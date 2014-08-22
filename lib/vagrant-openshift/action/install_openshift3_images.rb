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
      class InstallOpenshift3Images
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          Vagrant::Openshift::Constants.images.each do |image_name, _|
            puts "Importing #{image_name} from Docker index"
            sudo(env[:machine], pull_docker_image_cmd(image_name), {
              :timeout=>60*20
            })
          end
          @app.call(env)
        end

        def pull_docker_image_cmd(image_name)
          %{
docker pull '#{image_name}'
if ! docker inspect '#{image_name}' 2>&1 > /dev/null
then
  docker pull '#{image_name}'
fi
          }
        end

      end
    end
  end
end
