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
      class RepoSync < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "syncs and installs(by default) your local repos to the current instance"
        end

        def execute
          options = {}
          options[:clean] = false
          options[:local_source] = true
          options[:no_build] = false
          options[:deps] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant sync [vm-name]"
            o.separator ""

            o.on("-c", "--clean", "Delete existing repo and uninstall all OpenShift RPMs before syncing") do |f|
              options[:clean] = f
            end

            o.on("-u", "--upstream", "Build base VM based on local source") do |f|
              options[:local_source] = false
            end

            o.on("--install-deps", "Install any missing dependencies") do |f|
              options[:deps] = f
            end

            o.on("--dont-install", "Don't build and install RPMs") do |f|
              options[:no_build] = f
            end

            o.on("-d","--artifacts", String, "Download logs and rpms") do |f|
              options[:download] = true
            end

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          with_target_vms(argv, :reverse => true) do |machine|
            if options[:help]
              machine.env.ui.info opts
              exit
            end

            actions = Vagrant::Openshift::Action.repo_sync(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end