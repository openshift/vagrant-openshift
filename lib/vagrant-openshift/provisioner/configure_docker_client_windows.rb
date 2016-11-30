#--
# Copyright 2016 Red Hat, Inc.
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
    module Provisioner
      class ConfigureDockerClientWindows < Vagrant.plugin("2", :provisioner)
        def provision
          @machine.communicate.execute(%{mkdir -p /cygdrive/c/Users/Administrator/.docker})
          @machine.communicate.upload(".vagrant/docker-config/ca.crt", "/cygdrive/c/Users/Administrator/.docker/ca.pem")
          @machine.communicate.upload(".vagrant/docker-config/client.crt", "/cygdrive/c/Users/Administrator/.docker/cert.pem")
          @machine.communicate.upload(".vagrant/docker-config/client.key", "/cygdrive/c/Users/Administrator/.docker/key.pem")
          @machine.communicate.upload(".vagrant/docker-config/dockerenv", ".dockerenv")

          cmd = %{
if ! grep -q dockerenv .bash_profile; then
  echo ". .dockerenv" >>.bash_profile
fi
}
          @machine.communicate.execute(cmd)
        end
      end
    end
  end
end
