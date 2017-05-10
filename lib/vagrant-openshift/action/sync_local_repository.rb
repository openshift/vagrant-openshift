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

        def initialize(app, env, options={})
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          env[:machine].env.ui.info("Synchronizing local sources")

          Constants.repos_for_name(@options[:repo]).each do |repo_name, url|
            local_repo = Pathname.new(File.expand_path(File.join(env[:machine].env.root_path, "..", repo_name)))
            unless local_repo.exist?
              local_repo = Pathname.new(File.expand_path(File.join(env[:machine].env.root_path, repo_name)))
              unless local_repo.exist?
                env[:machine].ui.warn "Missing local clone of repository #{repo_name}"
                next
              end
            end

            Dir.chdir(local_repo) { sync_repo(env[:machine], repo_name) }
          end

          @app.call(env)
        end

        private

        def sync_repo(machine, repo_name)
          begin
            temp_commit

            # Get the current branch
            branch = get_branch

            puts "Synchronizing [#{repo_name}@#{branch}] from #{File.basename(FileUtils.pwd)}..."

            ssh_user = machine.ssh_info[:username]
            ssh_host = machine.ssh_info[:host]
            ssh_port = machine.ssh_info[:port]

            command = "export GIT_SSH=#{Constants.git_ssh};\n"

            if branch == 'origin/master'
              command += "git push -q ssh://#{ssh_user}@#{ssh_host}:#{ssh_port}#{Constants.build_dir + repo_name}-bare master:master --tags --force;\n"
            end
            command += "git push -q ssh://#{ssh_user}@#{ssh_host}:#{ssh_port}#{Constants.build_dir + repo_name}-bare #{branch}:master --tags --force"

            exit_status = 1
            retries = 0
            while exit_status != 0
              system(command)
              exit_status = $?.exitstatus
              exit exit_status if exit_status != 0 && retries >= 2
              retries += 1
            end
          ensure
            reset_temp_commit
          end
        end

        def temp_commit
          # Warn on uncommitted changes
          %x[git diff-index --quiet HEAD]

          if $?.exitstatus != 0
            # Perform a temporary commit
            puts "Creating temporary commit to build"

            begin
              %x[git commit -m "Temporary commit #1 - index changes"]
            ensure
              (@temp_commit ||= []).push("git reset --soft HEAD^") if $?.exitstatus == 0
            end

            begin
              `git commit -a -m "Temporary commit #2 - non-index changes"`
            ensure
              (@temp_commit ||= []).push("git reset --mixed HEAD^") if $?.exitstatus == 0
            end

            puts @temp_commit ? "No-op" : "Done"
          end
        end

        def reset_temp_commit
          if @temp_commit
            puts "Undoing temporary commit..."
            while undo = @temp_commit.pop
              %x[#{undo}]
            end
            @temp_commit = nil
            puts "Done."
          end
        end

        def get_branch
          (%x[git status | head -n1].chomp =~ /.*branch (.*)/) ? $1 : 'origin/master'
        end

      end
    end
  end
end
