#--
# Copyright 2013-2015 Red Hat, Inc.
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
require_relative '../aws'

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
          instance_type   = @options[:instance_type]
          volume_size   = @options[:volume_size]
          inst_ts = Time.now.getutc.strftime('%Y%m%d_%H%M')

          box_info_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml"))

          box_info_data = YAML.load(File.new(box_info_path))
          box_info = box_info_data[os][stage]
          box_info[:instance_name] = @options[:name].nil? ? 'openshift_origin_' + inst_ts : @options[:name]
          box_info[:os] = os
          box_info[:vagrant_guest] = [:centos7, :rhel7, :rhel7next, :rhelatomic7].include?(os) ? :redhat : os
          box_info[:port_mappings] = @options[:port_mappings]

          @openstack_creds_file = ENV['OPENSTACK_CREDS'].nil? || ENV['OPENSTACK_CREDS'] == '' ? "~/.openstackcred" : ENV['OPENSTACK_CREDS']
          @openstack_creds_file = Pathname.new(File.expand_path(@openstack_creds_file))
          box_info[:openstack_creds_file] = @openstack_creds_file

          if !box_info[:aws].nil? && !box_info[:aws][:ami_tag_prefix].nil?
            begin
              aws_creds = Vagrant::Openshift::AWS::aws_creds()
              compute = Fog::Compute.new(Vagrant::Openshift::AWS::fog_config(aws_creds, box_info[:aws][:ami_region]))
              box_info[:aws][:ami] = Vagrant::Openshift::AWS::find_ami_from_tag(compute, box_info[:aws][:ami_tag_prefix], @options[:required_name_tag])
            rescue AWSCredentialsNotConfiguredError
            end
          end

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
            'insert_key' => (stage == :inst) && !@options[:no_insert_key],
            'instance_type' => instance_type,
            'volume_size' => volume_size
          }

          vagrant_openshift_config['no_synced_folders'] = @options[:no_synced_folders]
          unless  @options[:no_synced_folders]
            vagrant_openshift_config['sync_to']   = '/data/src'
            vagrant_openshift_config['sync_from'] = "#{gopath}/src"
          end

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
          vagrant_openshift_config['openstack'] = {
            'image' => box_info[:openstack][:image],
            'ssh_user' => box_info[:openstack][:ssh_user]
          } if box_info[:openstack]

          File.open(".vagrant-openshift.json","w") do |f|
            f.write(JSON.pretty_generate(vagrant_openshift_config))
          end

          @app.call(env)
        end
      end
    end
  end
end
