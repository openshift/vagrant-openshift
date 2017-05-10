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
      class CloneUpstreamRepositories < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "clones upstream repositories into vm"
        end

        def execute
          options = {}
          options[:clean] = false
          options[:repo] = 'origin'

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant clone-upstream-repositories"
            o.separator ""

            o.on("-c", "--clean", "Remove the current bare repositories on disk if present") do |c|
              options[:clean] = true
            end

            o.on("-r [repo-name]", "--repo [repo-name]", String, "Clone the specified repo. Default is 'origin'.") do |f|
              options[:repo] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.clone_upstream_repositories(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end