require File.join(File.dirname(__FILE__), '../ssl_powershell')

Puppet::Type.type(:ssl_cert).provide(:letsencrypt, parent: Puppet::Provider::SSL_PowerShell) do
  confine    feature: :acmeclient
  confine    operatingsystem: :windows
  defaultfor operatingsystem: :windows

  commands powershell: PuppetX::SSLIIS::PowerShellCommon.powershell_path
  mk_resource_methods

  def authorize
    cmd = self.class.ps_script_content('_fixhandlers', @resource)
    self.class.run(cmd)
    virt_dir('New')
    private_key = OpenSSL::PKey::RSA.new(4096)
    endpoint = if @resource[:staging]
                 'https://acme-staging.api.letsencrypt.org/'
               else
                 'https://acme-v01.api.letsencrypt.org/'
               end
    client = Acme::Client.new(private_key: private_key, endpoint: endpoint,
                              connection_options: { request:
                                { open_timeout: 10, timeout: 10 } })
    registration = client.register(contact: "mailto:#{@resource[:contact_email]}")
    registration.agree_terms
    authorization = client.authorize(domain: @resource[:domain])
    return unless authorization.status == 'pending'
    Puppet.debug "Authorization status for domain #{@resource[:domain]} is pending, go ahead..."
    challenge = authorization.http01
    Puppet.debug "Authorization URL: #{authorization.uri}"
    FileUtils.mkdir_p(File.join(@resource[:physicalpath], File.dirname(challenge.filename)))
    File.write(File.join(@resource[:physicalpath], challenge.filename), challenge.file_content)
    challenge.request_verification
    # There is no method to wait for verification to complete, so we basically waiting for 2 seconds.
    sleep(2)
    # return unless authorization.verify_status == 'valid'
    Puppet.debug "http-01 verify has been validated successfully for #{@resource[:domain]}, go ahead..."
    domain = @resource[:domain].split(/,/)
    csr = Acme::Client::CertificateRequest.new(names: domain)
    certificate = client.new_certificate(csr)
    # Save the certificate and the private key to files
    File.write("#{cert_path}/#{@resource[:domain]}_privkey.pem", certificate.request.private_key.to_pem)
    File.write("#{cert_path}/#{@resource[:domain]}_cert.pem", certificate.to_pem)
    rsa_key = OpenSSL::PKey::RSA.new(File.read("#{cert_path}/#{@resource[:domain]}_privkey.pem"))
    cert = OpenSSL::X509::Certificate.new(File.read("#{cert_path}/#{@resource[:domain]}_cert.pem"))
    pfx = OpenSSL::PKCS12.create(@resource[:cert_pass], @resource[:domain], rsa_key, cert)
    File.open("#{cert_path}/#{@resource[:domain]}.pfx", 'wb') { |f| f.print pfx.to_der }
    cert_thumbprint
    manage_certificate('new')
  end

  def binding_exist?(proto)
    cmd = []
    cmd << "Get-WebBinding -Name \"#{@resource[:name]}\" "
    cmd << "-Protocol #{proto} "
    cmd << '-ErrorAction Stop'
    cmd = cmd.join
    result = self.class.run(cmd)
    Puppet.err "Error executing existance of binding: #{result[:errormessage]}" unless result[:exitcode].zero?
    return true unless result[:stdout].nil?
  end

  def manage_certificate(action)
    case action
    when 'new'
      cmd = self.class.ps_script_content('_newcert', @resource)
      result = self.class.run(cmd)
      Puppet.err "Error creating certificate: #{result[:errormessage]}" unless result[:exitcode].zero?
      manage_certificate('import')
    when 'remove'
      cmd = self.class.ps_script_content('_rmcert', @resource)
      result = self.class.run(cmd)
      Puppet.err "Error removing certificate: #{result[:errormessage]}" unless result[:exitcode].zero?
    when 'import'
      site_binding('https', 'New') if binding_exist?('https')
      cmd = self.class.ps_script_content('_bindcert', @resource)
      result = self.class.run(cmd)
      virt_dir('Remove')
      site_binding('http', 'Remove') if resource[:remove_http_bind]
      delete_certfiles if resource[:remove_certfiles]
      Puppet.err "Error binding certificate to site: #{result[:errormessage]}" unless result[:exitcode].zero?
    end
  end

  def site_binding(proto, action = 'New')
    cmd = []
    cmd << "#{action}-WebBinding -Name \"#{@resource[:name]}\" "
    cmd << "-Protocol #{proto} "
    cmd << '-Port 80 ' if proto == 'http'
    cmd << '-Port 443 ' if proto == 'https'
    cmd << '-Sslflags 1 ' if proto == 'https' && action == 'New'
    cmd << "-HostHeader \"#{@resource[:domain]}\" "
    cmd << '-ErrorAction Stop'
    cmd = cmd.join
    result = self.class.run(cmd)
    Puppet.err "Error executing creating of binding: #{result[:errormessage]}" unless result[:exitcode].zero?
  end

  def self.ssl_expired?(cert)
    daysleft = (Date.parse(cert) - Date.today).to_i
    false
    return true if daysleft <= 1
  end

  def cert_thumbprint
    cmd = self.class.ps_script_content('_getcertthumb', @resource)
    result = self.class.run(cmd)
    resource[:thumbprint] = result[:stdout]
  end

  def get_virt_dir
    cmd = self.class.ps_script_content('_getvirtdir', @resource)
    result = self.class.run(cmd)
    Puppet.err "Error executing existance of binding: #{result[:errormessage]}" unless result[:exitcode].zero?
    false
    true if (result[:stdout] =~ /true/i)
  end

  def delete_certfiles
    Dir.glob("#{resource[:cert_path]}\\#{resource[:domain]}*").each { |file| File.delete(file) }
  end

  def web_config
    @param_hash = resource
    template_path = File.expand_path('../../templates/letsencrypt', __FILE__)
    template_file = File.new(template_path + '/web.config.erb').read
    template      = ERB.new(template_file, nil, '-')
    File.open("#{physicalpath}\\.well-known\\acme-challenge\\web.config", 'w') do |f|
      f.write template.result(binding)
    end
  end

  def virt_dir(action = 'New')
    case action
    when 'New'
      if @resource[:physicalpath].nil?
        raise fail 'physicalpath is a required paramter to create a iis virtual directory'
      end
      FileUtils.mkdir_p "#{physicalpath}/.well-known/acme-challenge"
      # If there is no virt dir - we would create it lol what's the problem.
      unless get_virt_dir
        cmd = self.class.ps_script_content('_newvirtdir', @resource)
        result = self.class.run(cmd)
        Puppet.err "Error creating virtual directory: #{result[:errormessage]}" unless result[:exitcode].zero?
        # Push web.config to virtdir.
        web_config
      end
    when 'Remove'
      cmd = self.class.ps_script_content('_rmvirtdir', @resource)
      result = self.class.run(cmd)
      FileUtils.rm_rf("#{resource[:physicalpath]}\\.well-known")
      Puppet.err "Error removing virtual directory: #{result[:errormessage]}" unless result[:exitcode].zero?
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def reissue
    @property_flush[:ensure] = :absent
    @property_flush[:ensure] = :present
  end

  def self.instances
    cmd = ps_script_content('_getcertificates', @resource)
    result = run(cmd)
    return [] if result.nil?

    certs_json = self.parse_json_result(result[:stdout])
    return [] if certs_json.nil?

    certs_json.collect do |cert|
      cert_hash = {}
      cert_hash[:expiredate] = cert['NotAfter']
      cert_hash[:ensure] = unless ssl_expired?(cert_hash[:expiredate])
                             :present
                           else
                             :reissued
                           end
      cert_hash[:name] = cert['FriendlyName']
      cert_hash[:thumbprint] = cert['Thumbprint']
      new(cert_hash)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    unless resource.nil?
      @property_hash = resource.to_hash
    end

    if resource[:domain].nil?
      resource[:domain] = @resource[:name]
    end

    case self.ensure
    when :present
      site_binding('http') unless binding_exist?('http')
      authorize
    when :absent
      resource[:thumbprint] = @property_hash[:thumbprint]
      virt_dir('Remove') if get_virt_dir
      site_binding('https', 'Remove') if binding_exist?('https')
      manage_certificate('remove')
    when :reissued
      Puppet.debug 'Going to reissue the certificate.'
      self.ensure = :absent
      self.ensure = :present
    else
      raise Puppet::Error, "invalid :ensure value: #{self.ensure}"
    end
  end
end
