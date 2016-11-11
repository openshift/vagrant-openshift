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
      class CreateYumRepositories
        include CommandHelper

        def initialize(app, env)
          @app = app
        end

        def set_yum_repo(env, file, repo_name, baseurl)
          unless baseurl.nil?
            sudo(env[:machine], %{
(
  echo "set /files#{file}/#{repo_name}/baseurl #{baseurl}"
  echo "set /files#{file}/#{repo_name}/gpgcheck 0"
  echo "set /files#{file}/#{repo_name}/name #{repo_name}"
  echo "rm  /files#{file}/#{repo_name}/mirrorlist"
  echo save
) | augtool
              })
          end
        end

        def call(env)
          options = env[:machine].config.openshift
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          is_centos = env[:machine].communicate.test("test -e /etc/centos-release")
          is_rhel   = env[:machine].communicate.test("test -e /etc/redhat-release") && !is_centos && !is_fedora

          sudo(env[:machine], "yum -y install deltarpm", {fail_on_error: false})
          sudo(env[:machine], "yum -y install augeas")

          if is_centos
            set_yum_repo(env, "/etc/yum.repos.d/openshift-deps.repo", "openshift-deps", "https://mirror.openshift.com/pub/openshift-v3/dependencies/centos7/x86_64/")
          end

          sudo(env[:machine], "yum clean all")

          unless is_fedora
            #Workaround broken RHEL image which does not recover after restart.
            if "VagrantPlugins::AWS::Provider" == env[:machine].provider.class.to_s
              remote_write(env[:machine], "/etc/rc.local") {
%{#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
if [ ! -d /root/.ssh ] ; then
    mkdir -p /root/.ssh
    chmod 0700 /root/.ssh
    restorecon /root/.ssh
fi

# bz 707364
if [ ! -f /etc/blkid/blkid.tab ] ; then
        blkid /dev/xvda &>/dev/null
fi
}}
                sudo env[:machine], "chmod og+x /etc/rc.local"
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
