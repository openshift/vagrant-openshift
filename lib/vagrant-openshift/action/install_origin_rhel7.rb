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
      class InstallOriginRhel7
        include CommandHelper
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          is_centos = env[:machine].communicate.test("test -e /etc/centos-release")
          is_rhel   = env[:machine].communicate.test("test -e /etc/redhat-release") && !is_centos && !is_fedora
          if is_rhel
            ssh_user = env[:machine].ssh_info[:username]
            sudo(env[:machine], %{
set -ex

# inside temporary directory create docker build context for the new base image
contextdir=$(mktemp -d)

# copy the necessary files
mkdir $contextdir/{certs,repos,vars,keys}
cp /var/lib/yum/*.pem $contextdir/certs
cp /etc/yum/vars/* $contextdir/vars
cp /etc/yum.repos.d/* $contextdir/repos
cp /etc/pki/rpm-gpg/* $contextdir/keys

# Remove repositories we won't be needing and which require RH certs
rm -rf $contextdir/repos/redhat-rhui*

# remove google chrome repo
rm -rf $contextdir/repos/*chrome*.repo

# create Dockerfile
cat <<EOF > $contextdir/Dockerfile
FROM registry.access.redhat.com/rhel7.1:latest

RUN yum remove -y subscription-manager

ADD vars/* /etc/yum/vars/
ADD repos/* /etc/yum.repos.d/
ADD certs/* /var/lib/yum/
ADD keys/* /etc/pki/rpm-gpg/

# we're picking up 7.2 packages in our 7.1 image and these two conflict, so
# first replace the 7.1 package with the new 7.2 package so later updates/dep
# installations don't fail.
RUN yum swap -y -- remove systemd-container\* -- install systemd systemd-libs

RUN yum update -y && yum clean all

EOF

docker build --rm -t rhel7:latest $contextdir
docker tag rhel7:latest rhel7.1

# create Dockerfile
cat <<EOF > $contextdir/Dockerfile
FROM registry.access.redhat.com/rhel7.2:latest

RUN yum remove -y subscription-manager

ADD vars/* /etc/yum/vars/
ADD repos/* /etc/yum.repos.d/
ADD certs/* /var/lib/yum/
ADD keys/* /etc/pki/rpm-gpg/

RUN yum update -y && yum clean all

EOF

docker build --rm -t rhel7.2 $contextdir

# make sure the new rhel7.2 image has valid certs
docker run rhel7.2 yum install -y tar

# cleaning
rm -rf $contextdir
            })
          end
          @app.call(env)
        end
      end
    end
  end
end
