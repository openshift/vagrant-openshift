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
      class RestartGeardBroker
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          #TODO the second line is a temporary hack due to the selinux policies being outdated in the repo
          #TODO post geard fixes, remove sleep 2, and gear init from sudo below
          sudo(env[:machine], %{
set -e
gear restart origin-broker-1
sleep 2
gear init --post "origin-broker-1" "origin-broker"
          })
        end

      end
    end
  end
end