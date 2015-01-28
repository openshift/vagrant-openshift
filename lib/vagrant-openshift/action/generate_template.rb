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
          os      = @options[:os].to_sym
          stage   = @options[:stage].to_sym
          inst_ts = Time.now.getutc.strftime('%Y%m%d_%H%M')

          box_info_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml"))

          box_info_data = YAML.load(File.new(box_info_path))
          box_info = box_info_data[os][stage]
          box_info[:instance_name] = @options[:name].nil? ? 'openshift_origin_' + inst_ts : @options[:name]
          box_info[:os] = os
          box_info[:vagrant_guest] = [:centos7, :rhel7].include?(os) ? :redhat : os
          box_info[:port_mappings] = @options[:port_mappings]

          @openstack_creds_file = ENV['OPENSTACK_CREDS'].nil? || ENV['OPENSTACK_CREDS'] == '' ? "~/.openstackcred" : ENV['OPENSTACK_CREDS']
          @openstack_creds_file = Pathname.new(File.expand_path(@openstack_creds_file))
          box_info[:openstack_creds_file] = @openstack_creds_file

          @aws_creds_file = ENV['AWS_CREDS'].nil? || ENV['AWS_CREDS'] == '' ? "~/.awscred" : ENV['AWS_CREDS']
          @aws_creds_file = Pathname.new(File.expand_path(@aws_creds_file))
          box_info[:aws_creds_file] = @aws_creds_file
          find_ami_from_tag(box_info)

          gopath = nil
          if ENV['GOPATH'] && !ENV['GOPATH'].empty?
            gopath = File.expand_path(ENV['GOPATH'].split(/:/).last)
          else
            gopath = '.'
          end

          vagrant_openshift_config = {
            'instance_name' => box_info[:instance_name],
            'os' => os,
            'dev_cluster' => false,
            'num_minions' => 2,
            'cpus' => 2,
            'memory' => 1024,
            'rebuild_yum_cache' => false,
            'sync_to' => '/data/src',
            'sync_from' => "#{gopath}/src"
          }
          vagrant_openshift_config['virtualbox'] = {
            'box_name' => box_info[:virtualbox][:box_name],
            'box_url' => box_info[:virtualbox][:box_url]
          } if box_info[:virtualbox]
          vagrant_openshift_config['vmware'] = {
            'box_name' => box_info[:vmware][:box_name],
            'box_url' => box_info[:vmware][:box_url]
          } if box_info[:vmware]
          vagrant_openshift_config['libvirt'] = {
            'box_name' => box_info[:libvirt][:box_name],
            'box_url' => box_info[:libvirt][:box_url]
          } if box_info[:libvirt]
          vagrant_openshift_config['aws'] = {
            'ami' => box_info[:aws][:ami],
            'ami_region' => box_info[:aws][:ami_region],
            'ssh_user' => box_info[:aws][:ssh_user]
          } if box_info[:aws]

          File.open(".vagrant-openshift.json","w") do |f|
            f.write(JSON.pretty_generate(vagrant_openshift_config))
          end

          @app.call(env)
        end

        private

        def find_ami_from_tag(box_info)
          return if box_info[:aws][:ami_tag_prefix].nil?
          @env[:ui].info("Reading AWS credentials from #{@aws_creds_file.to_s}")
          if @aws_creds_file.exist?
            aws_creds = @aws_creds_file.exist? ? Hash[*(File.open(@aws_creds_file.to_s).readlines.map{ |l| l.strip!
                                                          l.split('=') }.flatten)] : {}

            fog_config = {
                :provider              => :aws,
                :region                => box_info[:aws][:ami_region],
                :aws_access_key_id     => aws_creds['AWSAccessKeyId'],
                :aws_secret_access_key => aws_creds['AWSSecretKey'],
            }

            aws_compute = Fog::Compute.new(fog_config)
            @env[:ui].info("Searching for latest base AMI")
            images = aws_compute.images.all({'Owner' => 'self', 'name' => "#{box_info[:aws][:ami_tag_prefix]}*",
                                             'state' => 'available' })
            latest_image = images.sort_by{ |i| i.name.split("_")[-1].to_i }.last
            box_info[:aws][:ami] = latest_image.id
            @env[:ui].info("Found: #{latest_image.id} (#{latest_image.name})")
          end
        end
      end
    end
  end
end
