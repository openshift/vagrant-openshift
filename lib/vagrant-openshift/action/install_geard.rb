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
      class InstallGeard
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          sudo(env[:machine], %{
set -x
usermod -a -G docker fedora
systemctl enable docker.service
systemctl start docker
systemctl status docker

mkdir -p /fedora/src/github.com/openshift/pkg
mkdir -p /fedora/src/github.com/openshift/bin
cp -r /data/geard /fedora/src/github.com/openshift/

GEARD_PATH=/fedora/src/github.com/openshift/geard
chown -R fedora:fedora /fedora

# Modify SSHD config to use gear-auth-keys-command to support git clone from repo
echo 'AuthorizedKeysCommand /usr/sbin/gear-auth-keys-command' >> /etc/ssh/sshd_config
echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config

# SET fedora USER PATH VARIABLES: GOPATH, GEARD_PATH
echo 'export GOPATH=/fedora' >> ~fedora/.bash_profile
echo 'export PATH=$GOPATH/bin:$PATH' >> ~fedora/.bash_profile

# SET ROOT USER PATH VARIABLES: GOPATH, GEARD_PATH
echo 'export GOPATH=/fedora' >> /root/.bash_profile
echo 'export PATH=$GOPATH/bin:$PATH' >> /root/.bash_profile


cat > /usr/lib/systemd/system/geard.service <<DELIM
[Unit]
Description=Gear Provisioning Daemon (geard)
Documentation=https://github.com/openshift/geard

[Service]
Type=simple
EnvironmentFile=-/etc/default/gear
ExecStart=/fedora/bin/gear daemon $GEARD_OPTS

[Install]
WantedBy=multi-user.target
DELIM

systemctl restart sshd
systemctl enable geard.service

          })

          do_execute(env[:machine], %{
echo "Performing initial geard build..."
pushd /fedora/src/github.com/openshift/geard
  contrib/build -s
popd
          })
        end
      end
    end
  end
end