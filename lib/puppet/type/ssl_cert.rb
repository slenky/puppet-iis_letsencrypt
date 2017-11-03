
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:ssl_cert) do
  @doc = 'Type representing a virtual machine in Microsoft Azure.'

  newproperty(:ensure) do
    desc "Specifies whether a certificate should be issued or not."

    newvalue(:present) do
      provider.create
    end

    newvalue(:reissued) do
      provider.reissue
    end

    newvalue(:absent) do
      provider.destroy
    end

    aliasvalue(:false, :absent)
    aliasvalue(:true, :present)
  end

  newparam(:name, namevar: true) do
    desc 'Name of your site & domain name of binding.'
  end

  newparam(:domain) do
    desc 'If your domain name is not the same as your site name you could specify it in those section. Defaults to :name.'
  end

  newparam(:physicalpath) do
    desc 'Physical path on your machine for .well-known virtual directory'
  end

  newparam(:cert_pass) do
    desc 'Password for your PFX certificate'
  end

  newparam(:cert_path) do
    desc 'Where must we store your cert on your system (temporary).'
  end

  newparam(:contact_email) do
    desc 'Contact Email of person for whom cert applies to.'
  end

  newproperty(:expiredate) do
    desc 'Basically, it is a private param. Whatever'
  end

  newproperty(:thumbprint) do
    desc 'Basically, it is a private param. Whatever'
  end

  newparam(:staging, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Boolean. Should we use staging letsencrypt environment on true. Default to false'
    defaultto false
  end

  newparam(:remove_http_bind, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Boolean. Should we remove http binding and set HTTPS as default. Default to true'
    defaultto true
  end

  newparam(:remove_certfiles, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Boolean. Should we use remove certificate files from your file system. Default to true'
    defaultto true
  end
end
