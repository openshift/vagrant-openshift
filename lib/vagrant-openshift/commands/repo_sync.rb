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
    module Commands
      class RepoSync < Vagrant.plugin(2, :command)
        include CommandHelper

        def execute
          options = {}
          options[:force] = false
          options[:local_source] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant reposync [vm-name]"
            o.separator ""

            o.on("-f", "--force", "Delete existing repo before syncing") do |f|
              options[:force] = f
            end

            o.on("-l", "--local-source", "Build base VM based on local source") do |f|
              options[:local_source] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv, :reverse => true) do |machine|
            machine.env.ui.info("Initializing repos from github.com")
            init_repos(machine, options)

            if options[:local_source]
              machine.env.ui.info("Sync'ing local sources")
              sync_repos(machine)
            end

            machine.env.ui.info("Checking out repos on build machine")
            checkout_repos(machine)

            0
          end
        end

        private

        def checkout_repos(machine)
          checkout_commands = ""
          Constants.repos.each do |repo_name, url|
            bare_repo_name = repo_name + "-bare"
            bare_repo_path = Constants.build_dir + bare_repo_name
            repo_path = Constants.build_dir + repo_name

            checkout_commands += "rm -rf #{repo_path}; git clone #{bare_repo_path} #{repo_path}; "
            #checkout_commands += "pushd #{repo_name}; git checkout #{options.branch}; popd; "
          end

          sudo machine, checkout_commands
        end

        def init_repos(machine, options)
          git_clone_commands = ""
          Constants.repos.each do |repo_name, url|
            bare_repo_name = repo_name + "-bare"
            bare_repo_path = Constants.build_dir + bare_repo_name

            git_clone_commands += "if [ ! -d #{bare_repo_path} ]; then\n" unless options[:force]
            git_clone_commands += "rm -rf #{bare_repo_path}; git clone --bare #{url} #{bare_repo_path};\n"
            git_clone_commands += "fi\n" unless options[:force]
          end

          sudo machine, git_clone_commands
        end

        def sync_repos(machine)
          Constants.repos.each do |repo_name, url|
            local_repo = Pathname.new(File.expand_path(repo_name))
            require 'pry'; binding.pry;
            raise "Missing local clone of repository #{local_repo}" unless local_repo.exist?

            FileUtils.cd(repo_name) do
              sync_repo(machine, repo_name)
            end
          end
        end

        def sync_repo(machine, repo_name)
          begin
            temp_commit

            # Get the current branch
            branch = get_branch

            puts "Synchronizing local changes from branch #{branch} for repo #{repo_name} from #{File.basename(FileUtils.pwd)}..."

            ssh_user = machine.ssh_info[:username]
            ssh_host = machine.ssh_info[:hostname]
            ssh_port = machine.ssh_info[:port]

            exitcode = system(<<-"SHELL", :verbose => verbose)
          #######
          # Start shell code
          export GIT_SSH=#{Constants.git_ssh}
            #{branch == 'origin/master' ? "git push -q #{ssh_user}@#{hostname}:#{remote_repo_parent_dir}/#{repo_name}-bare master:master --tags --force; " : ''}
          git push -q #{ssh_user}@#{hostname}:#{remote_repo_parent_dir}/#{repo_name}-bare #{branch}:master --tags --force

          #######
          # End shell code
            SHELL

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