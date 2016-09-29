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
    if Gem::Version.new(Bundler::VERSION) < Gem::Version.new("1.12.5")
      gem "vagrant", :git => "https://github.com/mitchellh/vagrant", :ref => "v1.7.4"
    else
      gem "vagrant", :git => "https://github.com/mitchellh/vagrant"
    end
  end
  gem "json"
end
