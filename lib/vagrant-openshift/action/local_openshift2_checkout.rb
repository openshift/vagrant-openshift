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
      class LocalOpenshift2Checkout
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          commands = "echo 'Waiting for the cloning process to finish'\n"
          Constants.openshift2_repos.each do |repo, url|
            commands += %{
( #{repo_checkout_bash_command(repo, url)} ) &
PIDS+=$!\" \";
}
          end

          commands += "[ -n \"$PIDS\" ] && wait $PIDS\n"

          system(commands)

          @app.call(env)
        end
      end
    end
  end
end
