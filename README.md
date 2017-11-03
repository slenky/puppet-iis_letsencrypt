
# iis_letsencrypt
#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with iis_letsencrypt](#setup)
    * [What iis_letsencrypt affects](#what-iis_letsencrypt-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with iis_letsencrypt](#beginning-with-iis_letsencrypt)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description
Puppet module designed to request and deploy valid SSL certificates from [LetsEncrypt](https://letsencrypt.org/) via [ACME](https://acme-v01.api.letsencrypt.org/) and deploy them to Windows Certificate Store and apply to your site.
Also it would check certificate expire date on every Puppet run and reissue the certificate if needed.

Implemented via Custom Provider with self.instances & prefetch.

Big thanks to [puppetlabs-iis](https://forge.puppet.com/puppetlabs/iis) module where I got powershell workarounds and to developers of [acme-client](https://github.com/unixcharles/acme-client)
## Setup

### What iis_letsencrypt affects
This module fully affects:
* Automatically installing Rubygems Dependencies
* Creating/removing virtual directories in IIS for new requests.
* Requesting new certificate via ACME, save it in Certificate Store and deploy to IIS Site.

### Setup Requirements

This module works perfectly with puppetlabs-iis module, so feel free to work with it but it's not actually a requrement.

### Beginning with iis_letsencrypt  
## Usage

Full example with IIS you'd able to find in examples/init.pp file.
```
ssl_cert { $mydomain1:
  ensure           => present,
  staging          => true,
  remove_http_bind => true,
  cert_pass        => '12345',
  cert_path        => 'C:\\certs',
  contact_email    => 'email@example.com',
  physicalpath     => 'C:\\mysite\\virtualfolder'
}
```
## Reference

### ssl_cert resource
#### name
Name specifies sitename in IIS where cert should apply to.
#### domain
If your domain name is not the same as your site name you could specify it in thus section. Defaults to :name.
#### staging
Boolean. Should we use staging letsencrypt environment on true. Defaults to false
#### remove_http_bind
Boolean. Should provider remove http bind after activation of certificate.
#### cert_pass
Password for PFX cert file.
#### cert_path
Where we should store PFX and PEM files.
#### remove_certfiles
Boolean. Should we use remove certificate files from your file system. Defaults to true
#### contact_email
Contact Email of person for whom cert applies to.
#### physicalpath
Physical path on your machine for .well-known virtual directory

## Limitations

Only Windows with Ruby >= 2.1.0
Tested on Win2012R2 with IIS 8.5

## Development
Feel free to fork, pull requests and so on.
