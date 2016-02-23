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
      class BuildOriginImages
        include CommandHelper

        def initialize(app, env, options={})
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]

          sudo(env[:machine], "mkdir -p #{Constants.build_dir}")
          sudo(env[:machine], "mkdir -p #{Constants.build_dir + "builder"} && chown -R #{ssh_user}:#{ssh_user} #{Constants.build_dir}")

          sudo(env[:machine], %{
set -e

pushd #{Constants.build_dir}origin/images/base
sudo cp -r #{Constants.build_dir}x86_64 .
sudo cp /etc/yum.repos.d/origin_local.repo .
docker build -t openshift/origin-base -f Dockerfile.rpm .
popd
})
          
          @app.call(env)
        end
      end
    end
  end
end
