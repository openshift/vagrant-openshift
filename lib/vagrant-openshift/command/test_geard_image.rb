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

      class TestGeardImage < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "tests an image"
        end

        def execute
          options = {}
          options[:image] = nil
          options[:ref] = 'master'
          options[:source] = nil

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant test-geard-image --image IMAGE [vm-name]"
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

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)

          if options[:image].nil? and options[:ref].nil?
            @env.ui.warn "You must specify an image and a git ref"
            exit
          end

          if options[:source].nil?
            options[:source] = "https://github.com/#{options[:image]}"
          end

          with_target_vms(argv, :reverse => true) do |machine|
            if options[:help]
              machine.env.ui.info opts
              exit
            end

            image = options[:image]
            ref = options[:ref]
            source = options[:source]

            # image could be centos or openshift/ruby-19-centos
            # just grab the end (centos or ruby-19-centos)
            source_dir = File.basename(image)
            app_name = "test-#{source_dir}"
            rc=1
            begin
              out, err, rc = do_execute(machine, %{
set -x

# so we can call sti
PATH=/data/bin:$PATH

# create a temp dir to play in
temp_dir=$(mktemp -d /tmp/image_test.XXXXXXX)
cd $temp_dir

# clone the image repo
git clone #{source}
cd #{source_dir}

# switch to the desired ref
git checkout #{ref}

# get git sha1
git_sha1=`git rev-parse --short #{ref}`

# grab the latest image from the index
docker pull #{image}:latest

status=0

# build and test the sample app, if it exists
if [ -d test-app -a -f .sti/bin/test ]; then
  # build
  sti build test-app #{image} #{app_name} --clean
  status=$?

  if [ $status -eq 0 ]; then
    # run tests
    docker run --rm -v $temp_dir/#{source_dir}/.sti/bin:/tmp/sti #{app_name} /tmp/sti/test

    status=$?
  fi
fi

if [ $status -eq 0 ]; then
  # get the image id
  image_id=`docker inspect #{image}:latest | grep id | sed -r 's/^\s*"id": "\([^"]\+\)".*/\\1/'`

  # tag it devenv-ready
  docker tag $image_id #{image}:devenv-ready

  # tag it with the git ref
  docker tag $image_id #{image}:git-$git_sha1
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
