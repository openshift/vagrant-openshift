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
      class SyncLocalRepository
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env[:machine].env.ui.info("Sync'ing local sources")

          Constants.repos.each do |repo_name, url|
            local_repo = Pathname.new(File.expand_path(env[:machine].env.root_path + repo_name))
            unless local_repo.exist?
              env[:machine].ui.warn "Missing local clone of repository #{local_repo}"
              next
            end

            FileUtils.cd(local_repo) do
              sync_repo(env[:machine], repo_name)
            end
          end

          @app.call(env)
        end

        private

        def sync_repo(machine, repo_name)
          begin
            temp_commit

            # Get the current branch
            branch = get_branch

            puts "Synchronizing local changes from branch #{branch} for repo #{repo_name} from #{File.basename(FileUtils.pwd)}..."

            command = ""
            command += "export GIT_SSH=#{Constants.git_ssh};\n" unless Constants.git_ssh.nil? or Constants.git_ssh.empty?
            command += "git push -q verifier:#{Constants.build_dir + repo_name}-bare master:master --tags --force;\n" if branch == 'origin/master'
            command += "git push -q verifier:#{Constants.build_dir + repo_name }-bare #{branch}:master --tags --force"
            exitcode = system(command)

            puts "Done"
          ensure
            reset_temp_commit
          end
        end

        def temp_commit
          # Warn on uncommitted changes
          `git diff-index --quiet HEAD`

          if $? != 0
            # Perform a temporary commit
            puts "Creating temporary commit to build"

            begin
              `git commit -m "Temporary commit #1 - index changes"`
            ensure
              (@temp_commit ||= []).push("git reset --soft HEAD^") if $? == 0
            end

            begin
              `git commit -a -m "Temporary commit #2 - non-index changes"`
            ensure
              (@temp_commit ||= []).push("git reset --mixed HEAD^") if $? == 0
            end

            puts @temp_commit ? "No-op" : "Done"
          end
        end

        def reset_temp_commit
          if @temp_commit
            puts "Undoing temporary commit..."
            while undo = @temp_commit.pop
              `#{undo}`
            end
            @temp_commit = nil
            puts "Done."
          end
        end

        def get_branch
          branch_str = `git status | head -n1`.chomp
          branch_str =~ /.*branch (.*)/
          branch = $1 ? $1 : 'origin/master'
          return branch
        end
      end
    end
  end
end