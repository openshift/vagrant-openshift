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
      class PrepareSshConfig
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]
          ssh_host = env[:machine].ssh_info[:host]
          ssh_port = env[:machine].ssh_info[:port]
          ssh_id_file = env[:machine].ssh_info[:private_key_path]
          if ssh_id_file.kind_of?(Array)
            ssh_id_file = ssh_id_file.first
          end

          vagrant_openshift_ssh_override_path = Constants.git_ssh
          vagrant_openshift_ssh_override_str = "/usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -i #{ssh_id_file} $@"
          File.open(vagrant_openshift_ssh_override_path.to_s, "w") do |file|
            file.write(vagrant_openshift_ssh_override_str)
          end
          FileUtils.chmod(0744, vagrant_openshift_ssh_override_path.to_s)

          home_dir=File.join(ENV['HOME'], '.openshiftdev/home.d')
          if File.exists?(home_dir)
            Dir.glob(File.join(home_dir, '???*'), File::FNM_DOTMATCH).each {|file|
              puts "Installing ~/#{File.basename(file)}"
              puts "#{ssh_id_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null #{file} #{ssh_user}@#{ssh_host}:#{ssh_port}"
              system "scp -P #{ssh_port} -i #{ssh_id_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null #{file} #{ssh_user}@#{ssh_host}:~"
            }
          end

          @app.call(env)
        end
      end
    end
  end
end
