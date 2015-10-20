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
      class CloneUpstreamRepositories
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

          git_clone_commands = "set -e\n"
          Constants.repos(env).each do |repo_name, url|
            bare_repo_name = repo_name + "-bare"
            bare_repo_path = Constants.build_dir + bare_repo_name

            if @options[:clean]
              git_clone_commands += "rm -fr #{bare_repo_path};\n"
            end

            git_clone_commands += %{
if [ ! -d #{bare_repo_path} ]; then
git clone --quiet --bare #{url} #{bare_repo_path} >/dev/null
fi
}
          end

          sudo(env[:machine], "mkdir -p #{Constants.build_dir}")
          sudo(env[:machine], "mkdir -p #{Constants.build_dir + "builder"} && chown -R #{ssh_user}:#{ssh_user} #{Constants.build_dir}")
          do_execute env[:machine], git_clone_commands

          @app.call(env)
        end
      end
    end
  end
end
