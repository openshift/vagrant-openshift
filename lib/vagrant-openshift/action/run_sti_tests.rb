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
      class RunStiTests
        include CommandHelper

        @@SSH_TIMEOUT = 4800

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options.clone
        end

        def call(env)
          @options.delete :logs

          cmds = ['OUTPUT_COVERAGE=/tmp/sti/artifacts/coverage hack/test-go.sh']

          if @options[:all]
            cmds << 'STI_TIMEOUT="--timeout 240s" hack/test-integration.sh'
          end

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

          _,_,env[:test_exit_code] = sudo(env[:machine], %{
set -e
pushd #{Constants.build_dir}/source-to-image >/dev/null
export PATH=$GOPATH/bin:$PATH
#{tests}
popd >/dev/null
          }, {:timeout => 60*60, :fail_on_error => false, :verbose => false})

          @app.call(env)
        end
      end
    end
  end
end
