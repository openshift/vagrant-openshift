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
require 'pathname'

module Vagrant
  module Openshift
    module Action
      class DownloadArtifactsOpenshift3
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          machine = @env[:machine]
          machine.ui.info "Downloading logs"
          ssh_info = machine.ssh_info
          private_key_path = ssh_info[:private_key_path].kind_of?(Array) ? ssh_info[:private_key_path][0] : ssh_info[:private_key_path]

          artifacts_dir = Pathname.new(File.expand_path(machine.env.root_path + "artifacts"))
          download_map = {
            "/var/log/yum.log"                     => artifacts_dir + "yum.log",
            "/var/log/secure"                      => artifacts_dir + "secure",
            "/var/log/audit/audit.log"             => artifacts_dir + "audit.log",
            "/tmp/origin/e2e/"                     => artifacts_dir + "e2e/",
          }

          download_map.each do |source,target|
            machine.ui.info "Downloading artifacts from '#{source}' to '#{target}'"
            if target.to_s.end_with? '/'
              FileUtils.mkdir_p target.to_s
            else
              FileUtils.mkdir_p File.dirname(target.to_s)
            end

            command = "/usr/bin/rsync -avz -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{private_key_path}' --rsync-path='sudo rsync' #{ssh_info[:username]}@#{ssh_info[:host]}:#{source} #{target}"

            if not system(command)
              machine.ui.warn "Unable to download artifacts"
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
