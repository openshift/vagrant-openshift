#--
# Copyright 2015 Red Hat, Inc.
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
      class BootstrapOpenshift3
        include CommandHelper
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]
          sudo(env[:machine], %Q[
set -x

echo "Bootstrap OpenShift3 Environment"

ORIGIN_PATH=/data/src/github.com/openshift/origin
cat > /etc/profile.d/openshift.sh <<DELIM
GOPATH=/data
PATH=$ORIGIN_PATH/_output/etcd/bin:$ORIGIN_PATH/_output/local/go/bin/:$GOPATH/bin:$PATH
OPENSHIFTCONFIG=/var/lib/openshift/openshift.local.certificates/admin/.kubeconfig
export GOPATH PATH KUBERNETES_MASTER OPENSHIFTCONFIG
DELIM

cat > /etc/sysconfig/openshift <<DELIM
GOPATH=/data
DELIM

source /etc/profile.d/openshift.sh

pushd $ORIGIN_PATH
  hack/install-etcd.sh
popd

systemctl stop openshift ||:

cp $ORIGIN_PATH/_output/local/go/bin/openshift /usr/bin
ln -sf /usr/bin/openshift /usr/bin/osc
mkdir -p /var/lib/openshift/
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
Description=OpenShift All-In-One
After=docker.service
Requires=docker.service
Documentation=https://github.com/openshift/origin

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/openshift
WorkingDirectory=/var/lib/openshift/
ExecStart=/usr/bin/openshift start --public-master=https://\\${HOST}:8443 --loglevel=0
ExecStartPost=/usr/bin/timeout 120 bash -c 'while [ ! -d /var/lib/openshift/openshift.local.certificates/admin ] ; do sleep 1; done'
ExecStartPost=/bin/sleep 1
ExecStartPost=/bin/chmod a+r -R /var/lib/openshift/openshift.local.certificates/admin
SyslogIdentifier=openshift-bootstrap

[Install]
WantedBy=multi-user.target
DELIM
systemctl daemon-reload
OUTERDELIM

chmod +x /usr/bin/generate_openshift_service
/usr/bin/generate_openshift_service

systemctl enable openshift.service

chown -R #{ssh_user}:#{ssh_user} /data
          ])

          @app.call(env)
        end
      end
    end
  end
end
