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
    module Action
      class RunOriginTests
        include CommandHelper

        @@SSH_TIMEOUT = 4800

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options.clone
        end

        def run_tests(env, cmds, as_root=true)
          tests = ''
          cmds.each do |cmd|
            tests += "
echo '***************************************************'
echo 'Running #{cmd}...'
time #{cmd}
echo 'Finished #{cmd}'
echo '***************************************************'
"
          end
          cmd = %{
set -e
pushd #{Constants.build_dir}/origin >/dev/null
export PATH=$GOPATH/bin:$PATH
#{tests}
popd >/dev/null
        }
          exit_code = 0
          if as_root
            _,_,exit_code = sudo(env[:machine], cmd, {:timeout => 60*60*4, :fail_on_error => false, :verbose => false})
          else
            _,_,exit_code = do_execute(env[:machine], cmd, {:timeout => 60*60*4, :fail_on_error => false, :verbose => false})
          end
          exit_code
        end

        #
        # Build and run the make commands
        #   for testing all run make test
        #   for testing unit tests only run make build check
        #   for testing assets run hack/test-assets.sh
        #
        # All env vars will be added to the beginning of the command like VAR=1 make test
        #
        def call(env)
          @options.delete :logs

          cmd_env = []
          build_targets = ["make"]
          if @options[:parallel]
            build_targets << '-j'
            build_targets << '--output-sync=recurse'
          end

          if @options[:all]
            cmd_env << 'ARTIFACT_DIR=/tmp/origin/e2e/artifacts'
            cmd_env << 'LOG_DIR=/tmp/origin/e2e/logs'
            cmd_env << 'TEST_ASSETS=true'
            cmd_env << 'TEST_ASSETS_HEADLESS=true'
            build_targets << 'test'
            # we want to test the output of build-release, this flag tells the makefile to skip the build dependency
            # so the command comes out to <cmd_env settings> make test SKIP_BUILD=true
            build_targets << "SKIP_BUILD=true"

            if @options[:skip_image_cleanup]
              cmd_env << 'SKIP_IMAGE_CLEANUP=1'
            end
          else
            build_targets << "check" if !@options[:skip_check]
          end

          if @options[:report_coverage]
            cmd_env << 'OUTPUT_COVERAGE=/tmp/origin/e2e/artifacts/coverage'
          end

          cmd = cmd_env.join(' ') + ' ' + build_targets.join(' ')
          env[:test_exit_code] = run_tests(env, [cmd], false)

          if env[:test_exit_code] == 0 && @options[:extended_test_packages].length > 0
            cmds = parse_extended(@options[:extended_test_packages])
            cmds = cmds.map{ |s| 'TEST_REPORT_DIR=/tmp/openshift-extended-tests/junit/extended ' + s }
            env[:test_exit_code] = run_tests(env, cmds, true)
          end


          # any other tests that should not be run as sudo
          if env[:test_exit_code] == 0 && @options[:all]
            cmds = ['hack/test-assets.sh']
            env[:test_exit_code] = run_tests(env, cmds, false)
          end

          @app.call(env)
        end

        # parse_extended parses the extended test tag
        # The valid syntax is:
        # [test][extended:core] will run **all** test cases in 'core' bucket
        # [test][extended:core(focus)] will run just test cases that matches 'focus' string in core bucket
        def parse_extended(tag)
          buckets = tag.split(",")
          cmds = []
          buckets.each do |bucket|
            if bucket.include?('(')
              focus = bucket.slice(bucket.index("(")+1..-2).split(" ").map { |i| Shellwords.escape(i.strip) }.join(" ")
              name = Shellwords.escape(bucket.slice(0..bucket.index("(")-1))
              cmds << "test/extended/#{name.strip}.sh --ginkgo.focus=\"#{focus}\""
            else
              cmds << "test/extended/#{Shellwords.escape(bucket.strip)}.sh"
            end
          end
          return cmds
        end

      end
    end
  end
end
