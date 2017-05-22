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

      def self.build_atomic_host(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use AtomicHostUpgrade
        end
      end

      def self.build_origin_rpm_test(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOriginRpmTest
        end
      end

      def self.build_origin_images(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOriginImages, options
        end
      end

      def self.create_local_yum_repo(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CreateLocalYumRepo, options
        end
      end

      def self.build_origin_base(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use CreateYumRepositories
          b.use YumUpdate
          b.use SetHostName
          b.use InstallOriginBaseDependencies
        end
      end

      def self.install_docker(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallDocker, options
        end
      end

      def self.install_golang(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallGolang, options
        end
      end

      def self.build_sti_base_windows(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildStiBaseWindows, options
        end
      end

      def self.install_origin(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use SetHostName
          b.use InstallOrigin
          b.use InstallOriginRhel7
          if options[:install_assets]
            b.use InstallOriginAssetDependencies, :restore_assets => true
          end
        end
      end

      def self.install_origin_assets_base(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallOriginAssetDependencies, :backup_assets => true
        end
      end

      def self.build_origin(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOrigin, options
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

      def self.try_restart_origin(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunSystemctl, {:action => "try-restart", :service => "openshift"}
        end
      end

      def self.build_origin_base_images(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildOriginBaseImages, options
        end
      end

      def self.repo_sync_origin(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean
              b.use CloneUpstreamRepositories, :repo => 'origin'
            end
            b.use SyncLocalRepository, :repo => 'origin'
            b.use CheckoutRepositories, :repo => 'origin'
          end
          if options[:build]
            b.use(BuildOriginBaseImages, options) if options[:images]
            b.use(BuildOrigin, options)
            b.use RunSystemctl, {:action => "try-restart", :service => "openshift"}
          end
        end
      end

      def self.repo_sync_sti(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean, :repo => 'source-to-image'
              b.use CloneUpstreamRepositories, :repo => 'source-to-image'
            end
            b.use SyncLocalRepository, :repo => 'source-to-image'
            b.use CheckoutRepositories, :repo => 'source-to-image'
          end
          unless options[:no_build]
            b.use(BuildSti, options)
          end
        end
      end

      def self.repo_sync_origin_console(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean, :repo => 'origin-web-console'
              b.use CloneUpstreamRepositories, :repo => 'origin-web-console'
            end
            b.use SyncLocalRepository, :repo => 'origin-web-console'
            b.use CheckoutRepositories, :repo => 'origin-web-console'
            if options[:build]
              b.use InstallOriginAssetDependencies, :restore_assets => true
            end
          end
        end
      end

      def self.repo_sync_origin_aggregated_logging(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use(Clean, options)
              b.use(CloneUpstreamRepositories, options)
            end
            b.use(SyncLocalRepository, options)
            b.use(CheckoutRepositories, options)
          end
          # no build support currently
          # if options[:build]
          #   b.use(BuildOriginBaseImages, options) if options[:images]
          #   b.use(BuildOrigin, options)
          #   b.use RunSystemctl, {:action => "try-restart", :service => "openshift"}
          # end
        end
      end

      def self.repo_sync_origin_metrics(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean, options
              b.use CloneUpstreamRepositories, options
            end
            b.use SyncLocalRepository, options
            b.use CheckoutRepositories, options
          end
        end
      end

      def self.repo_sync_customer_diagnostics(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareSshConfig
          if options[:source]
            if options[:clean]
              b.use Clean, options
              b.use CloneUpstreamRepositories, options
            end
            b.use SyncLocalRepository, options
            b.use CheckoutRepositories, options
          end
        end
      end

      def self.local_origin_checkout(options)
        Vagrant::Action::Builder.new.tap do |b|
          if not options[:no_build]
            b.use LocalOriginCheckout, options
          end
        end
      end

      def self.run_origin_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunOriginTests, options
          if options[:download]
            b.use DownloadArtifactsOrigin, options
          end
          b.use TestExitCode
        end
      end

      def self.run_origin_asset_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          # UI integration tests require the api server to be running
          b.use RunSystemctl, {:action => "start", :service => "openshift"}
          b.use RunOriginAssetTests, options
          if options[:download]
            b.use DownloadArtifactsOriginConsole
          end
          b.use TestExitCode
        end
      end

      def self.run_origin_aggregated_logging_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunOriginAggregatedLoggingTests, options
          if options[:download]
            b.use DownloadArtifactsOriginAggregatedLogging
          end
          b.use TestExitCode
        end
      end

      def self.run_origin_metrics_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunOriginMetricsTests, options
          if options[:download]
            b.use DownloadArtifactsOriginMetrics
          end
          b.use TestExitCode
        end
      end

      def self.run_customer_diagnostics_tests(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use RunCustomerDiagnosticsTests, options
          if options[:download]
            b.use DownloadArtifactsOriginMetrics
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

      def self.download_origin_artifacts(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use DownloadArtifactsOrigin, options
        end
      end

      def self.download_sti_artifacts(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use DownloadArtifactsSti
        end
      end

      def self.download_origin_aggregated_logging_artifacts(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use DownloadArtifactsOriginAggregatedLogging
        end
      end

      def self.download_origin_metrics_artifacts(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use DownloadArtifactsOriginMetrics
        end
      end

      def self.download_origin_console_artifacts(options)
        Vagrant::Action::Builder.new.tap do |b|
          b.use DownloadArtifactsOriginConsole
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
      autoload :SetHostName, action_root.join("set_host_name")
      autoload :YumUpdate, action_root.join("yum_update")
      autoload :InstallOriginBaseDependencies, action_root.join("install_origin_base_dependencies")
      autoload :InstallDocker, action_root.join("install_docker")
      autoload :InstallGolang, action_root.join("install_golang")
      autoload :InstallOriginAssetDependencies, action_root.join("install_origin_asset_dependencies")
      autoload :BuildOriginBaseImages, action_root.join("build_origin_base_images")
      autoload :PushOpenshiftImages, action_root.join("push_openshift_images")
      autoload :PushOpenshiftRelease, action_root.join("push_openshift_release")
      autoload :InstallOrigin, action_root.join("install_origin")
      autoload :InstallOriginRhel7, action_root.join("install_origin_rhel7")
      autoload :BuildOrigin, action_root.join("build_origin")
      autoload :BuildSti, action_root.join("build_sti")
      autoload :BuildStiBaseWindows, action_root.join("build_sti_base_windows")
      autoload :PrepareSshConfig, action_root.join("prepare_ssh_config")
      autoload :SyncLocalRepository, action_root.join("sync_local_repository")
      autoload :LocalOriginCheckout, action_root.join("local_origin_checkout")
      autoload :RunOriginTests, action_root.join("run_origin_tests")
      autoload :RunOriginAssetTests, action_root.join("run_origin_asset_tests")
      autoload :RunStiTests, action_root.join("run_sti_tests")
      autoload :RunOriginAggregatedLoggingTests, action_root.join("run_origin_aggregated_logging_tests")
      autoload :RunOriginMetricsTests, action_root.join("run_origin_metrics_tests")
      autoload :RunCustomerDiagnosticsTests, action_root.join("run_customer_diagnostics_tests")
      autoload :GenerateTemplate, action_root.join("generate_template")
      autoload :CreateAMI, action_root.join("create_ami")
      autoload :ModifyInstance, action_root.join("modify_instance")
      autoload :ModifyAMI, action_root.join("modify_ami")
      autoload :DownloadArtifactsOrigin, action_root.join("download_artifacts_origin")
      autoload :DownloadArtifactsOriginConsole, action_root.join("download_artifacts_origin_console")
      autoload :DownloadArtifactsSti, action_root.join("download_artifacts_sti")
      autoload :DownloadArtifactsOriginAggregatedLogging, action_root.join("download_artifacts_origin_aggregated_logging")
      autoload :DownloadArtifactsOriginMetrics, action_root.join("download_artifacts_origin_metrics")
      autoload :TestExitCode, action_root.join("test_exit_code")
      autoload :CleanNetworkSetup, action_root.join("clean_network_setup")
      autoload :RunSystemctl, action_root.join("run_systemctl")
      autoload :AtomicHostUpgrade, action_root.join("atomic_host_upgrade")
      autoload :BuildOriginRpmTest, action_root.join("build_origin_rpm_test")
      autoload :CreateLocalYumRepo, action_root.join("create_local_yum_repo")
      autoload :BuildOriginImages, action_root.join("build_origin_images")
    end
  end
end
