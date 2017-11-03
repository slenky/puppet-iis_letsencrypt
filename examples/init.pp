$iis_features = ['Web-WebServer','Web-Scripting-Tools']
# We will install 2 websites and request certs for them
$mydomain1 = 'bohdan1.ga'
$mydomain2 = 'dev.bohdan1.ga'
# Simple sites provided by puppetlabs-iis module
iis_feature { $iis_features:
  ensure => 'present',
} ->
iis_site { $mydomain1:
  ensure           => 'started',
  physicalpath     => "c:\\inetpub\\${mydomain1}",
  applicationpool  => 'DefaultAppPool',
  enabledprotocols => 'https',
  bindings         => [
    {
      'bindinginformation'   => "*:443:${mydomain1}",
      'protocol'             => 'https',
      # Custom fact which returns certificate thumbprint.
      # Creates in this way: ssl_ + friendly domain name without dots
      # i.e $ssl_examplecom
      'certificatehash'      => $ssl_bohdan1ga,
      'certificatestorename' => 'MY',
      'sslflags'             => 1,
    },
  ],
  require => File[$mydomain1],
} ->
# Create folders for virtual directory and where certs store to
file { ['C:\\Users\\bohdan\\Desktop\\public', 'C:\\CERTS']:
  ensure => 'directory'
} ->
ssl_cert { $mydomain1:
  ensure           => present,
  staging          => true,
  remove_http_bind => true,
  cert_pass        => '12345',
  cert_path        => 'C:\\CERTS',
  contact_email    => 'astapovb@ukr.net',
  physicalpath     => 'C:\\Users\\bohdan\\Desktop\\public'
}

file { $mydomain1:
  ensure => 'directory',
  path   => "c:\\inetpub\\${mydomain1}",
}

iis_site { $mydomain2:
  ensure           => 'started',
  physicalpath     => 'c:\\inetpub\\minimal',
  applicationpool  => 'DefaultAppPool',
  enabledprotocols => 'https',
  bindings         => [
    {
      'bindinginformation'   => "*:443:${mydomain2}",
      'protocol'             => 'https',
      'certificatehash'      => $ssl_devbohdan1ga,
      'certificatestorename' => 'MY',
      'sslflags'             => 1,
    },
  ],
  require => File[$mydomain2],
} ->

ssl_cert { $mydomain2:
  ensure           => present,
  staging          => true,
  remove_http_bind => true,
  cert_pass        => '12345',
  cert_path        => 'C:\\CERTS',
  contact_email    => 'astapovb@ukr.net',
  physicalpath     => 'C:\\Users\\bohdan\\Desktop\\public'
}

file { $mydomain2:
  ensure => 'directory',
  path   => "c:\\inetpub\\${mydomain2}",
}
