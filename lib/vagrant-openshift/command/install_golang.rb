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
      class InstallGolang < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "install golang"
        end

        def execute
          options = {}
          options[:"golang.repourls"] = []
          options[:"golang.reponames"] = []

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant install-golang [vm-name]"
            o.separator ""

            o.on("--repourl [name]", String, "URL of a repository file to use when installing Golang.") do |f|
              options[:"golang.repourls"] << f
            end

            o.on("--repo [name]", String, "Name of a repository to enable when installing Golang. Defaults to use all available repositories.") do |f|
              options[:"golang.reponames"] << f
            end

            o.on("--golang.version [version]", String, "Install the specified Golang version. Leave empty to install latest available.") do |f|
              options[:"golang.version"] = f
            end

            o.on("--force", String, "Uninstall Golang to swap in the new version, even if the uninstall is unclean.") do |f|
              options[:force] = true
            end

          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.install_golang(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
