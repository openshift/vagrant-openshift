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
          @env = env
        end

        def set_yum_repo(env, file, repo_name, baseurl)
          unless baseurl.nil?
            sudo(env[:machine], %{
(
  echo "set /files#{file}/#{repo_name}/baseurl #{baseurl}"
  echo "set /files#{file}/#{repo_name}/gpgcheck 0"
  echo "rm  /files#{file}/#{repo_name}/mirrorlist"
  echo save
) | augtool
              })
          end
        end

        def call(env)
          options = env[:global_config].openshift
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          is_centos = env[:machine].communicate.test("test -e /etc/centos-release")
          is_rhel   = env[:machine].communicate.test("test -e /etc/redhat-release") && !is_centos && !is_fedora

          sudo(env[:machine], "yum install -y augeas")
          if is_centos
            sudo(env[:machine], "yum install -y centos-release-SCL.x86_64 http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm")
            set_yum_repo(env, "/etc/yum.repos.d/CentOS-Base.repo", "base", options.os_repo)
            set_yum_repo(env, "/etc/yum.repos.d/CentOS-Base.repo", "updates", options.os_updates_repo)
            set_yum_repo(env, "/etc/yum.repos.d/CentOS-Base.repo", "extras", options.os_extras_repo)
            set_yum_repo(env, "/etc/yum.repos.d/epel.repo", "epel", options.optional_repo)
            set_yum_repo(env, "/etc/yum.repos.d/CentOS-SCL.repo", "scl", options.os_scl_repo)
          end

          if is_rhel
            set_yum_repo(env, "/etc/yum.repos.d/RHEL-Base.repo", "base", options.os_repo)
            set_yum_repo(env, "/etc/yum.repos.d/RHEL-Base.repo", "updates", options.os_updates_repo)
            set_yum_repo(env, "/etc/yum.repos.d/epel.repo", "epel", options.optional_repo)
            set_yum_repo(env, "/etc/yum.repos.d/RHEL-SCL.repo", "scl", options.os_scl_repo)

          end

          if is_fedora
            set_yum_repo(env, "/etc/yum.repos.d/fedora.repo", "fedora", options.os_repo)
            set_yum_repo(env, "/etc/yum.repos.d/fedora.repo", "updates", options.os_updates_repo)
          end

          if options.repos_base == nil
            if is_fedora
                options.repos_base = "http://mirror.openshift.com/pub/openshift-origin/nightly/fedora-19/"
            elsif is_centos or is_rhel
                options.repos_base = "http://mirror.openshift.com/pub/openshift-origin/nightly/rhel-6/"
            end

            packages = "#{options.repos_base}/packages/latest/x86_64"
            dependencies = "#{options.repos_base}/dependencies/x86_64"
          else
            packages = "#{options.repos_base}/packages/x86_64"
            dependencies = "#{options.repos_base}/dependencies/x86_64"
          end

          set_yum_repo(env, "/etc/yum.repos.d/openshift.repo", "origin-deps", dependencies)

          sudo(env[:machine], "yum clean all")

          unless is_fedora
            unless env[:machine].communicate.test("rpm -q epel-release")
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
          end

          @app.call(env)
        end
      end
    end
  end
end
