source 'https://rubygems.org'

# Specify your gem's dependencies in vagrant-openshift.gemspec
gemspec

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  if File.exist?(File.expand_path("../../vagrant", __FILE__))
    gem "vagrant", path: "../vagrant"
  else
    gem "vagrant", :git => "git://github.com/mitchellh/vagrant.git"
  end
  gem "json"
end
