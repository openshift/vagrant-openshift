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
require 'yaml'

module Vagrant
  module Openshift
    module Action
      class SetupBuilderFiles
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          ssh_user = env[:machine].ssh_info[:username]
          sudo(env[:machine], "rm -rf #{Constants.build_dir}")
          sudo(env[:machine], "mkdir #{Constants.build_dir}")
          sudo(env[:machine], "mkdir -p #{Constants.build_dir + "builder"}; chown #{ssh_user}:#{ssh_user} #{Constants.build_dir + "builder"};")
          sudo(env[:machine], "mkdir -p #{Constants.build_dir}")
          env[:machine].communicate.upload(File.expand_path("#{__FILE__}/../../templates/builder"), Constants.build_dir.to_s )
          env[:machine].communicate.upload(File.expand_path("#{__FILE__}/../../constants.rb"), (Constants.build_dir + "builder/lib/constants.rb").to_s )
          sudo(env[:machine], "chmod +x #{Constants.build_dir + "builder/yum-listbuilddep"}; chown #{ssh_user}:#{ssh_user} -R #{Constants.build_dir}")
          remote_write(env[:machine], Constants.build_dir + "builder/lib/options.rb") do
%{
require 'yaml'
OPTIONS = YAML.load(
  "#{
    {
      :ignore_packages      => env[:machine].config.openshift.ignore_packages,
      :cloud_domain         => env[:machine].config.openshift.cloud_domain,
      :additional_services  => env[:machine].config.openshift.additional_services,
    }.to_yaml}"
  )
}
          end

          @app.call(env)
        end
      end
    end
  end
end