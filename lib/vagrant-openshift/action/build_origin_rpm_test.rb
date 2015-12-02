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
      class BuildOriginRpmTest
        include CommandHelper

        def initialize(app, env, options={})
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]

          remote_write(env[:machine], "/#{ssh_user}/.ssh/config", "#{ssh_user}:#{ssh_user}", "0600") {
%{Host github.com
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
}}
          sudo(env[:machine], "mkdir -p #{Constants.build_dir}")
          sudo(env[:machine], "mkdir -p #{Constants.build_dir + "builder"} && chown -R #{ssh_user}:#{ssh_user} #{Constants.build_dir}")

          sudo(env[:machine], %{
set -e

sudo yum install -y tito

pushd #{Constants.build_dir}/origin
sudo yum-builddep ./origin.spec
sudo tito build --rpm --test
popd
})

          @app.call(env)
        end
      end
    end
  end
end
