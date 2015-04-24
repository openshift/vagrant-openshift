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
      class SetupSamplePolicy
        include CommandHelper

        def initialize(app, env)
          @app = app
        end

        def call(env)
          puts 'Creating cluster-admin policy'

          sudo(env[:machine], %q[
set -x
source /etc/profile.d/openshift.sh
openshift admin policy add-role-to-group cluster-admin system:authenticated --config=${OPENSHIFTCONFIG} --namespace=master
          ])

          @app.call(env)
        end
      end
    end
  end
end
