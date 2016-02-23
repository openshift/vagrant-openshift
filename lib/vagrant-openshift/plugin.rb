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

      command "sync-origin" do
        require_relative "command/repo_sync_origin"
        Commands::RepoSyncOrigin
      end

      command "sync-sti" do
        require_relative "command/repo_sync_sti"
        Commands::RepoSyncSti
      end

      command "build-atomic-host" do
        require_relative "command/build_atomic_host"
        Commands::BuildAtomicHost
      end

      command "build-origin-rpm-test" do
        require_relative "command/build_origin_rpm_test"
        Commands::BuildOriginRpmTest
      end

      command "build-origin-images" do
        require_relative "command/build_origin_images"
        Commands::BuildOriginImages
      end

      command "create-local-yum-repo" do
        require_relative "command/create_local_yum_repo"
        Commands::CreateLocalYumRepo
      end

      command "build-origin-base" do
        require_relative "command/build_origin_base"
        Commands::BuildOriginBase
      end

      command "build-origin" do
        require_relative "command/build_origin"
        Commands::BuildOrigin
      end

      command "build-sti" do
        require_relative "command/build_sti"
        Commands::BuildSti
      end

      command "install-origin" do
        require_relative "command/install_origin"
        Commands::InstallOrigin
      end

      command "install-origin-assets-base" do
        require_relative "command/install_origin_assets_base"
        Commands::InstallOriginAssetsBase
      end

      command "try-restart-origin" do
        require_relative "command/try_restart_origin"
        Commands::TryRestartOrigin
      end

      command "build-origin-base-images" do
        require_relative "command/build_origin_base_images"
        Commands::BuildOriginBaseImages
      end

      command "push-openshift-images" do
        require_relative "command/push_openshift_images"
        Commands::PushOpenshiftImages
      end

      command "origin-init" do
        require_relative "command/origin_init"
        Commands::OriginInit
      end

      command "origin-local-checkout" do
        require_relative "command/local_origin_setup"
        Commands::LocalOriginSetup
      end

      command "push-openshift-release" do
        require_relative "command/push_openshift_release"
        Commands::PushOpenshiftRelease
      end

      command "test-origin" do
        require_relative "command/test_origin"
        Commands::TestOrigin
      end

      command "test-sti" do
        require_relative "command/test_sti"
        Commands::TestSti
      end

      command "download-artifacts-origin" do
        require_relative "command/download_artifacts_origin"
        Commands::DownloadArtifactsOrigin
      end

      command "download-artifacts-sti" do
        require_relative "command/download_artifacts_sti"
        Commands::DownloadArtifactsSti
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

      command "test-origin-image" do
        require_relative "command/test_origin_image"
        Commands::TestOriginImage
      end

      provisioner(:openshift) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
