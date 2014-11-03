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
      class PushOpenshift3Release < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "pushes openshift docker images to a registry"
        end

        def execute
          options = {}
          options[:clean] = false
          options[:local_source] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant push-openshift3-release --registry [registry_name] --include-base [vm-name]"
            o.separator ""

            o.on("--registry [registry_name]", String, "A Docker registry to push images to (include a trailing slash)") do |f|
              options[:registry_name] = f
            end

            o.on("--include-base", "Include the base infrastructure images in the push.") do |c|
              options[:push_base_images] = true
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.push_openshift3_release(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
