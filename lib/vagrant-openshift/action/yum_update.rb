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
      class YumUpdate
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          sudo env[:machine], "rm -rf /etc/yum.repos.d/openshift-origin.repo"
          sudo env[:machine], "yum clean all"
          sudo env[:machine], "yum -y update --skip-broken --exclude=kernel*", {fail_on_error: false, :timeout=>60*10}
          sudo env[:machine], "yum list installed"

          env[:machine].ui.warn "Increasing YUM cache timeout to 9999999. You will need manually clear cache to get additional updates."
          remote_write(env[:machine], "/etc/yum.conf") {
            %{
[main]
cachedir=/var/cache/yum/$basearch/$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=0
plugins=1
installonly_limit=3

#  This is the default, if you make this bigger yum won't see if the metadata
# is newer on the remote and so you'll "gain" the bandwidth of not having to
# download the new metadata and "pay" for it by yum not having correct
# information.
#  It is esp. important, to have correct metadata, for distributions like
# Fedora which don't keep old packages around. If you don't like this checking
# interrupting your command line usage, it's much better to have something
# manually check the metadata once an hour (yum-updatesd will do this).
metadata_expire=9999999

# PUT YOUR REPOS HERE OR IN separate files named file.repo
# in /etc/yum.repos.d
            }
          }

          @app.call(env)
        end
      end
    end
  end
end
