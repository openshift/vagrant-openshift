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

module Vagrant
  module Openshift
    class Plugin < Vagrant.plugin("2")
      name "OpenShift"
      description %{
        Plugin to build and manage OpenShift Origin environments
      }

      command "sync" do
        require_relative "command/repo_sync"
        Commands::RepoSync
      end

      command "origin-build-base" do
        require_relative "command/build_origin_base"
        Commands::BuildOriginBase
      end

      command "origin-init" do
        require_relative "command/openshift_init"
        Commands::OpenshiftInit
      end

      command "origin-local-checkout" do
        require_relative "command/local_repo_setup"
        Commands::LocalRepoSetup
      end

      command "test" do
        require_relative "command/test"
        Commands::Test
      end

      config "openshift" do
        require_relative "config"
        Config
      end

      provisioner "openshift" do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end