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
      class InstallOriginBaseDependencies
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          # Migrate all of our scripts to the host machine
          ssh_user = @env[:machine].ssh_info[:username]
          destination="/home/#{ssh_user}/"
          @env[:machine].communicate.upload(File.join(__dir__,"/../resources"), destination)
          home="#{destination}/resources"

          # Workaround to vagrant inability to guess interface naming sequence:
          # Tell system to abandon the new naming scheme and use eth* instead if
          # we're communicating with a Fedora machine
          sudo(@env[:machine], "#{home}/reconfigure_network_fedora.sh")

          # Install base dependencies that we cannot continue without
          sudo(@env[:machine], "#{home}/install_dependencies.sh", :timeout=>60*30)

          # Install dependencies that are nice to have but we can live without
          sudo(@env[:machine], "#{home}/install_nonessential.sh", :timeout=>60*20, fail_on_error: false)

          # Install Chrome and chromedriver for headless UI testing
          sudo(@env[:machine], "#{home}/install_chrome.sh", :timeout=>60*60)

          sudo(env[:machine], "wget -O /etc/yum.repos.d/openshift-rhel7-dependencies.repo https://mirror.openshift.com/pub/openshift-origin/nightly/rhel-7/dependencies/openshift-rhel7-dependencies.repo", fail_on_error: true, :timeout=>60*20, :verbose => true)

          # Install Golang
          sudo(@env[:machine], "#{home}/install_golang.sh", :timeout=>60*60)

          # If we're on RHEL, install the RPM repositories for OSE and Docker
          is_rhel = @env[:machine].communicate.test("test -e /etc/redhat-release && ! test -e /etc/fedora-release && ! test -e /etc/centos-release")
          if is_rhel
            sudo(@env[:machine], "#{home}/install_rhaos_repos.sh")
            sudo(@env[:machine], "#{home}/install_dockerextra_repo.sh")
          end

          # Install Docker
          sudo(@env[:machine], "yum install -y docker", :timeout=>60*60)

          # Configure the machine system and the Docker daemon
          sudo(@env[:machine], "SSH_USER='#{ssh_user}' #{home}/configure_system.sh", :timeout=>60*30)
          sudo(@env[:machine], "SSH_USER='#{ssh_user}' #{home}/configure_docker.sh", :timeout=>60*30)

          @app.call(@env)
        end
      end
    end
  end
end