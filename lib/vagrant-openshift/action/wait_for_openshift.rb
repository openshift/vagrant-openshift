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
require 'open-uri'
require 'openssl'
require 'uri'

module Vagrant
  module Openshift
    module Action
      class WaitForOpenshift
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          puts 'Waiting on openshift to become active...'

          sudo(env[:machine], %{
active=false
i=0
while [ $i -lt 10 ]
do
  if systemctl is-active openshift 2>&1 > /dev/null
  then
    active=true
    break
  fi
  sleep 2
  i=$[$i+1]
done
if ! $active
then
  exit 1
fi
          })

          @app.call(env)
        end
      end
    end
  end
end
