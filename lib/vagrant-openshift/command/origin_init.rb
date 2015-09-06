#--
# Copyright 2013-2015 Red Hat, Inc.
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
      class OriginInit < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "creates an .vagrant-openshift.json config file based on the options supplied"
        end

        def execute
          options = {
            :no_base  => false,
            :os       => 'centos7',
            :stage    => 'inst',
            :instance_type => 't2.medium',
            :volume_size => 25,
            :port_mappings => [],
            :no_synced_folders => false,
            :no_insert_key => false
          }

          valid_stage = ['os','deps','inst', 'bootstrap']
          valid_os = ['centos7','fedora','rhel7','rhelatomic7']

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant origin-init [vm or instance name]"
            o.separator ""

            o.on("-s [stage]", "
              --stage [stage]", String, "Specify what build state to start from:\n\tos = base operating system\n\tdeps = only dependencies installed\n\tinst = dev environment [default]\n\tbootstrap = running environment") do |f|
              options[:stage] = f
            end

            o.on("-o [name]", "--os [name]", String, "Operating system:\n\tcentos7 [default]\n\tfedora\n\trhel7\n\trhelatomic7") do |f|
              options[:os] = f
            end

            o.on("-p [guest_port:host_port]", "--map-port [guest_port:host_port]", String, "When running on VirtualBox, map port from guest docker vm to host machine") do |f|
              options[:port_mappings].push(f.split(":"))
            end

            o.on('--no-synced-folders', 'Checkout source into image rather than mapping from host system') do |f|
              options[:no_synced_folders] = true
            end

            o.on('--no-insert-key', 'Insert a secure ssh key on vagrant up') do |f|
              options[:no_insert_key] = true
            end

            o.on('--instance-type', "--instance-type [type]", String, "Specify what type of instance to launch") do |f|
              options[:instance_type] = f
            end

            o.on('--volume-size', "--volume-size [size]", String, "Specify the volume size for the instance") do |f|
              options[:volume_size] = f.to_i
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
