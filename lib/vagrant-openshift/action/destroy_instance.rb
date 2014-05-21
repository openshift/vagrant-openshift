#--
# Copyright 2014 Red Hat, Inc.
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
require 'xmlsimple'

module Vagrant
  module Openshift
    module Action
      class DestroyInstance
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def cleanup_vagrant_machine(machine_name)
          FileUtils.rm_rf(
            File.join('.vagrant', 'machines', machine_name.to_s, 'aws'),
            :verbose => true
          )
        end

        def call(env)
          unless env[:machine].state.id == :running
            raise VagrantPlugins::AWS::Errors::FogError,
              :message => "Error: EC2 Machine is not available"
          end

          begin
            machine = env[:aws_compute].servers.get(env[:machine].id)
            machine_name = machine.tags["Name"]
            env[:aws_compute].tags.create(
              :resource_id => machine.identity,
              :key => 'Name',
              :value => "#{machine_name}-terminate"
            )
            env[:machine].ui.info("Instance #{machine_name} successfully marked for termination.")
            env[:machine].ui.info("Destroying #{machine_name}")
            cleanup_vagrant_machine(env[:machine].name)
          rescue Excon::Errors::BadRequest => e
            doc = XMLSimple.xml_in(e.response.body)
            code = doc['Response']['Errors']['Error']['Code'][0]
            message = doc['Response']['Errors']['Error']['Message'][0]
            raise VagrantPlugins::AWS::Errors::FogError, :message => "#{message}. Code: #{code}"
          end
          @app.call(env)
        end
      end
    end
  end
end
