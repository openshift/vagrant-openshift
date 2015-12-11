#
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
      class CreateLocalYumRepo
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          if @options[:rpmdir_loc]
            rpmdir_loc = @options[:rpmdir_loc]
          else
            rpmdir_loc = '/tmp/tito/x86_64/'
          end
          ssh_user = env[:machine].ssh_info[:username]

          sudo(env[:machine], %{
set -e

sudo yum install -y createrepo
sudo chmod -R og+w #{rpmdir_loc} /etc/yum.repos.d/
sudo createrepo #{rpmdir_loc}
sudo printf "[origin_local]\nname=origin\nbaseurl=file://#{rpmdir_loc}\nenabled=1\ngpgcheck=0\n" > /etc/yum.repos.d/origin_local.repo
sudo chmod -R og-w /etc/yum.repos.d/
sudo yum clean all
sudo yum repolist all
})

          @app.call(env)
        end
      end
    end
  end
end
