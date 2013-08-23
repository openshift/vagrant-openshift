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
    module CommandHelper
      def sudo(machine, command)
        machine.communicate.sudo(command) do |type, data|
          if [:stderr, :stdout].include?(type)
            color = type == :stdout ? :green : :red
            machine.env.ui.info(data, :color => color, :new_line => false, :prefix => false)
          end
        end
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
    end
  end
end