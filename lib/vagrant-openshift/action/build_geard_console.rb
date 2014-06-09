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
      class BuildGeardConsole
        include CommandHelper

        def initialize(app, env, options = {})
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          docker_file_path = "console/docker/origin-console-builder"
          build_builder_cmd = %{
echo "Performing origin-console-builder build..."
set -e
pushd #{Constants.build_dir}origin-server/#{docker_file_path}
  docker build --rm #{@options[:force] ? "--no-cache" : ""} -t origin-console-builder .
popd
          }
          build_console_cmd = %{
echo "Performing console build..."
set -e
gear build #{Constants.build_dir}origin-server/ origin-console-builder origin-console --verbose
          }
          if @options[:force]
            sudo(env[:machine], build_builder_cmd + build_console_cmd, {:timeout => 60*40})
          else
            sudo(env[:machine], sync_bash_command_on_dockerfile('origin-server', docker_file_path, build_builder_cmd), {:timeout => 60*20})

            sudo(env[:machine], sync_bash_command('origin-server', build_console_cmd), {:timeout => 60*20})
            @app.call(env)
          end
        end
      end
    end
  end
end
