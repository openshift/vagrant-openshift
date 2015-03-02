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

        def send_mail_notifications(recipients, registry)
          %{
set +x
if [ ! -f /tmp/push_images_result ]; then
  echo "noop" && exit 0
fi

echo "Sending notifications to #{recipients}"
echo -e "The list of Docker images pushed to #{registry}:\n" >> /tmp/mail_template

while read -r line; do
  image_name=$(echo -n $line | cut -d "/" -f 2,3 | cut -d ":" -f 1)
  echo "* ${image_name}" >> /tmp/mail_template
  echo -e "  $ docker pull ${line}\n" >> /tmp/mail_template
done < /tmp/push_images_result

count=$(echo -n `cat /tmp/push_images_result | wc -l`)
cat /tmp/mail_template | mail -r "Jenkins <noreply@redhat.com>" \
  -s "[Jenkins] ${count} Docker images pushed to #{registry}" #{recipients}
cat /tmp/mail_template
rm -f /tmp/mail_template /tmp/push_images_result
          }
        end

        def rhel7_images
          Vagrant::Openshift::Constants.openshift3_rhel7_base.merge(
            Vagrant::Openshift::Constants.openshift3_rhel7_images
          )
        end

        def centos7_images
          Vagrant::Openshift::Constants.openshift3_centos7_base.merge(
            Vagrant::Openshift::Constants.openshift3_centos7_images
          )
        end

        def clone_image_repos_cmd(repos, registry)
          cmd = %{set -e; set -x; cd /data/src/github.com; }
          # Perform git clone for all images repos in parallel
          repos.each do |name, git_url|
            cmd += %{
            ( rm -rf ./#{name}; git clone -q #{git_url} ./#{name} ) &
            }
          end
          # Wait for the clone to finish
          cmd += %{
          echo "Waiting for image GIT repositories to be cloned."
          wait
          }
          repos.each do |name, _|
            cmd += %{
rm -rf /tmp/force_rebuild*
pushd /data/src/github.com/#{name}
git rev-parse --short HEAD > .git-head
git_ref=`echo -n $(<.git-head)`
echo -n "#{registry}#{name}:$git_ref" > .docker-pull-name
set +e
docker pull $(<.docker-pull-name)
[ "$?" == "0" ] && touch .docker-build-skip
set -e
popd
            }
          end
          return cmd
        end

        def build_image(name, target, base_image, registry)
          cmd = %{
pushd /data/src/github.com/#{name}
git_ref=$(<.git-head)
image_name=$(<.docker-pull-name)

if [ -f .docker-build-skip -a ! -f /tmp/force_rebuild-#{target} ]; then
  echo "Already latest ${image_name} and no base image change, noop."
else
  echo "Building #{name}:$git_ref with #{target} target..."
  make build TARGET=#{target}

  if [ "$?" != 0 ]; then
    echo "ERROR: Failed to build ${image_name}"
  else
    echo "Tagging and pushing $image_name"
    if [ "#{registry}" != "" ]; then
      docker tag #{name} $image_name && docker push $image_name
      echo "${image_name}" >> /tmp/push_images_result
    else
      echo "#{name}:latest" >> /tmp/push_images_result
    fi
    docker tag #{name} #{registry}#{name}:latest && docker push #{registry}#{name}:latest


    # If this is a base image, force rebuild all image using it
    [ -z "#{base_image}" ] && touch /tmp/force_rebuild_#{target}
  fi
fi
popd
          }
          return cmd
        end

        def call(env)
          if @options[:registry].nil?
            @app.call(env)
            return
          end

          cmd = fix_insecure_registry_cmd(@options[:registry])

          if !@options[:registry].end_with?('/')
            @options[:registry] += "/"
          end

          cmd += clone_image_repos_cmd(rhel7_images, @options[:registry])
          cmd += clone_image_repos_cmd(centos7_images, "")
          cmd += %{
            set +e
          }
          # RHEL7 Docker images
          Vagrant::Openshift::Constants.openshift3_rhel7_base.each do |name, _|
            cmd += build_image(name, "rhel7", "", @options[:registry])
          end
          Vagrant::Openshift::Constants.openshift3_rhel7_images.each do |name, _|
            cmd += build_image(name, "rhel7", "rhel7", @options[:registry])

          end

          # Centos images goes to Docker hub
          Vagrant::Openshift::Constants.openshift3_centos7_base.each do |name, _|
            cmd += build_image(name, "centos7", "", "")
          end
          # Other language && STI images
          Vagrant::Openshift::Constants.openshift3_centos7_images.each do |name, _|
            cmd += build_image(name, "centos7", "centos7", "")
          end


          do_execute(env[:machine], cmd)
          do_execute(env[:machine], send_mail_notifications(
            "mfojtik@redhat.com",
            @options[:registry]
          ))
          @app.call(env)
        end
      end
    end
  end
end
