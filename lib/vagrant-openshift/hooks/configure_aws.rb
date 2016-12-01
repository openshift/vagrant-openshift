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
      class ConfigureAWS
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].config.openshift.autoconfigure_aws
            aws_creds = Vagrant::Openshift::AWS::aws_creds(env[:ui])

            aws = env[:machine].config.vm.get_provider_config(:aws)
            aws.access_key_id = aws_creds["AWSAccessKeyId"]
            aws.secret_access_key = aws_creds["AWSSecretKey"]
            aws.keypair_name = aws_creds["AWSKeyPairName"]

            box_info = YAML.load_file(Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml")))
            if !aws.ami.nil? && !aws.ami.start_with?("ami-")
              os, stage = aws.ami.split(":", 2)
              env[:machine].config.ssh.username = box_info[os.to_sym][stage.to_sym][:aws][:ssh_user]
            end
            env[:machine].config.ssh.private_key_path = [aws_creds["AWSPrivateKeyPath"]]
            env[:machine].config.vm.box = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
            env[:machine].config.vm.synced_folders["/vagrant"] = {:disabled => true, :guestpath => "/vagrant", :hostpath => "."}
          end

          @app.call(env)
        end
      end
    end
  end
end
