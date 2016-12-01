#--
# Copyright 2016 Red Hat, Inc.
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
      class BuildStiBaseWindows < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "install the prereqs for source-to-image on Windows"
        end

        def execute
          options = {
            :ami_prefix => ENV["USER"],
            :flavor_id => "m4.large",
            :instance_prefix => ENV["USER"]
          }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant build-sti-base-windows subnet_id"
            o.separator ""

            o.on("--ami-prefix prefix", "Prefix for AMI name.") do |prefix|
              options[:ami_prefix] = prefix
            end

            o.on("--flavor flavor", "Flavor of instance.") do |flavor|
              options[:flavor_id] = flavor
            end

            o.on("--instance-prefix prefix", "Prefix for instance name.") do |prefix|
              options[:instance_prefix] = prefix
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          raise Errors::CLIInvalidOptions, help: opts.help.chomp if argv.length != 1
          options[:subnet_id] = argv[0]

          actions = Vagrant::Openshift::Action.build_sti_base_windows(options)
          @env.action_runner.run actions
          0
        end
      end
    end
  end
end
