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
require 'xmlsimple'
require 'pry'

module Vagrant
  module Openshift
    module Action
      class ModifyAMI
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
            unless @options[:tag].nil?
              images = env[:aws_compute].images.all({"state" => "available", "name" => machine.tags["Name"]})
              images.each do |i|
                env[:aws_compute].create_tags(i.id, {'Name' => @options[:tag]})
                break
              end if images
            end
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
