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
          # FIXME: Move 'openshift/centos-mongodb' into openshift org and then
          #        add the image into 'repositories' constants
          #
          sudo(env[:machine], "yum install -y puppet git tito yum-utils wget make mlocate bind augeas vim docker-io hg bzr libselinux-devel vim tig glibc-static btrfs-progs-devel device-mapper-devel sqlite-devel libnetfilter_queue-devel gcc gcc-c++")
          #
          # FIXME: Need to install golang packages 'after' the 'gcc' is
          #        installed. See BZ#1101508
          #
          sudo(env[:machine], "yum install -y golang golang-pkg*  golang-src")
          #
          sudo(env[:machine], %{
systemctl daemon-reload
systemctl enable docker
systemctl start docker
docker pull dockerfile/ruby
if ! docker images | grep 'dockerfile/ruby' 2>&1 > /dev/null ; then
  docker pull dockerfile/ruby
fi
docker pull openshift/docker-builder
if ! docker images | grep 'openshift/docker-builder' 2>&1 > /dev/null ; then
  docker pull openshift/docker-builder
fi
touch #{Vagrant::Openshift::Constants.deps_marker}
          }, {:timeout=>60*20})
          @app.call(env)
        end
      end
    end
  end
end
