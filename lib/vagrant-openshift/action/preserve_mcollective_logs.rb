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
      class PreserveMcollectiveLogs
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          unless env[:machine].communicate.test("grep 'keeplogs=9999' /etc/mcollective/server.cfg")
            env[:machine].ui.info "Keep all mcollective logs on remote instance"
            sudo(env[:machine], "echo keeplogs=9999 >> /etc/mcollective/server.cfg")
            is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
            if is_fedora
              sudo(env[:machine], "/sbin/service mcollective restart")
            else
              sudo(env[:machine], "/sbin/service ruby193-mcollective restart")
            end
          end

          @app.call(env)
        end
      end
    end
  end
end