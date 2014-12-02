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
      class RunOpenshift3Tests
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
            _,_,exit_code = sudo(env[:machine], cmd, {:timeout => 60*60, :fail_on_error => false, :verbose => false})
          else
            _,_,exit_code = do_execute(env[:machine], cmd, {:timeout => 60*60, :fail_on_error => false, :verbose => false})
          end
          exit_code
        end

        def call(env)
          @options.delete :logs

          if @options[:report_coverage]
            cmds = ['OUTPUT_COVERAGE=/tmp/origin/e2e/artifacts/coverage hack/test-go.sh']
          else
            cmds = ['hack/test-go.sh']
          end

          if @options[:all]
            cmds << 'hack/test-integration.sh'
            cmds << 'hack/test-cmd.sh'
            if @options[:skip_image_cleanup]
              cmds << 'SKIP_IMAGE_CLEANUP=1 ARTIFACT_DIR=/tmp/origin/e2e/artifacts LOG_DIR=/tmp/origin/e2e/logs hack/test-end-to-end.sh'
            else
              cmds << 'ARTIFACT_DIR=/tmp/origin/e2e/artifacts LOG_DIR=/tmp/origin/e2e/logs hack/test-end-to-end.sh'
            end
          end

          env[:test_exit_code] = run_tests(env, cmds, true)

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
