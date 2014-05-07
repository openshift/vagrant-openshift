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
      class CreateAMI < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "registers an ami of the current instance with the same name as the instance"
        end

        def execute
          options = {}
          options[:help] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant create-ami"
            o.separator ""

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)

          if options[:help]
            @env.ui.info opts
            exit
          end

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.create_ami(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end

        private


      end
    end
  end
end
