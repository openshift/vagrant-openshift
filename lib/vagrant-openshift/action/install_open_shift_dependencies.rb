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
      class InstallOpenShiftDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")

          if is_fedora
            unless env[:machine].communicate.test("rpm -q activemq-5.6.0-6.fc19.x86_64")
              sudo(env[:machine], "yum erase -y activemq")
              sudo(env[:machine], "yum install -y https://mirror.openshift.com/pub/origin-server/nightly/fedora-19/dependencies/x86_64/activemq-5.6.0-6.fc19.x86_64.rpm")
            end
            sudo(env[:machine], "yum install -y rubygem-rake")
            sudo(env[:machine], "yum install -y rubygem-net-ssh-multi rubygem-net-ssh-gateway")
          else
            sudo(env[:machine], "yum install -y activemq")
            sudo(env[:machine], "yum install -y ruby193-rubygem-rake ruby193-build scl-utils-build")
            sudo(env[:machine], "yum install -y ruby193-rubygem-net-ssh-multi ruby193-rubygem-net-ssh-gateway")
          end

          sudo(env[:machine], "cd #{Constants.build_dir + "builder"}; #{scl_wrapper(is_fedora, 'rake install_deps')}", {timeout: 0})
          @app.call(env)
        end
      end
    end
  end
end