require 'pathname'
pspath = if File.exist?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
           "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
         elsif File.exist?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
           "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
         elsif File.exist?('/usr/bin/powershell')
           '/usr/bin/powershell'
         elsif File.exist?('/usr/local/bin/powershell')
           '/usr/local/bin/powershell'
         elsif !Puppet::Util::Platform.windows?
           'powershell'
         else
           'powershell.exe'
         end
script = Pathname.new(__FILE__).dirname + '..' + 'puppet' + 'provider' + 'templates' + 'letsencrypt' + '_getcertificate.ps1'
fullcmd = "#{pspath} -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command #{script}"
values = %x[ #{fullcmd} ].to_s.gsub(/\n+|\r+/, "\n").squeeze("\n").strip.gsub('Domain : ', '')
certs = Hash[values.each_line.map { |l| l.chomp.split(' ', 2) }]
certs.each do |domain, cert|
  good_domain = domain.dup
  good_domain = good_domain.gsub!(/\.+|\-+/, '')
  Facter.add("ssl_#{good_domain}") do
    setcode do
      cert || '0'
    end
  end
end
