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
      class BuildGeardImages
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          # FIXME: Measure what would be the appropriate timeout here as the
          #        docker build command can take quite a long time...
          #
          Constants.cartridges.each do |repo_name, _|
            docker_image_name = "openshift/#{repo_name}"
            sudo(env[:machine], sync_bash_command(repo_name, %{
echo "Building #{docker_image_name} image"
docker build --rm -t #{docker_image_name} .
            }), { :timeout => 60*20 })
          end
          @app.call(env)
        end

      end
    end
  end
end
