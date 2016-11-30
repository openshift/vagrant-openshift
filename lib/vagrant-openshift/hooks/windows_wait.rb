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
      class WindowsWait
        include CommandHelper

        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].config.openshift.autoconfigure_aws && is_windows?(env[:machine])
            env[:ui].info 'Waiting for instance to report "Windows is Ready to use"...'
            Fog.wait_for(1200) { /Message: Windows is Ready to use/.match(env[:aws_compute].get_console_output(env[:machine].id).body["output"]) }
          end

          @app.call(env)
        end
      end
    end
  end
end
