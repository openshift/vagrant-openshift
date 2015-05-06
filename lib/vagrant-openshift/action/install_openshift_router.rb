#--
# Copyright 2014 Red Hat, Inc.
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
      class InstallOpenshiftRouter
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          puts 'Installing OpenShift router'

          label = @options[:image_label].nil? ?
              nil :
              %Q[--images=#{@options[:image_label].gsub('$', '\\$')}]

          sudo(env[:machine], %Q[
#{}set -x

CMD="openshift ex router --create --credentials=${OPENSHIFTCONFIG} #{label}"

if systemctl -q is-active openshift; then
  ROUTER_EXISTS=$(openshift ex router --credentials=${OPENSHIFTCONFIG} 2>&1 | grep "service exists")
  if [[ -z $ROUTER_EXISTS ]]; then
    echo "Installing OpenShift router"
    ${CMD}
  else
    echo "Router already exists, skipping"
  fi
else
  echo "The OpenShift process is not running.  To install a router please start openshift.service and run ${CMD}"
fi
])
          @app.call(env)
        end
      end
    end
  end
end
