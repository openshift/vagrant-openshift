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
require "vagrant/action/builder"
require "pathname"

module Vagrant
  module Openshift
    module Action
      include Vagrant::Action::Builtin

      def self.build_origin_base(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CreateYumRepositories
          b.use YumUpdate
          b.use InstallBuildDependencies
          b.use SetupBuilderFiles
          b.use Clean
          b.use CloneUpstreamRepositories
          b.use SetHostName
          b.use SetupBindDnsKey
          b.use CheckoutRepositories
          b.use InstallOpenShiftDependencies
          b.use CreatePuppetFile
        end
      end

      def self.repo_sync(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:clean]
            b.use Clean
            b.use SetupBuilderFiles
            b.use CreatePuppetFile
            if options[:local_source]
              b.use CreateBareRepoPlaceholders
            else
              b.use CloneUpstreamRepositories
            end
          end

          if options[:local_source]
            b.use SyncLocalRepository
          else
            b.use SyncUpstreamRepository
          end
          b.use CheckoutRepositories
          b.use InstallOpenShiftDependencies if options[:deps]
          b.use UninstallOpenShiftRpms if options[:clean]
          b.use BuildSources unless options[:no_build]
          if options[:download]
            b.use DownloadArtifacts
          end
        end
      end

      def self.local_repo_checkout(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use LocalRepoCheckout unless options[:no_build]
        end
      end

      def self.run_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CreateTestUsers
          b.use PreserveMcollectiveLogs
          b.use IdleAllGears
          b.use CheckoutTests
          b.use RunTests, options
          if options[:download]
            b.use DownloadArtifacts
          end
          b.use TestExitCode
        end
      end

      def self.gen_vagrant_file(options)
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

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :Clean, action_root.join("clean")
      autoload :UninstallOpenShiftRpms, action_root.join("uninstall_openshift_rpms")
      autoload :CloneUpstreamRepositories, action_root.join("clone_upstream_repositories")
      autoload :CreateYumRepositories, action_root.join("create_yum_repositories")
      autoload :CreatePuppetFile, action_root.join("create_puppet_file")
      autoload :InstallOpenShiftDependencies, action_root.join("install_open_shift_dependencies")
      autoload :CheckoutRepositories, action_root.join("checkout_repositories")
      autoload :SetupBindDnsKey, action_root.join("setup_bind_dns_key")
      autoload :SetHostName, action_root.join("set_host_name")
      autoload :YumUpdate, action_root.join("yum_update")
      autoload :SetupBuilderFiles, action_root.join("setup_builder_files")
      autoload :InstallBuildDependencies, action_root.join("install_build_dependencies")
      autoload :PrepareSshConfig, action_root.join("prepare_ssh_config")
      autoload :SyncLocalRepository, action_root.join("sync_local_repository")
      autoload :SyncUpstreamRepository, action_root.join("sync_upstream_repository")
      autoload :BuildSources, action_root.join("build_sources")
      autoload :LocalRepoCheckout, action_root.join("local_repo_checkout")
      autoload :CreateBareRepoPlaceholders, action_root.join("create_bare_repo_placeholders")
      autoload :CreateTestUsers, action_root.join("create_test_users")
      autoload :IdleAllGears, action_root.join("idle_all_gears")
      autoload :PreserveMcollectiveLogs, action_root.join("preserve_mcollective_logs")
      autoload :RunTests, action_root.join("run_tests")
      autoload :CheckoutTests, action_root.join("checkout_tests")
      autoload :GenerateTemplate, action_root.join("generate_template")
      autoload :CreateAMI, action_root.join("create_ami")
      autoload :ModifyInstance, action_root.join("modify_instance")
      autoload :DownloadArtifacts, action_root.join("download_artifacts")
      autoload :TestExitCode, action_root.join("test_exit_code")
      autoload :CleanNetworkSetup, action_root.join("clean_network_setup")
    end
  end
end
