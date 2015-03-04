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

        def build_image(image_name, git_ref, repo_url, registry)
          %{
dest_dir="/data/src/github/openshift/#{image_name}"
rm -rf ${dest_dir}; mkdir -p ${dest_dir}
if git clone #{repo_url} ${dest_dir}; then
  pushd ${dest_dir}
    git checkout #{git_ref}
    git_ref=$(git rev-parse --short HEAD)
    echo "Building #{image_name}:$git_ref"

    if make build TARGET=centos7; then
      docker tag #{image_name}-centos7 #{registry}#{image_name}-centos7:$git_ref
      docker tag #{image_name}-centos7 #{registry}#{image_name}-centos7:latest
      docker tag #{image_name}-centos7 #{image_name}-centos7:latest
      docker push #{registry}#{image_name}-centos7:$git_ref
      docker push #{registry}#{image_name}-centos7:latest
      docker push #{image_name}-centos7:latest
    else
      echo "ERROR: Failed to build #{image_name}-centos7"
    fi

    if make build TARGET=rhel7; then
      docker tag #{image_name}-rhel7 #{registry}#{image_name}-rhel7:$git_ref
      docker tag #{image_name}-rhel7 #{registry}#{image_name}-rhel7:latest
      docker push #{registry}#{image_name}-rhel7:$git_ref
      docker push #{registry}#{image_name}-rhel7:latest
    else
      echo "ERROR: Failed to build #{image_name}-rhel7"
    fi
  popd
fi
          }
        end

        def update_latest_image_cmd(registry)
          cmd = %{
rm -rf ~/latest_images ; touch ~/latest_images
          }
          Vagrant::Openshift::Constants.openshift3_images.each do |name, git_url|
            cmd += %{
git_ref=$(git ls-remote #{git_url} -h refs/heads/master | cut -c1-7)
curl -s http://#{registry}v1/repositories/#{name}-rhel7/tags/${git_ref} | grep -q "error"
[ "$?" != "0" ] && echo "#{name};$git_ref" >> ~/latest_images
            }
          end
          return cmd
        end

        def call(env)
          cmd = fix_insecure_registry_cmd(@options[:registry])
          if !@options[:registry].end_with?('/')
            @options[:registry] += "/"
          end

          cmd += %{
set -x; set +e
echo "Pre-pulling base images"
docker pull #{@options[:registry]}openshift/base-centos7
[[ "$?" == "0" ]] && docker tag #{@options[:registry]}openshift/base-centos7 openshift/base-centos7
docker pull #{@options[:registry]}openshift/base-rhel7
[[ "$?" == "0" ]] && docker tag #{@options[:registry]}openshift/base-rhel7 openshift/base-rhel7
          }

          # FIXME: We always need to make sure we have the latest base image
          # FIXME: This is because the internal registry is pruned once per month
          if !@options[:build_images].include?("openshift/base")
            @options[:build_images] = "openshift/base:master,#{@options[:build_images]}"
          end

          build_images = @options[:build_images].split(",").map { |i| i.strip }

          build_images.each do |image|
            name, git_ref = image.split(':')
            repo_url = Vagrant::Openshift::Constants.openshift3_images[name]
            if repo_url == nil
              puts "Unregistred image: #{name}, skipping"
              next
            end
            cmd += build_image(name, git_ref, repo_url, @options[:registry])
          end

          cmd += update_latest_image_cmd(@options[:registry])

          do_execute(env[:machine], cmd)

          @app.call(env)
        end
      end
    end
  end
end
