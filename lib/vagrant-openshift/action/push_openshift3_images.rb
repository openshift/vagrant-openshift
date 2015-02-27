#
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
      class PushOpenshift3Images
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        # FIXME: This is a temporary fix as the RHEL7 AMI should have this
        #        registry here already.
        def fix_insecure_registry_cmd(registry_url)
          %{
cat <<EOF > /etc/sysconfig/docker
OPTIONS='--insecure-registry #{registry_url} --selinux-enabled -H fd://'
EOF
systemctl restart docker
          }
        end

        def call(env)
          if @options[:registry].nil?
            @app.call(env)
            return
          end
          do_execute(env[:machine], fix_insecure_registry_cmd(@options[:registry])) 
          cmd = "set -x"
          Vagrant::Openshift::Constants.openshift3_images.each do |name, repo|
            cmd += %{
pushd /data/src/github.com
set -e
# Remove the directory if already exists (usefull for testing)
rm -rf ./#{name}
git clone #{repo} ./#{name}
set +e
popd


pushd /data/src/github.com/#{name}
git_ref=$(git rev-parse --short HEAD)

image_pull_spec="#{@options[:registry]}/#{name}:$git_ref"

docker pull $image_pull_spec
image_found=$?

if [ "$image_found" == "0" ]; then
  echo "Already have latest $image_pull_spec, noop."
else
  echo "Building #{name}:$git_ref..."
  make build

  if [ "$?" != 0 ]; then
    echo "Failed to build #{name}:$git_ref"
  else
    echo "Tagging and pushing $image_pull_spec"
    docker tag #{name} $image_pull_spec
    docker push $image_pull_spec

    echo "Tagging and pushing #{name}:latest"
    docker tag #{name} #{@options[:registry]}/#{name}:latest 
    docker push #{@options[:registry]}/#{name}:latest
  fi
fi
popd
            }
          end
          do_execute(env[:machine], cmd) 
          @app.call(env)
        end
      end
    end
  end
end
