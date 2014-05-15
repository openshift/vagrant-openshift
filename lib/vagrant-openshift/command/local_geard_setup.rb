#--
# Copyright 2014 Red Hat, Inc.
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
      class LocalGeardSetup < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "clones the openshift repos into the current directory"
        end

        def execute
          options = {
            :branch => 'master',
            :replace => false,
          }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant geard-local-checkout [options]"
            o.separator ""

            o.on("-b [branch_name]", "--branch [branch_name]", String, "Check out the specified branch. Default is 'master'.") do |f|
              options[:branch] = f
            end

            o.on("-u [username]", "--user [username]", String, "Your GitHub username. If provided, Vagrant will attempt to clone your forks of the Origin repos. If not provided, or if the forks cannot be found, Vagrant will clone read-only copies of the OpenShift repos.") do |f|
              options[:user] = f
            end

            o.on("-r", "--replace", "Delete existing cloned dirs first. Default is to skip repos that are already cloned.") do |f|
              options[:replace] = f
            end

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = f
            end
          end

          # Parse the options
          parse_options(opts)
          if options[:help]
            @env.ui.info opts
            exit
          end

          actions = Vagrant::Openshift::Action.local_geard_checkout(options)
          @env.action_runner.run actions
          0
        end
      end
    end
  end
end
