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
      class BuildGeardBroker
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          sudo(env[:machine], sync_bash_command('origin-server', %{
echo "Performing broker build..."
set -e
pushd broker/docker/origin-broker-builder
  docker build --rm -t origin-broker-builder .
popd
gear build /data/src/github.com/openshift/origin-server/ origin-broker-builder origin-broker
          }), {:timeout => 60*20})
          @app.call(env)
        end
      end
    end
  end
end