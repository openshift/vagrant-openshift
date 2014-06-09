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

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          # FIXME: Measure what would be the appropriate timeout here as the
          #        docker build command can take quite a long time...
          #
          @options[:geard_images].each do |geard_image, _|
            docker_image_name = "openshift/#{geard_image}"
            docker_file_path = "#{Constants.build_dir}#{geard_image}"
            build_cmd = %{
echo "Building #{docker_image_name} image"
pushd #{docker_file_path}
  docker build --rm #{@options[:force] ? "--no-cache" : ""} -t #{docker_image_name} .
popd
            }
            if @options[:force]    
              sudo(env[:machine], build_cmd, { :timeout => 60*20 })
            else
              sudo(env[:machine], sync_bash_command(geard_image, build_cmd), { :timeout => 60*20 })
            end
          end
          @app.call(env)
        end

      end
    end
  end
end
