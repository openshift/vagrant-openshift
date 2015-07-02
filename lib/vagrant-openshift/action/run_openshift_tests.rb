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
      class RunOpenshiftTests
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
            _,_,exit_code = sudo(env[:machine], cmd, {:timeout => 60*60*2, :fail_on_error => false, :verbose => false})
          else
            _,_,exit_code = do_execute(env[:machine], cmd, {:timeout => 60*60*2, :fail_on_error => false, :verbose => false})
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
            build_targets << "check"
          end

          if @options[:report_coverage]
            cmd_env << 'OUTPUT_COVERAGE=/tmp/origin/e2e/artifacts/coverage'
          end

          cmd = cmd_env.join(' ') + ' ' + build_targets.join(' ')
          env[:test_exit_code] = run_tests(env, [cmd], true)

          if env[:test_exit_code] == 0 && @options[:extended_test_packages].length > 0
            extended_cmd = 'hack/test-extended.sh ' + Shellwords.escape(@options[:extended_test_packages])
            env[:test_exit_code] = run_tests(env, [extended_cmd], true)
          end


          # any other tests that should not be run as sudo
          if env[:test_exit_code] == 0 && @options[:all]
            cmds = ['hack/test-assets.sh']
            env[:test_exit_code] = run_tests(env, cmds, false)
          end

          @app.call(env)
        end
      end
    end
  end
end
