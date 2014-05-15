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

      config "openshift" do
        require_relative "config"
        Config
      end

      config(:openshift, :provisioner) do
        require_relative "config"
        Config
      end

      command "sync" do
        require_relative "command/repo_sync"
        Commands::RepoSync
      end

      command "sync-geard" do
        require_relative "command/repo_sync_geard"
        Commands::RepoSyncGeard
      end

      command "origin-build-base" do
        require_relative "command/build_origin_base"
        Commands::BuildOriginBase
      end

      command "build-geard-base" do
        require_relative "command/build_geard_base"
        Commands::BuildGeardBase
      end

      command "build-geard" do
        require_relative "command/build_geard"
        Commands::BuildGeard
      end

      command "install-geard" do
        require_relative "command/install_geard"
        Commands::InstallGeard
      end

      command "install-geard-broker" do
        require_relative "command/install_geard_broker"
        Commands::InstallGeardBroker
      end

      command "restart-geard" do
        require_relative "command/restart_geard"
        Commands::RestartGeard
      end

      command "restart-geard-broker" do
        require_relative "command/restart_geard_broker"
        Commands::RestartGeardBroker
      end

      command "build-geard-broker" do
        require_relative "command/build_geard_broker"
        Commands::BuildGeardBroker
      end

      command "build-geard-images" do
        require_relative "command/build_geard_images"
        Commands::BuildGeardImages
      end

      command "origin-init" do
        require_relative "command/openshift_init"
        Commands::OpenshiftInit
      end

      command "origin-local-checkout" do
        require_relative "command/local_repo_setup"
        Commands::LocalRepoSetup
      end

      command "geard-local-checkout" do
        require_relative "command/local_geard_setup"
        Commands::LocalGeardSetup
      end

      command "test" do
        require_relative "command/test"
        Commands::Test
      end

      command "test-geard" do
        require_relative "command/test_geard"
        Commands::TestGeard
      end

      command "create-ami" do
        require_relative "command/create_ami"
        Commands::CreateAMI
      end

      command "modify-ami" do
        require_relative "command/modify_ami"
        Commands::ModifyAMI
      end

      command "modify-instance" do
        require_relative "command/modify_instance"
        Commands::ModifyInstance
      end

      command "clone-upstream-repos" do
        require_relative "command/clone_upstream_repositories"
        Commands::CloneUpstreamRepositories
      end

      command "checkout-repos" do
        require_relative "command/checkout_repositories"
        Commands::CheckoutRepositories
      end

      command "install-rhc" do
        require_relative "command/install_rhc"
        Commands::InstallRhc
      end

      provisioner(:openshift) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
