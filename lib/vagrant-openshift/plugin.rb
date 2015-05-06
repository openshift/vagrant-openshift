#--
# Copyright 2013-2015 Red Hat, Inc.
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

      command "sync-openshift" do
        require_relative "command/repo_sync_openshift"
        Commands::RepoSyncOpenshift
      end

      command "sync-sti" do
        require_relative "command/repo_sync_sti"
        Commands::RepoSyncSti
      end

      command "build-openshift-base" do
        require_relative "command/build_openshift_base"
        Commands::BuildOpenshiftBase
      end

      command "build-openshift" do
        require_relative "command/build_openshift"
        Commands::BuildOpenshift
      end

      command "build-sti" do
        require_relative "command/build_sti"
        Commands::BuildSti
      end

      command "install-openshift" do
        require_relative "command/install_openshift"
        Commands::InstallOpenshift
      end

      command "install-openshift-assets-base" do
        require_relative "command/install_openshift_assets_base"
        Commands::InstallOpenshiftAssetsBase
      end

      command "try-restart-openshift" do
        require_relative "command/try_restart_openshift"
        Commands::TryRestartOpenshift
      end

      command "build-openshift-base-images" do
        require_relative "command/build_openshift_base_images"
        Commands::BuildOpenshiftBaseImages
      end

      command "push-openshift-images" do
        require_relative "command/push_openshift_images"
        Commands::PushOpenshiftImages
      end

      command "origin-init" do
        require_relative "command/openshift_init"
        Commands::OpenshiftInit
      end

      command "openshift-local-checkout" do
        require_relative "command/local_openshift_setup"
        Commands::LocalOpenshiftSetup
      end

      command "push-openshift-release" do
        require_relative "command/push_openshift_release"
        Commands::PushOpenshiftRelease
      end

      command "test-openshift" do
        require_relative "command/test_openshift"
        Commands::TestOpenshift
      end

      command "test-sti" do
        require_relative "command/test_sti"
        Commands::TestSti
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

      command "test-openshift-image" do
        require_relative "command/test_openshift_image"
        Commands::TestOpenshiftImage
      end

      command "install-openshift-router" do
        require_relative "command/install_openshift_router"
        Commands::InstallOpenshiftRouter
      end

      command "install-docker-registry" do
        require_relative 'command/install_docker_registry'
        Commands::InstallDockerRegistry
      end

      command "bootstrap-openshift" do
        require_relative 'command/bootstrap_openshift'
        Commands::BootstrapOpenshift
      end

      provisioner(:openshift) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
