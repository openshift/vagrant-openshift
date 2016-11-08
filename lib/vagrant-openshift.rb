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
require "vagrant-openshift/version"
require "pathname"

begin
  require "vagrant"
rescue LoadError
  raise "Not running in vagrant environment"
end

module Vagrant
  module Openshift
    plugin_path = Pathname.new(File.expand_path("#{__FILE__}/../vagrant-openshift/"))

    autoload :CommandHelper, plugin_path + "helper/command_helper"
    autoload :InstallHelper, plugin_path + "helper/install_helper"
    autoload :Constants, plugin_path + "constants"
  end
end

require "vagrant-openshift/plugin"
