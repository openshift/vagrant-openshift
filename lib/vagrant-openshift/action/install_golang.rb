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

module Vagrant
  module Openshift
    module Action
      class InstallGolang
        include CommandHelper
        include InstallHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options.clone
        end

        def call(env)
          isolated_install(
            @env[:machine],
            'golang',
            @options[:"golang.version"],
            @options[:"golang.repourls"],
            @options[:"golang.reponames"],
            @options[:force]
          )

          if @options[:"golang.version"] =~ %r"^1\.4.*" && ! env[:machine].communicate.test("test -e /etc/fedora-release")
            # Prior to go1.5, the cgo symbol tables were not provided in the base golang
            # package on RHEL and CentOS, so if we've installed go1.4.x and we're not on
            # Fedora, we need to also install `golang-pkg-linux-amd64'
            sudo(@env[:machine], "yum install -y #{format_versioned_package("golang-pkg-linux-amd64", @options[:"golang.version"])}", :timeout=>60*5)
          end

          @app.call(@env)
        end
      end
    end
  end
end