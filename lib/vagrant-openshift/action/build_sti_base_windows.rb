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

require "fog"
require_relative "../aws"

module Vagrant
  module Openshift
    module Action
      class BuildStiBaseWindows
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          aws_creds = Vagrant::Openshift::AWS::aws_creds()
          compute = Fog::Compute.new(Vagrant::Openshift::AWS::fog_config(aws_creds))

          @env[:ui].info("Finding base AMI...")
          images = compute.images.all({"Owner" => "amazon", "name" => "Windows_Server-2012-R2_RTM-English-64Bit-Base-*", "state" => "available"})
          # https://github.com/fog/fog-aws/issues/320 would make this less hacky
          images.sort_by! {|image| image.name[-10,10]}
          @env[:ui].info("Using base AMI #{images.last.name}, #{images.last.id}")

          @env[:ui].info("Creating instance...")
          instance = compute.servers.create(
            :tags => {"Name" => "#{@options[:instance_prefix]}-windows2012r2_#{Time.now.to_i}"},
            :image_id => images.last.id,
            :flavor_id => @options[:flavor_id],
            :key_name => aws_creds["AWSKeyPairName"],
            :subnet_id => @options[:subnet_id],
            :user_data => <<'USERDATA'
<powershell>
Set-ExecutionPolicy -ExecutionPolicy Bypass

# Download and install Cygwin
$client = New-Object System.Net.WebClient
$client.DownloadFile("https://cygwin.com/setup-x86_64.exe", "C:\Windows\Temp\setup-x86_64.exe")
&C:\Windows\Temp\setup-x86_64.exe -q -D -L -d -o -s http://mirrors.kernel.org/sourceware/cygwin -l C:\Windows\Temp\cygwin -R C:\cygwin -P curl -P gcc-core -P git -P make -P openssh -P rsync | Out-Null
Remove-Item -Recurse C:\Windows\Temp\cygwin
Remove-Item C:\Windows\Temp\setup-x86_64.exe
$env:Path += ";C:\cygwin\bin"

# Configure and start OpenSSH
$env:LOGONSERVER = "\\" + $env:COMPUTERNAME  # http://petemoore.github.io/general/taskcluster/2016/03/30/windows-sshd-cygwin-ec2-aws.html
&bash -c "ssh-host-config --yes -w Pa$$w0rd"
&bash -c "sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/sshd_config"
&bash -c "sed -i -e 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/sshd_config"
&cygrunsrv -S sshd
&netsh advfirewall firewall add rule name=SSH profile=any localport=22 enable=yes action=allow dir=in protocol=tcp

# Download and install Golang
$client.DownloadFile("https://storage.googleapis.com/golang/go1.7.1.windows-amd64.msi", "C:\Windows\Temp\go1.7.1.windows-amd64.msi")
&msiexec /qb /i C:\Windows\Temp\go1.7.1.windows-amd64.msi | Out-Null
Remove-Item C:\Windows\Temp\go1.7.1.windows-amd64.msi

# Create Administrator's home directory
Out-Null | &bash --login
&bash -c "mkdir /home/Administrator/.ssh; curl -o /home/Administrator/.ssh/authorized_keys http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key"
&bash -c "mkdir /data"
$stream = New-Object System.IO.StreamWriter @("c:\cygwin\home\Administrator\.bash_profile", $true)
$stream.Write("export GOPATH='C:\cygwin\data'`n")
$stream.Close()

# Download and install Docker client
$client.DownloadFile("https://get.docker.com/builds/Windows/x86_64/docker-1.10.3.exe", "C:\cygwin\usr\local\bin\docker.exe")

# Install a fake sudo
$stream = New-Object System.IO.StreamWriter "C:\cygwin\bin\sudo"
$stream.Write("#!/bin/bash`n`nwhile [[ `$# -ge 0 && `$1 = -* ]]; do`n  shift`ndone`n`n`"`$@`"`n")
$stream.Close()
$stream = New-Object System.IO.StreamWriter "C:\cygwin\etc\sudoers"
$stream.Close()

# Start sysprep (will power off instance when done)
&"C:\Program Files\Amazon\Ec2ConfigService\ec2config.exe" -sysprep
</powershell>
USERDATA
          )

          @env[:ui].info("Instance ID is #{instance.id}")

          @env[:ui].info("Waiting for instance state == running...")
          instance.wait_for { ready? }

          @env[:ui].info("Waiting for instance state == stopped...")
          instance.wait_for(3600) { state == "stopped" }

          @env[:ui].info("Creating AMI...")
          image_req = compute.create_image(instance.id, "#{@options[:ami_prefix]}-windows2012r2_#{Time.now.to_i}", "", false)

          @env[:ui].info("AMI ID is #{image_req.body['imageId']}")

          @env[:ui].info("Waiting for AMI state == available...")
          Fog.wait_for {
            image = compute.images.get(image_req.body["imageId"])
            !image.nil? && image.ready?
          }

          @env[:ui].info("Setting instance name to terminate...")
          compute.create_tags(instance.id, "Name" => "terminate")

          @env[:ui].info("Done")

          @app.call(env)
        end
      end
    end
  end
end
