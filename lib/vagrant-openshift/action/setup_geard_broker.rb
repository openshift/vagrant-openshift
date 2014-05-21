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
      class SetupGeardBroker
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)          
          sudo(env[:machine], %{            
echo "Install cartridges into broker"
switchns --container="origin-broker-1" --env="BROKER_SOURCE=1" --env="HOME=/opt/ruby" --env="OPENSHIFT_BROKER_DIR=/opt/ruby/src/broker" -- /bin/bash --login -c "/opt/ruby/src/docker/openshift_init"
          })
          @app.call(env)
        end
      end
    end
  end
end