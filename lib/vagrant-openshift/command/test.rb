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
      class Test < Vagrant.plugin(2, :command)
        include CommandHelper

        def component_list
          [:node,:cart,:gear,:broker,:console,:rhc]
        end

        def execute
          options = {}
          options[:help] = false
          options[:extended] = false
          options[:download] = false
          component_list.each { |component| options[component] = false }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant test [machine-name]"
            o.separator ""

            o.on("-n", "--node", String, "Run node tests") do |f|
              options[:node] = true
            end

            o.on("-t", "--cart", String, "Run cartridge tests") do |f|
              options[:cart] = true
            end

           o.on("-g", "--gear", String, "Run gear tests") do |f|
             options[:gear] = true
           end

            o.on("-b", "--broker", String, "Run broker tests") do |f|
              options[:broker] = true
            end

            o.on("-r", "--rhc", String, "Run CLI tests") do |f|
              options[:rhc] = true
            end

            o.on("-c", "--console", String, "Run console/web tests") do |f|
              options[:console] = true
            end

            o.on("-e", "--extended", String, "Run extended tests") do |f|
              options[:extended] = true
            end

            o.on("-a", "--all", String, "Run all tests") do |f|
              component_list.each { |component| options[component] = true }
            end

            o.on("-d","--artifacts", String, "Download logs and rpms") do |f|
              options[:download] = true
            end

            o.on("--fixme", "Run known broken tests to verify test fixes") do |f|
              options[:fixme] = true
            end

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = true
            end
          end

          # Parse the options
          argv = parse_options(opts)

          if options[:help]
            @env.ui.info opts
            exit
          end

          # Figure out if we are implicitly running all tests
          do_all = true
          component_list.each do |component|
            if options[component]
              do_all = false
              break
            end
          end
          if do_all
            component_list.each { |component| options[component] = true }
          end

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.run_tests(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
