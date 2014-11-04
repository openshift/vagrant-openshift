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
      class OpenshiftInit < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "creates an OpenShift Vagrantfile based on the options supplied"
        end

        def execute
          options = {
            :no_base  => false,
            :os       => 'centos6',
            :stage    => 'inst',
            :port_mappings => []
          }

          valid_stage = ['os','deps','inst']
          valid_os = ['centos6','fedora','rhel6']

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant origin-init [vm or instance name]"
            o.separator ""

            o.on("-s [stage]", "--stage [stage]", String, "Specify what build state to start from:\n\tos = base operating system\n\tdeps = only dependencies installed\n\tinst = dev environment [default]") do |f|
              options[:stage] = f
            end

            o.on("-o [name]", "--os [name]", String, "Operating system:\n\tcentos6 [default]\n\tfedora\n\trhel6") do |f|
              options[:os] = f
            end

            o.on("-p [guest_port:host_port]", "--map-port [guest_port:host_port]", String, "When running on Virtualbox, map port from guest docker vm to host machine") do |f|
              options[:port_mappings].push(f.split(":"))
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          unless valid_stage.include? options[:stage]
            @env.ui.warn "Unknown stage '#{options[:stage]}'. Please choose from #{valid_stage.join(', ')}"
            exit
          end

          unless valid_os.include? options[:os]
            @env.ui.warn "Unknown OS '#{options[:os]}'. Please choose from #{valid_os.join(', ')}"
            exit
          end

          options[:name] = argv[0] if argv[0]

          actions = Vagrant::Openshift::Action.gen_template(options)
          @env.action_runner.run actions
          0
        end

        private


      end
    end
  end
end
