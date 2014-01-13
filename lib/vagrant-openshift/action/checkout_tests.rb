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
    module Action
      class CheckoutTests
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          is_fedora = env[:machine].communicate.test("test -e /etc/fedora-release")
          sudo env[:machine], "cd #{Constants.build_dir}/builder; #{scl_wrapper(is_fedora,'rake checkout_tests')}"

          sudo env[:machine], "mkdir -p /var/www/html/binaryartifacts"
          sudo env[:machine], "restorecon /var/www/html/binaryartifacts"

          remote_write(env[:machine], "/etc/httpd/conf.d/binaryartifacts.conf", "root:root", "0644") {
            %{#
# This configuration is to host the binary artifacts for use during testing.
# Currently the apache only hosts on https and with a cert that is not signed
# so curl requires -k.  To get around this in testing just host it over non-ssl
# and test test copies the tgz file to the /var/www/html/binaryartifacts folder.
#

Listen 81

<VirtualHost *:81>
  ServerName localhost
  ServerAdmin root@localhost
  DocumentRoot /var/www/html/binaryartifacts
</VirtualHost>}}
          sudo env[:machine], "restorecon -v /etc/httpd/conf.d/binaryartifacts.conf"
          sudo env[:machine], "service httpd restart"
          @app.call(env)
        end
      end
    end
  end
end