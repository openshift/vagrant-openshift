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

ORIGIN_PATH=/data/src/github.com/openshift/origin
ASSET_BACKUP_DIR=/data/asset_dependencies

if ! which npm > /dev/null 2>&1 ; then
  sudo yum -y install npm
fi

SKIP_INSTALL=1
}
          if @options[:restore_assets]
            cmd += %{
  # copy them to the assets dir
  if [[ -d $ASSET_BACKUP_DIR/node_modules ]]; then
    cp -rf $ASSET_BACKUP_DIR/node_modules $ORIGIN_PATH/assets/node_modules
  fi
  if [[ -d $ASSET_BACKUP_DIR/bower_components ]]; then
    cp -rf $ASSET_BACKUP_DIR/bower_components $ORIGIN_PATH/assets/bower_components
  fi
  if [[ -f $ASSET_BACKUP_DIR/go-bindata ]]; then
    mkdir -p $ORIGIN_PATH/Godeps/_workspace/bin
    cp -f $ASSET_BACKUP_DIR/go-bindata $ORIGIN_PATH/Godeps/_workspace/bin/go-bindata
  fi

  echo "Using restored assets, checking package.json and bower.json for updates..."
  SKIP_INSTALL=0
  diff $ORIGIN_PATH/assets/package.json $ASSET_BACKUP_DIR/package.json || SKIP_INSTALL=$?
  if [[ $SKIP_INSTALL -eq 0 ]]; then
    diff $ORIGIN_PATH/assets/bower.json $ASSET_BACKUP_DIR/bower.json || SKIP_INSTALL=$?
  fi
}
          end

          cmd += %{
if [[ $SKIP_INSTALL -ne 0 ]]; then
  pushd $ORIGIN_PATH
    hack/install-assets.sh
  popd
fi

}

          if @options[:backup_assets]
            cmd += %{
  if [[ SKIP_INSTALL -ne 0 ]]; then
    rm -rf $ASSET_BACKUP_DIR
    mkdir -p $ASSET_BACKUP_DIR
    cp -r $ORIGIN_PATH/assets/node_modules $ASSET_BACKUP_DIR/node_modules
    cp -r $ORIGIN_PATH/assets/bower_components $ASSET_BACKUP_DIR/bower_components
    cp $ORIGIN_PATH/assets/package.json $ASSET_BACKUP_DIR/package.json
    cp $ORIGIN_PATH/assets/bower.json $ASSET_BACKUP_DIR/bower.json  
    cp $ORIGIN_PATH/Godeps/_workspace/bin/go-bindata $ASSET_BACKUP_DIR/go-bindata
  fi
}
          end

          do_execute(env[:machine], cmd, :verbose => false, :timeout=>60*20)
          @app.call(env)
        end
      end
    end
  end
end
