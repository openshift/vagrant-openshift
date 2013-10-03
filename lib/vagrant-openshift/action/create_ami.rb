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

module Vagrant
  module Openshift
    module Action
      class CreateAMI
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
            image_req = env[:aws_compute].create_image(machine.identity, machine.tags["Name"], machine.tags["Name"], true)
            image = env[:aws_compute].images.get(image_req.body["imageId"])
            env[:machine].ui.info "Creating AMI #{image.id}"
            while not image.ready?
              sleep 10
              image = env[:aws_compute].images.get(image_req.body["imageId"])
            end
            env[:machine].ui.info("Done")
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