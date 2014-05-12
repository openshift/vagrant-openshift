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
      class InstallGeardBaseDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          sudo(env[:machine], "yum install -y puppet git tito yum-utils wget make mlocate bind augeas vim docker-io golang hg bzr libselinux-devel vim tig glibc-static btrfs-progs-devel device-mapper-devel sqlite-devel libnetfilter_queue-devel gcc gcc-c++")
          sudo(env[:machine], %{
systemctl enable docker
systemctl start docker
docker pull openshift/centos-mongodb
if ! docker images | grep 'openshift/centos-mongodb' 2>&1 > /dev/null ; then
  docker pull openshift/centos-mongodb
fi
          }, {:timeout=>60*20})
          sudo(env[:machine], %{
docker pull openshift/centos-ruby
if ! docker images | grep 'openshift/centos-ruby' 2>&1 > /dev/null ; then
  docker pull openshift/centos-ruby
fi
touch #{Vagrant::Openshift::Constants.deps_marker}
          }, {:timeout=>60*20})
          #is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          @app.call(env)
        end
      end
    end
  end
end