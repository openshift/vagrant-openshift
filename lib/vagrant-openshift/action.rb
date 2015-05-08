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
require "vagrant/action/builder"
require "pathname"

module Vagrant
  module Openshift
    module Action
      include Vagrant::Action::Builtin

      def self.build_openshift_base(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CreateYumRepositories
          b.use YumUpdate
          b.use SetHostName
          b.use InstallOpenshiftBaseDependencies
        end
      end

      def self.install_openshift(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use YumUpdate
          b.use SetHostName
          b.use InstallOpenshift
          b.use InstallOpenshiftRhel7
          b.use InstallOpenshiftAssetDependencies
        end
      end

      def self.install_openshift_assets_base(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallOpenshiftAssetDependencies
        end
      end

      def self.build_openshift(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOpenshift, options
        end
      end

      def self.push_openshift_images(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PushOpenshiftImages, options
        end
      end

      def self.build_sti(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildSti, options
        end
      end

      def self.try_restart_openshift(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunSystemctl, {:action => "try-restart", :service => "openshift"}
        end
      end

      def self.build_openshift_base_images(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOpenshiftBaseImages, options
        end
      end

      def self.repo_sync_openshift(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean
              b.use CloneUpstreamRepositories
            end
            b.use SyncLocalRepository
            b.use CheckoutRepositories
            b.use InstallOpenshiftAssetDependencies
          end
          if options[:build]
            b.use(BuildOpenshiftBaseImages, options) if options[:images]
            b.use(BuildOpenshift, options)
            b.use RunSystemctl, {:action => "try-restart", :service => "openshift"}
          end
        end
      end

      def self.repo_sync_sti(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean
              b.use CloneUpstreamRepositories
            end
            b.use SyncLocalRepository
            b.use CheckoutRepositories
          end
          unless options[:no_build]
            b.use(BuildSti, options)
          end
        end
      end

      def self.local_openshift_checkout(options)
        Vagrant::Action::Builder.new.tap do |b|
          if not options[:no_build]
            b.use LocalOpenshiftCheckout, options
          end
        end
      end

      def self.run_openshift_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunOpenshiftTests, options
          if options[:download]
            b.use DownloadArtifactsOpenshift
          end
          b.use TestExitCode
        end
      end

      def self.run_sti_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunStiTests, options
          if options[:download]
            b.use DownloadArtifactsSti
          end
          b.use TestExitCode
        end
      end

      def self.gen_template(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use GenerateTemplate, options
        end
      end

      def self.create_ami(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CleanNetworkSetup
          b.use ConfigValidate
          b.use VagrantPlugins::AWS::Action::ConnectAWS
          b.use CreateAMI, options
        end
      end

      def self.modify_instance(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use VagrantPlugins::AWS::Action::ConnectAWS
          b.use ModifyInstance, options
        end
      end

      def self.modify_ami(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use VagrantPlugins::AWS::Action::ConnectAWS
          b.use ModifyAMI, options
        end
      end

      def self.push_openshift_release(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PushOpenshiftRelease, options
        end
      end

      def self.clone_upstream_repositories(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CloneUpstreamRepositories, options
        end
      end

      def self.checkout_repositories(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckoutRepositories, options
        end
      end

      def self.install_rhc(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallRhc
        end
      end

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :Clean, action_root.join("clean")
      autoload :CloneUpstreamRepositories, action_root.join("clone_upstream_repositories")
      autoload :CreateYumRepositories, action_root.join("create_yum_repositories")
      autoload :CheckoutRepositories, action_root.join("checkout_repositories")
      autoload :SetupBindDnsKey, action_root.join("setup_bind_dns_key")
      autoload :SetHostName, action_root.join("set_host_name")
      autoload :YumUpdate, action_root.join("yum_update")
      autoload :InstallOpenshiftBaseDependencies, action_root.join("install_openshift_base_dependencies")
      autoload :InstallOpenshiftAssetDependencies, action_root.join("install_openshift_asset_dependencies")
      autoload :BuildOpenshiftBaseImages, action_root.join("build_openshift_base_images")
      autoload :PushOpenshiftImages, action_root.join("push_openshift_images")
      autoload :PushOpenshiftRelease, action_root.join("push_openshift_release")
      autoload :InstallOpenshift, action_root.join("install_openshift")
      autoload :InstallOpenshiftRhel7, action_root.join("install_openshift_rhel7")
      autoload :BuildOpenshift, action_root.join("build_openshift")
      autoload :BuildSti, action_root.join("build_sti")
      autoload :PrepareSshConfig, action_root.join("prepare_ssh_config")
      autoload :SyncLocalRepository, action_root.join("sync_local_repository")
      autoload :SyncUpstreamRepository, action_root.join("sync_upstream_repository")
      autoload :LocalOpenshiftCheckout, action_root.join("local_openshift_checkout")
      autoload :CreateBareRepoPlaceholders, action_root.join("create_bare_repo_placeholders")
      autoload :RunOpenshiftTests, action_root.join("run_openshift_tests")
      autoload :RunStiTests, action_root.join("run_sti_tests")
      autoload :GenerateTemplate, action_root.join("generate_template")
      autoload :CreateAMI, action_root.join("create_ami")
      autoload :ModifyInstance, action_root.join("modify_instance")
      autoload :ModifyAMI, action_root.join("modify_ami")
      autoload :DownloadArtifactsOpenshift, action_root.join("download_artifacts_openshift")
      autoload :DownloadArtifactsSti, action_root.join("download_artifacts_sti")
      autoload :TestExitCode, action_root.join("test_exit_code")
      autoload :CleanNetworkSetup, action_root.join("clean_network_setup")
      autoload :SetupBindHost, action_root.join("setup_bind_host")
      autoload :RunSystemctl, action_root.join("run_systemctl")
    end
  end
end
