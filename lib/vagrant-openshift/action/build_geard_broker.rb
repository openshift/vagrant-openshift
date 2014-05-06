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
          #TODO gear build does not support a local directory as a git clone source yet, so use the github URL for now
          #TODO branch should be configurable

          sudo(env[:machine], sync_bash_command('origin-server', %{
echo "Performing broker build..."
set -e
pushd broker/docker/origin-broker-builder
  docker build --rm -t origin-broker-builder .
popd
gear build https://github.com/openshift/origin-server.git origin-broker-builder origin-broker --ref='next_gen_node'
          }))
          @app.call(env)
        end
      end
    end
  end
end