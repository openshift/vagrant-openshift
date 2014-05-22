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
          ssh_user = env[:machine].ssh_info[:username]
          sudo(env[:machine], %{
set -x
TODO Remove me ASAP
setenforce 0
usermod -a -G docker #{ssh_user}

GEARD_PATH=/data/src/github.com/openshift/geard
chown -R #{ssh_user}:#{ssh_user} /data

# Modify SSHD config to use gear-auth-keys-command to support git clone from repo
echo 'AuthorizedKeysCommand /usr/sbin/gear-auth-keys-command' >> /etc/ssh/sshd_config
echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config

cat > /etc/profile.d/geard.sh <<DELIM
export GOPATH=/data
export PATH=$GOPATH/bin:$PATH
DELIM

cat > /usr/lib/systemd/system/geard.service <<DELIM
[Unit]
Description=Gear Provisioning Daemon (geard)
Documentation=https://github.com/openshift/geard

[Service]
Type=simple
EnvironmentFile=-/etc/default/gear
ExecStart=/data/bin/gear daemon $GEARD_OPTS

[Install]
WantedBy=multi-user.target
DELIM

systemctl restart sshd
systemctl enable geard.service

          })

          @app.call(env)
        end
      end
    end
  end
end