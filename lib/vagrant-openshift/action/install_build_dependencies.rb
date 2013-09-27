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
      class InstallBuildDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          sudo(env[:machine], "yum install -y puppet git tito yum-utils wget make tig mlocate bind augeas vim")
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")

          if is_fedora
            sudo(env[:machine], "yum install -y rubygem-rake rubygem-fakefs")
          else
            sudo(env[:machine], "yum install -y ruby193-rubygem-rake ruby193-build scl-utils-build")
            #test dependencies
            sudo(env[:machine], "yum install -y ruby193-rubygem-net-ssh ruby193-rubygem-archive-tar-minitar ruby193-rubygem-fakefs ruby193-rubygem-httpclient")
          end
          @app.call(env)
        end
      end
    end
  end
end