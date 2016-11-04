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
      class ConfigureDockerServerLinux < Vagrant.plugin("2", :provisioner)
        def provision
          begin
            Dir.mkdir(".vagrant/docker-config")
          rescue Errno::EEXIST
          end

          cmd = %{
IP=$(ifconfig eth0 | awk '/inet / { print $2; }')
openssl genrsa -out /tmp/ca.key
openssl req -new -key /tmp/ca.key -subj /CN=CA -x509 -sha1 -days 7 -set_serial 1 -out /tmp/ca.crt
openssl genrsa -out /tmp/server.key
openssl req -new -key /tmp/server.key -subj /CN=$IP -out /tmp/server.csr
echo subjectAltName=IP:$IP | openssl x509 -req -in /tmp/server.csr -CA /tmp/ca.crt -CAkey /tmp/ca.key -days 7 -extfile /dev/stdin -set_serial 2 -out /tmp/server.crt
rm -f /tmp/server.csr
openssl genrsa -out /tmp/client.key
openssl req -new -key /tmp/client.key -subj /CN=client -out /tmp/client.csr
echo extendedKeyUsage=clientAuth | openssl x509 -req -in /tmp/client.csr -CA /tmp/ca.crt -CAkey /tmp/ca.key -days 7 -extfile /dev/stdin -set_serial 3 -out /tmp/client.crt
rm -f /tmp/client.csr
if ! grep -q tlsverify /etc/sysconfig/docker; then
  sed -i -e "s|^OPTIONS='|OPTIONS='--tlsverify --tlscacert=/tmp/ca.crt --tlscert=/tmp/server.crt --tlskey=/tmp/server.key -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2376 |" /etc/sysconfig/docker
fi
systemctl restart docker.service
echo -e "export DOCKER_HOST=tcp://$IP:2376\nexport DOCKER_TLS_VERIFY=1" >/tmp/dockerenv
}
          @machine.communicate.sudo(cmd)
          @machine.communicate.download("/tmp/ca.crt", ".vagrant/docker-config/ca.crt")
          @machine.communicate.download("/tmp/client.crt", ".vagrant/docker-config/client.crt")
          @machine.communicate.download("/tmp/client.key", ".vagrant/docker-config/client.key")
          @machine.communicate.download("/tmp/dockerenv", ".vagrant/docker-config/dockerenv")
        end
      end
    end
  end
end
