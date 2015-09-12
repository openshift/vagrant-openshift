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
      class InstallOpenshiftBaseDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          # Workaround to vagrant inability to guess interface naming sequence
          # Tell system to abandon the new naming scheme and use eth* instead
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          if is_fedora
            sudo(env[:machine], %{
if ! [[ -L /etc/udev/rules.d/80-net-setup-link.rules ]]; then
  ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
  rm -f /etc/sysconfig/network-scripts/ifcfg-enp0s3
fi
            })
          end

          ssh_user = env[:machine].ssh_info[:username]
          # FIXME: Move 'openshift/centos-mongodb' into openshift org and then
          #        add the image into 'repositories' constants
          #
          sudo(env[:machine], "yum install -y git fontconfig yum-utils wget make mlocate bind augeas vim docker-io hg bzr libselinux-devel vim tig glibc-static btrfs-progs-devel device-mapper-devel sqlite-devel libnetfilter_queue-devel gcc gcc-c++ e2fsprogs tmux tmux httpie ctags hg xfsprogs rubygems openvswitch bridge-utils bzip2 ntp screen java-1.?.0-openjdk bind-utils socat unzip Xvfb", {:timeout=>60*20})
          sudo(env[:machine], "yum install -y facter", {fail_on_error: false, :timeout=>60*10})

          # Install Chrome and chromedriver for headless UI testing
          sudo(env[:machine], %{
cd /tmp

# Add signing key for Chrome repo
wget https://dl.google.com/linux/linux_signing_key.pub
rpm --import linux_signing_key.pub

# Add Chrome yum repo
yum-config-manager --add-repo=http://dl.google.com/linux/chrome/rpm/stable/x86_64

# Install chrome
yum install -y google-chrome-stable 

# Install chromedriver
wget https://chromedriver.storage.googleapis.com/2.16/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
mv chromedriver /usr/bin/chromedriver
chown root /usr/bin/chromedriver
chmod 755 /usr/bin/chromedriver
          }, {:timeout=>60*10})

          #
          # FIXME: Need to install golang packages 'after' the 'gcc' is
          #        installed. See BZ#1101508
          #
          sudo(env[:machine], "yum install -y golang golang-pkg-linux-amd64 golang-src", {:timeout=>60*10})
          #
          sudo(env[:machine], %{

set -ex
# TODO Remove me ASAP
sed -i 's,^SELINUX=.*,SELINUX=permissive,' /etc/selinux/config
setenforce 0

systemctl enable ntpd

groupadd -f docker
usermod -a -G docker #{ssh_user}

sed -i "s,^OPTIONS='\\(.*\\)',OPTIONS='--insecure-registry=172.30.0.0/16 \\1'," /etc/sysconfig/docker
sed -i "s,^OPTIONS=-\\(.*\\),OPTIONS='--insecure-registry=172.30.0.0/16 -\\1'," /etc/sysconfig/docker

sed -i "s,^ADD_REGISTRY='\\(.*\\)',#ADD_REGISTRY='--add-registry=docker.io \\1'," /etc/sysconfig/docker

cat /etc/sysconfig/docker

# Force socket reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

mkdir -p /data/src
mkdir -p /data/pkg
mkdir -p /data/bin

GO_VERSION=($(go version))
echo "Detected go version: $(go version)"

if [[ ${GO_VERSION[2]} == "go1.4"* ]]; then
  GOPATH=/data go get golang.org/x/tools/cmd/cover
else
  GOPATH=/data go get code.google.com/p/go.tools/cmd/cover
fi

GOPATH=/data go get golang.org/x/tools/cmd/vet

chown -R #{ssh_user}:#{ssh_user} /data

sed -i "s,^#DefaultTimeoutStartSec=.*,DefaultTimeoutStartSec=240s," /etc/systemd/system.conf

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable docker
time systemctl start docker
          }, {:timeout=>60*30})
          @app.call(env)
        end
      end
    end
  end
end
