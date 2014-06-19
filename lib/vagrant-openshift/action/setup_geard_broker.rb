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
#{bash_systemd_polling_functions}
#
gear list-units

echo "Waiting for origin-db and origin-broker to become available..."

if ! wait_for_activate origin-db; then
  echo "WARNING: The 'origin-db' container is not ACTIVE. Trying restart..."
  gear restart origin-db-1
  if ! wait_for_activate origin-db; then
    echo "ERROR: Unable to activate the origin-db container."
    gear status origin-db-1
    exit 1
  fi
fi

if ! wait_for_activate origin-broker; then
  echo "WARNING: The 'origin-broker' container is not ACTIVE. Trying restart..."
  gear restart origin-broker-1
  if ! wait_for_activate origin-broker; then
    echo "ERROR: Unable to activate the origin-broker container."
    gear status origin-broker-1
    exit 1
  fi
fi

echo "Install cartridges into broker"

retries=1
until [ $retries -ge 5 ]; do
    switchns --container="origin-broker-1" -- /bin/bash --login -c '$HOME/src/docker/openshift_init'
    [ $? == 0 ] && break
    echo "Installing cartridges failed ($?). Retry \#$retries" && sleep 1
    retries=$[$retries+1]
done
})
          @app.call(env)
        end
      end
    end
  end
end
