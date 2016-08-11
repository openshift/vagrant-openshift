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
require "tempfile"
require "timeout"

module Vagrant
  module Openshift
    module CommandHelper

      def sudo(machine, command, options={})
        options[:sudo] = true
        do_execute(machine, command, options)
      end

      def do_execute(machine, command, options={})
        stdout = []
        stderr = []
        rc = -1

        options = {
          timeout: 60*60*4,
          verbose: true,
          retries: 0,
          fail_on_error: true
        }.merge(options || {})

        execute = lambda { |type, data|
          if [:stderr, :stdout].include?(type)
            if type == :stdout
              color = :green
              stdout << data
            else
              color = :red
              stderr << data
            end
            machine.env.ui.info(data, :color => color, :new_line => false, :prefix => false) unless options[:buffered_output] == true
          end
        }

        # if verbose output is requested, we don't mess with vagrant's built-in SSH error handling
        # otherwise, we ask for muted SSH error handling to reduce the clutter
        if options[:verbose]
          opts = nil
        else
          opts = { :error_key => :ssh_bad_exit_status_muted }
        end

        (0..options[:retries]).each do |retry_count|
          begin
            if options[:verbose]
              machine.env.ui.info "Running ssh/sudo command '#{command}' with timeout #{options[:timeout]}. Attempt ##{retry_count}"
            elsif retry_count > 0
              machine.env.ui.info "Retrying. Attempt ##{retry_count} with timeout #{options[:timeout]}"
            end
            Timeout::timeout(options[:timeout]) do
              if options[:sudo]
                rc = machine.communicate.sudo(command, opts, &execute)
              else
                rc = machine.communicate.execute(command, opts, &execute)
              end
            end
          rescue Timeout::Error
            machine.env.ui.warn "Timeout occurred while running ssh/sudo command: #{command}"
            rc = -1
          rescue Exception => e
            machine.env.ui.warn "Error while running ssh/sudo command: #{command}"
            machine.env.ui.warn e.message
            rc ||= -1
          end
          break if rc == 0
        end
        exit rc if options[:fail_on_error] && rc != 0
        [stdout, stderr, rc]
      end

      def remote_write(machine, dest, owner="root", perms="0644", &block)
        file = Tempfile.new('file')
        begin
          file.write(block.yield)
          file.flush
          file.close
          machine.communicate.upload(file.path, "/tmp/#{File.basename(file)}")
          dest_dir = File.dirname(dest)
          sudo(machine,
%{mkdir -p #{dest_dir};
mv /tmp/#{File.basename(file)} #{dest} &&
chown #{owner} #{dest} &&
chmod #{perms} #{dest}})
        ensure
          file.unlink
        end
      end

      def sync_bash_command(repo_name, build_cmd, file_path="", branch_name=Vagrant::Openshift::Constants.git_branch_current, sync_path=Vagrant::Openshift::Constants.sync_dir, commit_id_path="#{sync_path}/#{repo_name}")
        refname = branch_name
        refname = "#{refname}:#{file_path}" if !file_path.empty?
        git_status_cmd = "git status --porcelain"
        git_status_cmd = "#{git_status_cmd} | grep #{file_path}" if !file_path.empty?
        cmd = %{
pushd /data/src/github.com/openshift/#{repo_name}
  commit_id=`git rev-parse #{refname}`
  git_status=$(#{git_status_cmd})
  if [ -f #{commit_id_path} ]
  then
    previous_commit_id=$(cat #{commit_id_path})
  fi
  if [ "$previous_commit_id" != "$commit_id" ] || [ -n "$git_status" ]
  then
    #{build_cmd}
  else
    echo "Commit ID: $commit_id"
    echo "Previous Commit ID: $previous_commit_id"
    echo "Git Status: $git_status"
    echo "No update for #{repo_name}, #{refname}"
  fi
  mkdir -p #{sync_path}
  echo -n $commit_id > #{commit_id_path}
popd
        }

      end

      def sync_bash_command_on_dockerfile(repo_name, dockerfile_build_path, build_cmd)
        file_path = "#{dockerfile_build_path}/Dockerfile"
        branch_name=Vagrant::Openshift::Constants.git_branch_current
        sync_path = "#{Vagrant::Openshift::Constants.sync_dir}/dockerfile/#{repo_name}/#{dockerfile_build_path}"
        commit_id_path = "#{sync_path}/Dockerfile"
        sync_bash_command(repo_name, build_cmd, file_path, branch_name, sync_path, commit_id_path)
      end

      def repo_checkout_bash_command(repo, url)
        repo_path = File.expand_path(repo)
        command = ""
        branch = @options[:branch] || 'master'
        if Pathname.new(repo_path).exist?
          if @options[:replace]
            command += %{
set -e
echo 'Replacing: #{repo_path}'
pushd #{repo_path}
  git fetch origin
  git checkout #{branch}
  git reset --hard origin/#{branch}
  git clean -fdx
  set +e
  git branch | grep -ve " #{branch}$" | xargs git branch -D
  #git gc
  set -e
popd
}
          else
            command += "echo 'Already cloned: #{repo}'\n"
          end
        else
          command += %{
cloned=false
echo 'Cloning #{repo} ...'
}

          if @options[:user]
            user_repo_url="git@github.com:#{@options[:user]}/#{repo}"
            command += %{
echo 'Cloning #{user_repo_url}'
git clone --quiet --recurse-submodules #{user_repo_url}
if [ $? -eq 0 ]; then
cloned=true
(cd #{repo} && git remote add upstream #{url} && git fetch upstream)
else
echo 'Fork of repo #{repo} not found. Cloning read-only copy from upstream'
fi
}

          end
          command += %{
[ $cloned != true ] && git clone --quiet --recurse-submodules #{url}
(cd #{repo} && git checkout #{branch} &>/dev/null)
}
        end

        command
      end

      def bash_systemd_polling_functions
        command = %{
function wait_for_success {
  local retries=1
  local cmd=$1
  until [ $retries -ge 21 ]; do
    /bin/sh -c $cmd
    [ $? == 0 ] && return 0
    echo "Command '$cmd' failed ($?). Retry \#${retries}" && sleep 1
    retries=$[$retries+1]
  done
}

function wait_for_activate {
  local retries=0
  local unit="$1"
  until [ $retries -ge 20 ]; do
    state=$(systemctl is-active ctr-${unit}-1.service)
    [ "$state" == "active" ] && return 0
    [ "$state" == "failed" ] && break
    echo "Waiting for ${unit} to become active (${state})" && sleep 1
    retries=$[$retries+1]
  done
  echo "The unit ctr-${unit}-1.service failed to activate."
  return 1
}
}
        return command
      end

    end
  end
end
