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
    module Commands
      class BuildOriginBase < Vagrant.plugin(2, :command)
        include CommandHelper

        def execute
          options = {}
          options[:force] = false
          options[:local_source] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant build-origin-base [vm-name]"
            o.separator ""

            o.on("-f", "--force", "Delete existing repo before syncing") do |f|
              options[:force] = f
            end

            o.on("-l", "--local-source", "Build base VM based on local source") do |f|
              options[:local_source] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv, :reverse => true) do |machine|
            sudo machine, "yum -y update"
            sudo machine, "yum erase -y epel-release activemq"
            is_fedora = machine.communicate.test("test -e /etc/fedora-release")

            unless is_fedora
              sudo(machine, "yum -y install http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm")
              remote_write(machine, "/etc/yum.repos.d/puppet.repo") {
%{[puppet]
name=Puppet
baseurl=http://yum.puppetlabs.com/el/6/products/x86_64/
enabled=1
gpgcheck=0
exclude=mcollective*

[puppet-deps]
name=Puppet-Deps
baseurl=http://yum.puppetlabs.com/el/6/dependencies/x86_64/
enabled=1
gpgcheck=0}}
            end

            sudo(machine, "yum install -y puppet git tito yum-utils wget make tig mlocate")
            deps_mirror_url = nil
            if is_fedora
              sudo(machine, "yum install -y rubygem-rake https://mirror.openshift.com/pub/origin-server/nightly/fedora-19/dependencies/x86_64/activemq-5.6.0-6.fc19.x86_64.rpm")
              deps_mirror_url = "https://mirror.openshift.com/pub/origin-server/nightly/fedora-19/dependencies/x86_64/"
            else
              sudo(machine, "yum install -y ruby193-rubygem-rake https://mirror.openshift.com/pub/origin-server/nightly/rhel-6/dependencies/x86_64/activemq-5.6.0-6.fc19.x86_64.rpm")
              deps_mirror_url = "https://mirror.openshift.com/pub/origin-server/nightly/rhel-6/dependencies/x86_64/"
            end

            remote_write(machine, "/etc/yum.repos.d/openshift-origin-deps.repo") {
%{[openshift-origin-deps]
name=openshift-origin-deps
baseurl=#{deps_mirror_url}
gpgcheck=0
enabled=1}}

            sudo(machine, "wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo")
            sudo(machine, "rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key")

            remote_write(machine, "/root/.ssh/config", "root:root", "0600") {
%{Host github.com
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
}}

            ssh_user = machine.ssh_info[:username]
            sudo(machine, "mkdir -p #{Constants.build_dir}")
            machine.communicate.upload(File.expand_path("#{__FILE__}/../../../../builder"), Constants.build_dir.to_s )
            machine.communicate.upload(File.expand_path("#{__FILE__}/../../constants.rb"), (Constants.build_dir + "builder/lib/constants.rb").to_s )
            sudo(machine, "chmod +x #{Constants.build_dir + "builder/yum-listbuilddep"}; chown #{ssh_user}:#{ssh_user} -R #{Constants.build_dir}")

            require_relative "repo_sync"
            sync_args = []
            sync_args << "-f" if options[:force]
            sync_args << "-l" if options[:local_source]
            RepoSync.new(sync_args, @env).execute

            sudo(machine, "cd #{Constants.build_dir + "builder"}; rake openshift:install_deps")
            0
          end
        end
      end
    end
  end
end