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
require 'yaml'
require 'fog'

module Vagrant
  module Openshift
    module Action
      class GenerateTemplate
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          os = @options[:os].to_sym
          stage = @options[:stage].to_sym

          template_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/Vagrantfile.erb"))
          box_info_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml"))

          box_info_data = YAML.load(File.new(box_info_path))
          box_info = box_info_data[os][stage]

          if not @options[:name].nil?
            box_info[:virtualbox][:box_name] = @options[:name]
            box_info[:aws][:machine_name] = @options[:name]
          end
          box_info[:os] = os
          box_info[:vagrant_guest] = (os == :centos) ? :redhat : os

          @aws_creds_file = ENV['AWS_CREDS'].nil? || ENV['AWS_CREDS'] == '' ? "~/.awscred" : ENV['AWS_CREDS']
          @aws_creds_file = Pathname.new(File.expand_path(@aws_creds_file))
          box_info[:aws_creds_file] = @aws_creds_file
          find_ami_from_tag(box_info)

          contents = Vagrant::Util::TemplateRenderer.render(template_path.to_s[0..-5], box_info: box_info)
          File.open("Vagrantfile", "w+") do |f|
            f.write(contents)
          end

          @app.call(env)
        end

        private

        def find_ami_from_tag(box_info)
          return if box_info[:aws][:ami_tag_prefix].nil?
          @env[:ui].info("Reading AWS credentials from #{@aws_creds_file.to_s}")
          if @aws_creds_file.exist?
            aws_creds = @aws_creds_file.exist? ? Hash[*(File.open(@aws_creds_file.to_s).readlines.map{ |l| l.split('=') }.flatten.map{ |i| i.strip })] : {}

            fog_config = {
                :provider              => :aws,
                :region                => box_info[:aws][:ami_region],
                :aws_access_key_id     => aws_creds['AWSAccessKeyId'],
                :aws_secret_access_key => aws_creds['AWSSecretKey'],
            }

            aws_compute = Fog::Compute.new(fog_config)
            @env[:ui].info("Searching for latest base AMI")
            images = aws_compute.images.all({'Owner' => 'self', 'name' => "#{box_info[:aws][:ami_tag_prefix]}*" })
            latest_image = images.sort_by{ |i| i.name.split("_")[-1].to_i }.last
            box_info[:aws][:ami] = latest_image.id
            @env[:ui].info("Found: #{latest_image.id} (#{latest_image.name})")
          end
        end
      end
    end
  end
end
