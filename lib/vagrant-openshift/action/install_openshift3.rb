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
      class InstallOpenshift3
        include CommandHelper
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]
          sudo(env[:machine], %{
set -x

#systemctl enable firewalld
#systemctl start firewalld
#firewall-cmd --permanent --zone=public --add-port=8443/tcp
#firewall-cmd --permanent --zone=public --add-port=8444/tcp
#firewall-cmd --reload
#firewall-cmd --list-all


ORIGIN_PATH=/data/src/github.com/openshift/origin
cat > /etc/profile.d/openshift.sh <<DELIM
export GOPATH=/data
export PATH=$ORIGIN_PATH/_output/etcd/bin:$ORIGIN_PATH/_output/local/go/bin/:$GOPATH/bin:$PATH
#export KUBERNETES_MASTER=http://localhost:8080
export KUBECONFIG=/openshift.local.certificates/admin/.kubeconfig
DELIM

source /etc/profile.d/openshift.sh

pushd $ORIGIN_PATH
  hack/install-etcd.sh
popd

cat > /usr/bin/generate_openshift_service <<OUTERDELIM

HOST=\\`facter ec2_public_hostname 2>/dev/null | xargs echo -n\\`
if [ -z "\\$HOST" ]
then
  HOST=\\`ip -f inet addr show | grep -Po 'inet \\K[\\d.]+' | grep 10.245 | head -1\\`
  if [ -z "\\$HOST" ]
  then
    HOST=localhost
  fi
fi

echo Host: \\$HOST

cat > /usr/lib/systemd/system/openshift.service <<DELIM
[Unit]
Description=OpenShift
After=docker.service
Requires=docker.service
Documentation=https://github.com/openshift/origin

[Service]
Type=simple
EnvironmentFile=-/etc/profile.d/openshift.sh
ExecStart=$ORIGIN_PATH/_output/local/go/bin/openshift start --public-master=https://\\${HOST}:8443
ExecStartPost=/bin/chmod a+r -R /openshift.local.certificates/admin

[Install]
WantedBy=multi-user.target
DELIM
systemctl daemon-reload
OUTERDELIM

chmod +x /usr/bin/generate_openshift_service
/usr/bin/generate_openshift_service

#systemctl enable openshift.service

chown -R #{ssh_user}:#{ssh_user} /data
          })

          @app.call(env)
        end
      end
    end
  end
end
