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
require 'xml'
require 'pry'

module Vagrant
  module Openshift
    module Action
      class ModifyInstance
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          raise VagrantPlugins::AWS::Errors::FogError, :message => "Error: EC2 Machine is not available" unless env[:machine].state.id == :running

          begin
            machine = env[:aws_compute].servers.get(env[:machine].id)
            unless @options[:rename].nil?
              env[:aws_compute].tags.create(:resource_id => machine.identity, :key => 'Name', :value => @options[:rename])
              env[:machine].ui.info("Renamed to #{@options[:rename]}")
            end
            if @options[:stop]
              env[:machine].ui.info("Stopping instance #{machine.identity}")
              machine.stop
              while env[:machine].state.id != :stopped
                sleep 5
              end
              env[:machine].ui.info("Stopped!")
            end
          rescue Excon::Errors::BadRequest => e
            doc = XML::Parser.string(e.response.body).parse
            code = doc.find("//Response/Errors/Error/Code").first.content
            message = doc.find("//Response/Errors/Error/Message").first.content
            raise VagrantPlugins::AWS::Errors::FogError, :message => "#{message}. Code: #{code}"
          end
          @app.call(env)
        end
      end
    end
  end
end