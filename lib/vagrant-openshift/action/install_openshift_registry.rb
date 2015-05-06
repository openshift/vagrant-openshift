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
      class InstallOpenshiftRegistry
        include CommandHelper

        def initialize(app, env, options)
          @app         = app
          @env         = env
          @options     = options
        end

        def call(env)
          puts 'Installing OpenShift registry'

          proxy_command = @options[:with_registry_proxy].nil? ?
              nil :
              %q[osc create -f $ORIGIN_PATH/images/proxyregistry/pod.json]

          label = @options[:image_label].nil? ?
              nil :
              %Q[--images=#{@options[:image_label].gsub('$', '\\$')}]

          sudo(env[:machine], %Q[
#set -x
source /etc/profile.d/openshift.sh

CMD="openshift admin registry --credentials=${OPENSHIFTCONFIG} #{label}"

if systemctl -q is-active openshift; then
  ${CMD}
  #{proxy_command}
else
  echo "The OpenShift process is not running.  To install a registry please start openshift.service and run ${CMD}"
fi
])
          @app.call(env)
        end
      end
    end
  end
end
