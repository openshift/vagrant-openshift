#--
# Copyright 2016 Red Hat, Inc.
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

require "pathname"
require "fog"

module Vagrant
  module Openshift
    class AWSCredentialsNotConfiguredError < RuntimeError
      def initialize(msg="AWS credentials not configured")
        super
      end
    end

    class AWS
      def self.aws_creds()
        aws_creds_file = ENV["AWS_CREDS"].nil? || ENV["AWS_CREDS"] == "" ? "~/.awscred" : ENV["AWS_CREDS"]
        aws_creds_file = Pathname.new(File.expand_path(aws_creds_file))

        raise AWSCredentialsNotConfiguredError if !aws_creds_file.exist?

        return Hash[*(aws_creds_file.open.readlines.map{|l| l.strip.split("=")}.flatten)]
      end

      def self.fog_config(aws_creds, region="us-east-1")
        {
          :provider              => :aws,
          :aws_access_key_id     => aws_creds["AWSAccessKeyId"],
          :aws_secret_access_key => aws_creds["AWSSecretKey"],
          :region                => region
        }
      end

      def self.find_ami_from_tag(compute, ami_tag_prefix, required_name_tag=nil)
        image_filter = {"Owner" => "self", "name" => "#{ami_tag_prefix}*", "state" => "available"}
        image_filter["tag:Name"] = required_name_tag unless required_name_tag.nil?
        images = compute.images.all(image_filter)
        latest_image = images.sort_by{|i| i.name.split("_")[-1].to_i}.last
        if !latest_image.nil?
          return latest_image.id
        end

        nil
      end
    end
  end
end
