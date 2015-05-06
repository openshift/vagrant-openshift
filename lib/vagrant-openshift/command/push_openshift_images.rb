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

      class PushOpenshiftImages < Vagrant.plugin(2, :command)
        include CommandHelper

        def self.synopsis
          "build and push openshift images"
        end

        def execute
          options = {}
          options[:registry] = nil

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant push-openshift-images --registry DOCKER_REGISTRY [vm-name]"
            o.on("--registry [url]", String, "Docker Registry to push images to.") do |c|
              options[:registry] = c
            end
            o.on("--build_images [list]", String, "List of IMAGE:REF pairs, delimited by ','") do |i|
              options[:build_images] = i
            end
            o.separator ""
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if options[:registry].nil?
            @env.ui.warn "You must specify target Docker registry"
            exit
          end

          if options[:build_images].nil?
            @env.ui.warn "You must specify list of images to build"
            exit
          end

          with_target_vms(argv, :reverse => true) do |machine|
            actions = Vagrant::Openshift::Action.push_openshift_images(options)
            @env.action_runner.run actions, {:machine => machine}
            0
          end
        end
      end
    end
  end
end
