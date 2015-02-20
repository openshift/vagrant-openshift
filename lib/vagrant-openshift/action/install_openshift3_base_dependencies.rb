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
      class InstallOpenshift3BaseDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]
          # FIXME: Move 'openshift/centos-mongodb' into openshift org and then
          #        add the image into 'repositories' constants
          #
          sudo(env[:machine], "yum install -y git fontconfig yum-utils wget make mlocate bind augeas vim docker-io hg bzr libselinux-devel vim tig glibc-static btrfs-progs-devel device-mapper-devel sqlite-devel libnetfilter_queue-devel gcc gcc-c++ e2fsprogs tmux tmux httpie ctags hg xfsprogs rubygems openvswitch bridge-utils bzip2 screen java-1.?.0-openjdk")
          sudo(env[:machine], "yum install -y facter", {fail_on_error: false})
          #
          # FIXME: Need to install golang packages 'after' the 'gcc' is
          #        installed. See BZ#1101508
          #
          sudo(env[:machine], "yum install -y golang golang-pkg-linux-amd64 golang-src")
          #
          sudo(env[:machine], %{

set -x
# TODO Remove me ASAP
sed -i 's,^SELINUX=.*,SELINUX=permissive,' /etc/selinux/config
setenforce 0

groupadd docker
chown root:docker /var/run/docker.sock
usermod -a -G docker #{ssh_user}

sed -i "s,^OPTIONS='\\(.*\\)',OPTIONS='--insecure-registry=172.30.17.0/24 \\1'," /etc/sysconfig/docker
sed -i "s,^OPTIONS=-\\(.*\\),OPTIONS='--insecure-registry=172.30.17.0/24 -\\1'," /etc/sysconfig/docker
cat /etc/sysconfig/docker

# Force socket reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

mkdir -p /data/src
mkdir -p /data/pkg
mkdir -p /data/bin
GOPATH=/data go get code.google.com/p/go.tools/cmd/cover
chown -R #{ssh_user}:#{ssh_user} /data

systemctl daemon-reload
systemctl enable docker
systemctl start docker

docker pull openshift/docker-registry
          }, {:timeout=>60*20})
          @app.call(env)
        end
      end
    end
  end
end
