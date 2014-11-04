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
    class Provisioner < Vagrant.plugin(2, :provisioner)
      include CommandHelper

      # Called with the root configuration of the machine so the provisioner
      # can add some configuration on top of the machine.
      #
      # During this step, and this step only, the provisioner should modify
      # the root machine configuration to add any additional features it
      # may need. Examples include sharing folders, networking, and so on.
      # This step is guaranteed to be called before any of those steps are
      # done so the provisioner may do that.
      #
      # No return value is expected.
      def configure(root_config)

      end

      # This is the method called when the actual provisioning should be
      # done. The communicator is guaranteed to be ready at this point,
      # and any shared folders or networks are already setup.
      #
      # No return value is expected.
      def provision
        #check if OpenShift has been installed
        #reapply puppet configuration so that IPs and ifcfg-* file is correct
        if @machine.communicate.test("test -d /etc/openshift")
          @machine.ui.info("Reapplying puppet script to update changed IP values")
          hostname = @machine.config.vm.hostname
          sudo(machine,"echo #{hostname} > /proc/sys/kernel/hostname")
          sudo(machine,"puppet apply --verbose #{Vagrant::Openshift::Constants.build_dir + 'configure_origin.pp'}", {timeout: 60*20})
          is_fedora = @machine.communicate.test("test -e /etc/fedora-release")

          sudo(machine,Constants.restart_services_cmd(is_fedora).join("\n"))
          if @machine.config.openshift.additional_services.size > 0
            cmd = ""
            @machine.config.openshift.additional_services.each do |service|
              cmd += "service #{service} restart;"
            end
            sudo(machine,cmd)
          end

          # TODO: Replace this temporary fix with a complete post-install routine
          sudo(machine,"oo-admin-ctl-cartridge -c import-node --activate --obsolete && RAILS_ENV=test oo-admin-ctl-cartridge -c import-node --activate --obsolete")
        else
          #TODO is_fedora is a temporary fix for the new environment
          is_fedora = @machine.communicate.test("test -e /etc/fedora-release")
          if is_fedora
            ssh_user = machine.ssh_info[:username]
            sync_dir = Vagrant::Openshift::Constants.sync_dir
            ## pause to stabilize environment to try to correct odd sudo error on aws
            sleep 2
            sudo(machine, "mkdir -p #{sync_dir} && chown -R #{ssh_user}:#{ssh_user} #{sync_dir}")
          end
          unless is_fedora || @machine.communicate.test("test -f #{Vagrant::Openshift::Constants.deps_marker}")
            @machine.ui.info("Preparing base environment")
            require_relative "command/build_openshift2_base"
            Vagrant::Openshift::Commands::BuildOpenshift2Base.new([], @machine.env).execute
            @machine.communicate.sudo("touch #{Vagrant::Openshift::Constants.deps_marker}")
          end
        end
      end
    end
  end
end
