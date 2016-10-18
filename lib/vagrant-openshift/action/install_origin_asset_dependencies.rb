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
      class InstallOriginAssetDependencies
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options.clone
        end

        def call(env)
          cmd = %{
set -ex

ORIGIN_CONSOLE_PATH=/data/src/github.com/openshift/origin-web-console
ASSET_BACKUP_DIR=/data/asset_dependencies

if ! which npm > /dev/null 2>&1 ; then
  sudo yum -y install npm
  if $(test -e /etc/fedora-release)
  then
    # Update npm, we need a newer version than is installed by yum
    sudo npm install npm@3.7.3 -g
  fi
fi

}
          if @options[:restore_assets]
            cmd += %{
  # make sure the dirs always exist
  mkdir -p /data/asset_dependencies/node_modules
  mkdir -p /data/asset_dependencies/bower_components
  # copy them to the console repo
  cp -rf $ASSET_BACKUP_DIR/node_modules $ORIGIN_CONSOLE_PATH/node_modules
  cp -rf $ASSET_BACKUP_DIR/bower_components $ORIGIN_CONSOLE_PATH/bower_components

}
          end

          cmd += %{
pushd $ORIGIN_CONSOLE_PATH
  hack/install-deps.sh
popd

}

          if @options[:backup_assets]
            cmd += %{
  # Make sure tests pass before backing up this asset install
  pushd $ORIGIN_CONSOLE_PATH
    hack/test-headless.sh test
  popd
  mkdir -p $ASSET_BACKUP_DIR
  cp -rf $ORIGIN_CONSOLE_PATH/node_modules $ASSET_BACKUP_DIR/node_modules
  cp -rf $ORIGIN_CONSOLE_PATH/bower_components $ASSET_BACKUP_DIR/bower_components
}
          end

          do_execute(env[:machine], cmd, :verbose => false, :timeout=>60*60*2)
          @app.call(env)
        end
      end
    end
  end
end
