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
require_relative "../action"

module Vagrant
  module Openshift
    module Commands

      class TestOpenshiftImage < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "tests an image"
        end

        def execute
          options = {}
          options[:image] = nil
          options[:ref] = 'master'
          options[:source] = nil
          options[:base_images] = false
          options[:registry] = ""

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant test-openshift-image --image IMAGE [vm-name]"
            o.separator ""

            o.on("-i", "--image IMAGE", String, "image to test") do |o|
              options[:image] = o
            end

            o.on("-r", "--ref REF", String, "git ref to test") do |o|
              options[:ref] = o
            end

            o.on("-s", "--source SOURCE", String, "git repo source url") do |o|
              options[:source] = o
            end

            o.on("-b", "--base_images", "flag whether the base images have to be pre-pulled") do
              options[:base_images] = true
            end

            # FIXME: This is a temporary fix as the RHEL7 AMI should have this
            #        registry here already.
            o.on("--registry [url]", String, "Docker Registry to push images to.") do |o|
              options[:registry] = o
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if options[:image].nil? and options[:ref].nil?
            @env.ui.warn "You must specify an image and a git ref"
            exit
          end

          if options[:source].nil?
            @env.ui.warn "You must specify git repo source url"
            exit
          end

          options[:source] = "https://github.com/#{options[:source]}"

          with_target_vms(argv, :reverse => true) do |machine|
            image = options[:image]
            ref = options[:ref]
            source = options[:source]
            base_images = options[:base_images]
            registry = options[:registry]

            # image could be centos or openshift/ruby-20-centos7
            # just grab the end (centos or ruby-20-centos7)
            source_dir = File.basename(source)
            app_name = "test-#{source_dir}"
            rc=1
            begin
              out, err, rc = do_execute(machine, %{
set -x

# NOTE: This is only for rhel7
if [ -n "#{registry}" -a -f /etc/sysconfig/docker ]; then
  cat <<EOF > /etc/sysconfig/docker
OPTIONS='--insecure-registry #{registry} --selinux-enabled'
EOF
  systemctl restart docker
fi

# so we can call sti
PATH=/data/src/github.com/openshift/source-to-image/_output/go/bin:/data/src/github.com/openshift/source-to-image/_output/local/go/bin:$PATH

# create a temp dir to play in
temp_dir=$(mktemp -d /tmp/image_test.XXXXXXX)

# set correct SELinux context
chcon -t docker_share_t $temp_dir

cd $temp_dir

# clone the image repo
git clone #{source}
cd #{source_dir}

# Fetch refs from Github pull requests
git fetch --quiet --tags --progress #{source} +refs/pull/*:refs/remotes/origin/pr/*

# switch to the desired ref
git checkout #{ref}

if [ "#{base_images}" == "true" -a -n "#{registry}" ]; then
  # Pull base images
  docker pull #{registry}/openshift/base-centos7 && docker tag #{registry}/openshift/base-centos7 openshift/base-centos7
  docker pull #{registry}/openshift/base-rhel7 && docker tag #{registry}/openshift/base-rhel7 openshift/base-rhel7
fi

if ! make test TARGET=rhel7; then
    echo "ERROR: #{image}-rhel7 failed testing."
    exit 1
fi
  
if ! make test TARGET=centos7; then
    echo "ERROR: #{image}-centos7 failed testing."
    exit 1
fi

# clean up
cd /
rm -rf $temp_dir
exit $status
})
            # Vagrant throws an exception if any execute invocation returns non-zero,
            # so catch it so we can return a proper output.
            rescue => e
              @env.ui.info "Exception: #{e}"
            end
            @env.ui.info "RC=#{rc}"
            return rc
          end
        end
      end
    end
  end
end
