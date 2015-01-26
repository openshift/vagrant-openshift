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

      command "sync-openshift3" do
        require_relative "command/repo_sync_openshift3"
        Commands::RepoSyncOpenshift3
      end

      command "sync-sti" do
        require_relative "command/repo_sync_sti"
        Commands::RepoSyncSti
      end

      command "build-openshift3-base" do
        require_relative "command/build_openshift3_base"
        Commands::BuildOpenshift3Base
      end

      command "build-openshift3" do
        require_relative "command/build_openshift3"
        Commands::BuildOpenshift3
      end

      command "build-sti" do
        require_relative "command/build_sti"
        Commands::BuildSti
      end

      command "install-openshift3" do
        require_relative "command/install_openshift3"
        Commands::InstallOpenshift3
      end

      command "install-openshift3-assets-base" do
        require_relative "command/install_openshift3_assets_base"
        Commands::InstallOpenshift3AssetsBase
      end

      command "try-restart-openshift3" do
        require_relative "command/try_restart_openshift3"
        Commands::TryRestartOpenshift3
      end

      command "build-openshift3-base-images" do
        require_relative "command/build_openshift3_base_images"
        Commands::BuildOpenshift3BaseImages
      end

      command "origin-init" do
        require_relative "command/openshift_init"
        Commands::OpenshiftInit
      end

      command "openshift3-local-checkout" do
        require_relative "command/local_openshift3_setup"
        Commands::LocalOpenshift3Setup
      end

      command "push-openshift3-release" do
        require_relative "command/push_openshift3_release"
        Commands::PushOpenshift3Release
      end

      command "test-openshift3" do
        require_relative "command/test_openshift3"
        Commands::TestOpenshift3
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

      command "test-openshift3-image" do
        require_relative "command/test_openshift3_image"
        Commands::TestOpenshift3Image
      end

      provisioner(:openshift) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
