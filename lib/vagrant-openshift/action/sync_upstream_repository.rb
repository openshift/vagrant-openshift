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
      class SyncUpstreamRepository
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env[:machine].env.ui.info("Synchronizing upstream sources\n")
          command = "set -e"

          Constants.repos(env).each do |repo_name, url|

            branch="master"

            bare_repo_name = repo_name + "-bare"
            bare_repo_wc_name = repo_name + "-bare-working_copy"
            bare_repo_path = Constants.build_dir + bare_repo_name
            bare_repo_wc_path = Constants.build_dir + bare_repo_wc_name

            command += "export GIT_SSH=#{Constants.git_ssh};\n" unless Constants.git_ssh.nil? or Constants.git_ssh.empty?
            command += %{
if [ ! -d #{bare_repo_wc_path} ]; then
echo 'Cloning #{repo_name} ...'
git clone -l --quiet #{bare_repo_path} #{bare_repo_wc_path}
fi

cd #{bare_repo_wc_path}
git remote add upstream #{url}
git fetch upstream
git checkout master
git reset --hard upstream/#{branch}
git push origin master -f
}
          end

          do_execute(env[:machine], command)

          env[:machine].env.ui.info("Done")
          @app.call(env)
        end

      end
    end
  end
end
