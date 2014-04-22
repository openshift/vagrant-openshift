# -*- encoding: utf-8 -*-
#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-openshift/version'

Gem::Specification.new do |gem|
  gem.name          = %q{vagrant-openshift}
  gem.version       = Vagrant::Openshift::VERSION
  gem.authors       = %q{Red Hat}
  gem.email         = %q{dev@lists.openshift.redhat.com}
  gem.description   = %q{Vagrant plugin to manage OpenShift Origin environments}
  gem.summary       = %q{Vagrant plugin to manage OpenShift Origin environments}
  gem.homepage      = %q{https://github.com/openshift/vagrant-openshift}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("rake")
  gem.add_development_dependency("thor")
  gem.add_dependency("pry")
  gem.add_dependency("fog")
  gem.add_dependency("xml-simple")
  gem.add_dependency("vagrant-aws")
end
