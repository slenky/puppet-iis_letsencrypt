require 'puppet/util/feature'

Puppet.features.add(:acmeclient) do
  acme_version = '0.6.1'
  gems = ['acme-client', acme_version], ['httpclient', '~> 2.8.3']
  gems.each do |gem, version|
    gdep = Gem::Dependency.new(gem, version)
    found_gspec = gdep.matching_specs.max_by(&:version)
    if found_gspec
      Puppet.debug "Requirement '#{gdep}' already satisfied by #{found_gspec.name}-#{found_gspec.version}"
    else
      Puppet.debug "Requirement '#{gdep}' not satisfied; installing..."
      reqs_string = gdep.requirements_list.join(', ')
      Gem.install gem, gdep.requirement
    end
  end
  require 'digest/md5'
  require 'fileutils'
  require 'net/http'
  require 'date'
  # There starts hardcoded way to fix the strange issue with Faraday,
  # which decided to broke up any connections to LE at all.
  link = 'https://gist.githubusercontent.com/slenky/cdcf0655b91aeefb19b72642ede316f3/raw/739909e0a91f08c07ebb6843f18ee66dca336d11/client.rb'
  rubyvers = Facter.value('rubysitedir').split('/')[-1]
  gemfile = Facter.value('rubysitedir')[/^(.*\/lib\/ruby\/).*$/, 1] + "/gems/#{rubyvers}/gems/acme-client-#{acme_version}/lib/acme/client.rb"
  digest = Digest::MD5.hexdigest(File.read(gemfile))
  digestmod = '3f6ccea44f20481c511251aa1a5e887e'
  unless digest.eql? digestmod
    File.write(filepath, Net::HTTP.get(URI.parse(link)))
    Puppet.debug 'Replacing default client.rb'
  end
  require 'acme-client'
  require 'openssl'
  true
end
