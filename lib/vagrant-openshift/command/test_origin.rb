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
      class TestOrigin < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "run the origin tests"
        end

        def execute
          options = {}
          options[:download] = false
          options[:all] = false
          options[:extended_test_packages] = ""

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant test-origin [machine-name]"
            o.separator ""

            o.on("-t", "--target MAKEFILE_TARGETS", String, "Arguments to pass to the repository Makefile") do |f|
              options[:target] = f
            end

            o.on("", "--root", String, "Run tests as root") do |f|
              options[:root] = true
            end

            o.on("-a", "--all", String, "Run all tests") do |f|
              options[:all] = true
            end

            o.on("", "--skip-check", String, "Skip unit, integration and e2e tests") do |f|
              options[:skip_check] = true
            end

            o.on("-e", "--extended TEST_BUCKETS", String, "Comma delimited list of extended test packages to run") do |f|
              options[:extended_test_packages] = f
            end

            o.on("-d","--artifacts", String, "Download logs") do |f|
              options[:download] = true
            end

            o.on("", "--download-release-artifacts", String, "Download release binaries") do |f|
              options[:download_release] = true
            end

            o.on("-s","--skip-image-cleanup", String, "Skip Docker image teardown for E2E test") do |f|
              options[:skip_image_cleanup] = true
            end

            o.on("-c","--report-coverage", String, "Generate code coverage report") do |f|
              options[:report_coverage] = true
            end

            o.on("-j","--parallel", String, "Run parallel make") do |f|
              options[:parallel] = true
            end

            o.on("-r","--image-registry REGISTRY", String, "Image registry to configure tests with") do |f|
              options[:image_registry] = f
            end

            o.on("", "--env ENV=VALUE", String, "Environment variable to execute tests with") do |f|
              options[:envs] = [] unless options[:envs]
              options[:envs] << f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.run_origin_tests(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
