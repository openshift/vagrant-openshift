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
      class InstallOpenshift3Rhel7
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
set -x

# inside temporary directory create docker build context for the new base image
contextdir=$(mktemp -d)

# copy the necessary files
mkdir $contextdir/{certs,repos,vars}
cp /var/lib/yum/*.pem $contextdir/certs
cp /etc/yum/vars/* $contextdir/vars
cp /etc/yum.repos.d/* $contextdir/repos

# create Dockerfile
cat <<EOF > $contextdir/Dockerfile
FROM rhel7:latest

RUN yum remove -y subscription-manager

ADD vars/* /etc/yum/vars/
ADD repos/* /etc/yum.repos.d/
ADD certs/* /var/lib/yum/

RUN yum update -y && yum clean all

EOF

# make old official image backup and build the new "official"
docker tag rhel7:latest rhel7:latest_official
docker build --rm -t rhel7:latest $contextdir

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
