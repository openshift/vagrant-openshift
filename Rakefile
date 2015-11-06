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

require 'rubygems'
require 'bundler/setup'
require 'pry'
$stdout.sync = true
$stderr.sync = true

namespace :vagrant do

  desc "Install plugin into Vagrant"
  task :install do

    syntax_check_cmd = %{
set -e
for f in `find lib -name *.rb`
do
  ruby -c $f >/dev/null;
done
}
    `#{syntax_check_cmd}`
    if $?.exitstatus != 0
      exit 1
    end

    # We want to install our plugin on the system vagrant. Pull gem paths out of
    # $PATH so that we get the correct vagrant binary.
    dirty_path = `echo $PATH`
    clean_path = dirty_path.split(':').select{ |p| not p.include?('gem') }.join(':')
    sys_cmd = `PATH=#{clean_path} which vagrant`.chomp
    if $?.exitstatus != 0
      sys_cmd = `which vagrant`.chomp
      if not $?.exitstatus == 0
        $stderr.puts "ERROR: Could not find a Vagrant binary in your PATH.\nEnsure that Vagrant has been installed on this system."
        exit 1
      else
        $stderr.puts "WARNING: Could not find a Vagrant binary outside of your gem environments.\nEnsure that the Vagrant package has been installed from the official Vagrant packages and not a gem."
      end
    end

    system("rm -rf pkg")

    Rake::Task['build'].invoke
    name = Bundler::GemHelper.instance.send(:name)
    version = Bundler::GemHelper.instance.send(:version).to_s

    install_cmd = %{
#{sys_cmd} plugin install pkg/#{name}-#{version}.gem
}
    system(install_cmd)
  end
end

Bundler::GemHelper.install_tasks
task :default => "vagrant:install"
