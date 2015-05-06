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
require_relative "../action"

module Vagrant
  module Openshift
    module Commands
      class InstallOpenshiftRegistry < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          'installs OpenShift registry as container'
        end

        def execute
          options = {
              with_registry_proxy: false,
              image_label: nil,
          }

          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant install-openshift-registry [vm-name]'
            o.separator ''

            o.on('--with-proxy', 'Deploy proxy container for OpenShift registry') do |c|
              options[:with_registry_proxy] = true
            end

            o.on('-i [label]', '--images [label]', String, 'Set default label for registry image') do |f|
              options[:image_label] = f.gsub(/\A["']|['"]\Z/, '')
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.install_openshift_registry(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
