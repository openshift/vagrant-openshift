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
          ssh_id   = env[:machine].id.gsub("-","")

          ssh_config_path = Pathname.new(File.expand_path("~/.ssh/config"))
          ssh_config_str = %{
Host verifier
  HostName #{ssh_host}
  Port     #{ssh_port}
  User     #{ssh_user}
  IdentityFile #{ssh_id_file}
          }

          if ssh_config_path.exist?
            if system( "grep -n 'Host verifier' #{ssh_config_path}" )
              lines = File.new(ssh_config_path.to_s).readlines
              idx = lines.index{ |l| l.match(/Host verifier/)}
              lines.map!{ |line| line.rstrip }

              lines.delete_at(idx)
              while(not (lines[idx].nil? or lines[idx].match(/Host /)))
                lines.delete_at(idx)
              end

              File.open(ssh_config_path.to_s, "w") do |file|
                file.write(lines.join("\n"))
                file.write(ssh_config_str)
              end
            else
              File.open(ssh_config_path.to_s, "a") do |file|
                file.write(ssh_config_str)
              end
            end
          else
            File.open(ssh_config_path.to_s, "w") do |file|
              file.write(ssh_config_str)
            end
            FileUtils.chmod(0600, ssh_config_path.to_s)
          end

          home_dir=File.join(ENV['HOME'], '.openshiftdev/home.d')
          if File.exists?(home_dir)
            Dir.glob(File.join(home_dir, '???*'), File::FNM_DOTMATCH).each {|file|
              puts "Installing ~/#{File.basename(file)}"
              system "scp #{file} verifier:"
            }
          end

          @app.call(env)
        end
      end
    end
  end
end