#--
# Copyright 2015 Red Hat, Inc.
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
      class InstallDockerRegistry
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          puts 'Installing docker registry'
          sudo(env[:machine], %q[
set -x
source /etc/profile.d/openshift.sh

CMD="openshift admin registry --create --credentials=${OPENSHIFTCONFIG}"
OS_RUNNING=$(systemctl status openshift | /bin/grep "(running)")
if [[ $OS_RUNNING ]]; then
  ${CMD}
else
  echo "The OpenShift process is not running.  To install a docker registry please start OpenShift and run ${CMD}"
fi
])
          @app.call(env)
        end
      end
    end
  end
end
