#--
# Copyright 2016 Red Hat, Inc.
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

require_relative "../aws"

module Vagrant
  module Openshift
    module Hooks
      class FindAMI
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].config.openshift.autoconfigure_aws
            aws = env[:machine].config.vm.get_provider_config(:aws)
            if !aws.ami.nil? && !aws.ami.start_with?("ami-")
              box_info = YAML.load_file(Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml")))
              os, stage = aws.ami.split(":", 2)
              aws.ami = Vagrant::Openshift::AWS::find_ami_from_tag(env[:ui], env[:aws_compute], box_info[os.to_sym][stage.to_sym][:aws][:ami_tag_prefix])
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
