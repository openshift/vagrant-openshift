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

        def call(env)
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")

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

              sudo env[:machine], "yum install -y http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm"
              remote_write(env[:machine], "/etc/yum.repos.d/epel.repo") {
                %{
[epel]
name=Extra Packages for Enterprise Linux 6 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch
exclude=*passenger* nodejs*
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 6 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch/debug
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-6&arch=$basearch
exclude=*passenger* nodejs*
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 6 - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/6/SRPMS
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-6&arch=$basearch
exclude=*passenger* nodejs*
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1
                  }
              }
            end

            remote_write(env[:machine], "/etc/yum.repos.d/puppet.repo") {
              %{[puppet]
name=Puppet
baseurl=http://yum.puppetlabs.com/el/6/products/x86_64/
enabled=1
gpgcheck=0
exclude=mcollective* activemq*

[puppet-deps]
name=Puppet-Deps
baseurl=http://yum.puppetlabs.com/el/6/dependencies/x86_64/
enabled=1
gpgcheck=0
exclude=mcollective* activemq*
}}

            #additonal SCL repos
            sudo env[:machine], "curl http://people.redhat.com/bkabrda/scl_python27.repo -o /etc/yum.repos.d/scl_python27.repo"
            sudo env[:machine], "curl http://sochotni.fedorapeople.org/nodejs010-RHSCL-1-RHEL-6/nodejs010.repo -o /etc/yum.repos.d/nodejs010.repo"
          end

          if is_fedora
            deps_mirror_url = "https://mirror.openshift.com/pub/origin-server/nightly/fedora-19/dependencies/x86_64/"
          else
            deps_mirror_url = "https://mirror.openshift.com/pub/origin-server/nightly/rhel-6/dependencies/x86_64/"
          end

          remote_write(env[:machine], "/etc/yum.repos.d/openshift-origin-deps.repo") {
            %{[openshift-origin-deps]
name=openshift-origin-deps
baseurl=#{deps_mirror_url}
gpgcheck=0
enabled=1}}

          unless env[:machine].communicate.test("test -f /etc/yum.repos.d/jenkins.repo")
            sudo(env[:machine], "yum install -y wget")
            sudo(env[:machine], "wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo")
            sudo(env[:machine], "rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key")
          end

          @app.call(env)
        end
      end
    end
  end
end
