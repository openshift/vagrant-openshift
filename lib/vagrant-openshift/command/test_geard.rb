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
      class TestGeard < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "run the geard tests"
        end

        def execute
          options = {}
          options[:download] = false
          options[:all] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant test [machine-name]"
            o.separator ""

            o.on("-a", "--all", String, "Run all tests") do |f|
              options[:all] = true
            end

            o.on("-d","--artifacts", String, "Download logs and rpms") do |f|
              options[:download] = true
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.run_geard_tests(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
