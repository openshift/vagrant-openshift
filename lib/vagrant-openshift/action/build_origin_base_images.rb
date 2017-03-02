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
      class BuildOriginBaseImages
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          # Migrate the local epel repo to the host machine
          ssh_user = @env[:machine].ssh_info[:username]
          destination="/home/#{ssh_user}/"
          @env[:machine].communicate.upload(File.join(__dir__,"/../resources"), destination)
          home="#{destination}/resources"
          
          sudo(@env[:machine], "#{home}/install_local_epel_repos.sh")
          
          do_execute(env[:machine], %{
echo "Building base images..."
set -e
pushd /data/src/github.com/openshift/origin
  OS_BUILD_IMAGE_ARGS='--mount /etc/yum.repos.d/local_epel.repo:/etc/yum.repos.d/local_epel.repo' hack/build-base-images.sh
  # note dind image does not have any epel related installs
  if [[ -f "hack/build-dind-images.sh" ]]; then
    hack/build-dind-images.sh
  fi
popd
},
            { :timeout => 60*60*2, :verbose => false })
          @app.call(env)
        end

      end
    end
  end
end
