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
if [[ $(cat /etc/ssh/sshd_config | grep /gear-auth-keys-command) = "" ]]; then
  echo 'AuthorizedKeysCommand /usr/sbin/gear-auth-keys-command' >> /etc/ssh/sshd_config
  echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config
else
  echo "AuthorizedKeysCommand already configured"
fi

# SET fedora USER PATH VARIABLES: GOPATH, GEARD_PATH
if [[ $(cat ~fedora/.bash_profile | grep GOPATH) = "" ]]; then
  echo 'export GOPATH=/fedora' >> ~fedora/.bash_profile
  echo 'export PATH=$GOPATH/bin:$PATH' >> ~fedora/.bash_profile
  echo "cd $GEARD_PATH" >> ~fedora/.bashrc
  echo "bind '\"\e[A\":history-search-backward'" >> ~fedora/.bashrc
  echo "bind '\"\e[B\":history-search-forward'" >> ~fedora/.bashrc
else
  echo "fedora user path variables already configured"
fi

# SET ROOT USER PATH VARIABLES: GOPATH, GEARD_PATH
if [[ $(cat /root/.bash_profile | grep GOPATH) = "" ]]; then
  echo 'export GOPATH=/fedora' >> /root/.bash_profile
  echo 'export PATH=$GOPATH/bin:$PATH' >> /root/.bash_profile
  echo "cd $GEARD_PATH" >> /root/.bashrc
  echo "bind '\"\e[A\":history-search-backward'" >> /root/.bashrc
  echo "bind '\"\e[B\":history-search-forward'" >> /root/.bashrc
else
  echo "root user path variables already configured"
fi

echo "Performing initial geard build..."
su --login --shell="/bin/bash" --session-command "cd $GEARD_PATH && contrib/build" fedora

          })
          @app.call(env)
        end
      end
    end
  end
end