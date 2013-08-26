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

module Vagrant
  module Openshift
    module Commands
      class OpenshiftInit < Vagrant.plugin(2, :command)
        include CommandHelper

        def execute
          options = {}
          options[:no_base] = false
          options[:help] = false
          options[:provider] = "virtualbox"
          options[:os] = "fedora"

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant origin-init [machine-name]"
            o.separator ""

            o.on("-n", "--no-base", "Start from a scratch (clean operating system image) rather than a prebuilt base box") do |f|
              options[:no_base] = true
            end

            o.on("-o", "--os [name]", String, "Operating system: fedora (default)") do |f|
              options[:os] = f
            end

            o.on("-h", "--help", "Show this message") do |f|
              options[:help] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)

          if options[:help]
            @env.ui.info opts
            exit
          end

          template_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/Vagrantfile.erb"))
          box_info_path = Pathname.new(File.expand_path("#{__FILE__}/../../templates/command/init-openshift/box_info.yaml"))

          box_info_data = YAML.load(File.new(box_info_path))
          box_info = box_info_data[options[:os].to_sym][(options[:no_base] ? :os : :base)]

          box_info[:aws][:machine_name] = argv[0] unless argv[0].nil?
          aws_creds = Pathname.new(File.expand_path("~/.awscred"))
          box_info[:aws][:aws_access_key_id]     = "AWS ACCESS KEY"
          box_info[:aws][:aws_secret_access_key] = "AWS SECRET KEY"
          box_info[:aws][:aws_keypair_name]      = "AWS KEYPAIR NAME"
          box_info[:aws][:aws_private_key_path]  = "PATH TO AWS KEYPAIR PRIVATE KEY"

          if aws_creds.exist?
            @env.ui.info "Reading aws credentials from #{aws_creds}"
            File.open(aws_creds.to_s) do |file|
              file.readlines.each do |line|
                line = line.strip.split("=")
                case line[0]
                  when "AWSAccessKeyId"
                    box_info[:aws][:aws_access_key_id] = line[1]
                  when "AWSSecretKey"
                      box_info[:aws][:aws_secret_access_key] = line[1]
                  when "AWSKeyPairName"
                      box_info[:aws][:aws_keypair_name] = line[1]
                  when "AWSPrivateKeyPath"
                      box_info[:aws][:aws_private_key_path] = line[1]
                end
              end
            end
          end
          box_info[:os] = options[:os].to_sym

          contents = Vagrant::Util::TemplateRenderer.render(template_path.to_s[0..-5], box_info: box_info)
          File.open("Vagrantfile", "w+") do |f|
            f.write(contents)
          end
          0
        end
      end
    end
  end
end
