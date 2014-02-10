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

require_relative 'constants'
require_relative 'options'
require 'tempfile'
require 'fileutils'
require 'pathname'
require 'yaml'

class RPM
  def self.get_packages(options={})
    spec_cache = Pathname.new(Vagrant::Openshift::Constants.build_dir + ".spec_cache")
    if spec_cache.exist? && !options[:ignore_cache]
      return YAML.load(File.open(spec_cache.to_s))
    end

    parent_dir = Pathname.new(File.expand_path("__FILE__/../../"))

    #find all spec files
    spec_files = []
    Vagrant::Openshift::Constants.repos.each do |name, url|
      repo_dir = parent_dir + name
      spec_files += Dir.glob((repo_dir + "**/*.spec").to_s).map{ |p| {path: p}}
    end

    #exclude ones that have not been tagged
    source_package_names = []
    spec_files.delete_if do |spec|
      spec[:name] = `rpm -q --specfile --queryformat '%{NAME}\n' #{spec[:path]}`.split("\n")[0]
      spec[:version] = `rpm -q --specfile --queryformat '%{VERSION}\n' #{spec[:path]}`.split("\n")[0]
      source_package_names << spec[:name]
      spec[:dir] = Pathname.new(spec[:path]).dirname
      is_tagged = Dir.chdir(spec[:dir]) { system "git tag | grep '#{spec[:name]}' 2>&1 1>/dev/null" }
      is_spec_bad = false
      if is_tagged
        begin
          spec[:build_deps] = YAML.load(`./yum-listbuilddep #{spec[:path]}`.split("\n").last)
          raise "Bad spec" if spec[:build_deps].class == Hash
          spec[:deps] = `rpm -q --specfile --requires #{spec[:path]}`.split("\n")
        rescue Exception => e
          next true
        end
      else
        puts "\n\nSkipping '#{spec[:name]}' in '#{spec[:dir]}' since it is not tagged.\n"
        next true
      end

      options.has_key?(:ignore_packages) && options[:ignore_packages].include?(spec[:name])
    end

    if(options.has_key?(:remove_os_build_deps) && options[:remove_os_build_deps])
      #remove deps provided by OS and keep only the ones that will be built from source
      spec_files.each do |spec|
        spec[:build_deps].delete_if{ |dep| not source_package_names.include? dep }
      end
    end

    File.open(spec_cache.to_s, "w") do |file|
      file.write(spec_files.to_yaml)
    end

    spec_files
  end

  def self.install_rpms(list)
    print "Installing #{list.size} in chunks of 20 packages"
    list.uniq.each_slice(20) do |sub_list|
      system %{yum install -y --skip-broken "#{sub_list.join('" "')}"}
    end
  end

  def self.uninstall_openshift
    #undo pam.d sshd modification
    if system("grep -n 'pam_openshift' /etc/pam.d/sshd")
      file = Tempfile.new('temp')
      begin
        file.write(%{
set /files/etc/pam.d/sshd/#comment[.='pam_openshift.so close should be the first session rule'] 'pam_selinux.so close should be the first session rule'
ins 01 before /files/etc/pam.d/sshd/*[argument='close']
set /files/etc/pam.d/sshd/01/type session
set /files/etc/pam.d/sshd/01/control required
set /files/etc/pam.d/sshd/01/module pam_selinux.so
set /files/etc/pam.d/sshd/01/argument close

set /files/etc/pam.d/sshd/#comment[.='pam_openshift.so open should only be followed by sessions to be executed in the user context'] 'pam_selinux.so open should only be followed by sessions to be executed in the user context'
ins 02 before /files/etc/pam.d/sshd/*[argument='open']
set /files/etc/pam.d/sshd/02/type session
set /files/etc/pam.d/sshd/02/control required
set /files/etc/pam.d/sshd/02/module pam_selinux.so
set /files/etc/pam.d/sshd/02/argument[1] open
set /files/etc/pam.d/sshd/02/argument[2] env_params

rm /files/etc/pam.d/sshd/*[module='pam_openshift.so']
rm /files/etc/pam.d/sshd/*[module='pam_namespace.so']
rm /files/etc/pam.d/sshd/*[module='pam_cgroup.so']
rm /files/etc/pam.d/sshd/*[module='pam_succeed_if.so']
save
      })
        file.close
        system("augtool --file #{file.path}")
      ensure
        file.unlink
      end
    end
    FileUtils.rm_rf("/etc/openshift")

    get_packages(ignore_cache: true).each_slice(10) do |spec_files_list|
      sub_list = spec_files_list.map {|s| s[:name] }
      system %{yum erase -y "#{sub_list.join('" "')}"}
    end
  end

  def self.build_packages(spec_files, opts={})
    built_specs = []

    FileUtils.mkdir_p "/tmp/tito/noarch/"
    FileUtils.mkdir_p (Vagrant::Openshift::Constants.build_dir + "origin-rpms").to_s
    FileUtils.mkdir_p (Vagrant::Openshift::Constants.build_dir + "origin-srpms").to_s
    (1..3).each do |phase|
      print "Build phase #{phase}\n"
      buildable = []

      #install pre reqs if thet have already been built
      spec_files.each do |spec|
        spec[:build_deps].delete_if do |dep|
          if opts[:assume_deps_built] || built_specs.map{ |s| s[:name] }.include?(dep)
            puts "\n    Installing...#{dep}"
            raise "Unable to install package #{package.name}" unless system("rpm -Uvh --force /tmp/tito/noarch/#{dep}*.rpm")
            true
          else
            false
          end
        end
      end

      buildable = spec_files.select{ |spec| spec[:build_deps].size == 0 }

      buildable.each do |spec|
        Dir.chdir(spec[:dir]) do
          puts "\n#{'-'*60}"
          system "rm -f /tmp/tito/noarch/#{spec[:name]}*.rpm"
          system "rm -f /tmp/tito/#{spec[:name]}*.src.rpm"

          raise "Unable to build #{spec[:name]}" unless system("tito build --rpm --test")

          Dir.glob('/tmp/tito/x86_64/*.rpm').each {|file|
            FileUtils.mv file, "/tmp/tito/noarch/"
          }
          Dir.glob("/tmp/tito/noarch/#{spec[:name]}*.rpm").each do |file|
            FileUtils.rm_f (Vagrant::Openshift::Constants.build_dir + "origin-rpms/" + "#{spec[:name]}*.rpm").to_s
            FileUtils.cp file, (Vagrant::Openshift::Constants.build_dir + "origin-rpms/").to_s
          end
          Dir.glob('/tmp/tito/*.src.rpm').each {|file|
            FileUtils.rm_f (Vagrant::Openshift::Constants.build_dir + "origin-srpms/" + "#{spec[:name]}*.src.rpm").to_s
            FileUtils.mv file, (Vagrant::Openshift::Constants.build_dir + "origin-srpms/").to_s
          }

          built_specs << spec
          spec_files.delete(spec)
        end
      end
    end

    File.open((Vagrant::Openshift::Constants.build_dir + ".built_packages").to_s, "w") do |file|
      file.write(tito_report.to_yaml)
    end

    print "Updating local repo for built sources"
    Dir.chdir((Vagrant::Openshift::Constants.build_dir + "origin-rpms/").to_s) do
      system("createrepo .")
      system("yum clean all")
    end

    built_specs
  end

  def self.updated_packages
    spec_files = get_updated_packages
    built_packages = build_packages(spec_files, {assume_deps_built: true})
    built_packages.each do |spec|
      unless system("rpm -Uvh --force #{Vagrant::Openshift::Constants.build_dir + "origin-rpms"}/#{spec[:name]}*.rpm")
        unless system("rpm -e --justdb --nodeps #{spec[:name]}; yum install -y #{Vagrant::Openshift::Constants.build_dir + "origin-rpms"}/#{spec[:name]}*.rpm")
          print "Unable to install updated package #{spec[:name]}"
          exit 1
        end
      end
    end
  end

  private

  def self.get_updated_packages
    raise "Please perform full build with 'rake openshift:build_all' before running sync" unless (Vagrant::Openshift::Constants.build_dir + ".built_packages").exist?

    spec_files = get_packages(remove_os_build_deps: true)
    cur_report = tito_report
    old_report = YAML.load(File.new((Vagrant::Openshift::Constants.build_dir + ".built_packages").to_s))

    updated_packages = []
    spec_files.each do |spec|
      cur_package_report = cur_report[spec[:name]]
      old_package_report = old_report[spec[:name]]

      if (old_package_report.nil? && !cur_package_report.nil?) ||
          (!cur_package_report.nil? && cur_package_report[:version] != old_package_report[:version]) ||
          (!cur_package_report.nil? && cur_package_report[:untagged_revisions] != old_package_report[:untagged_revisions])
        updated_packages << spec unless OPTIONS[:ignore_packages].include?(spec[:name])
      end
    end

    updated_packages
  end

  def self.tito_report
    packages = {}
    Vagrant::Openshift::Constants.repos.each do |name, url|
      Dir.chdir((Vagrant::Openshift::Constants.build_dir + name).to_s) do
        tito_report = `tito report --untagged-commits`
        tito_report = tito_report.split(/[-]+{10,100}[\n]/)
        tito_report.shift

        tito_report.each do |package_report|
          package_report = package_report.split("\n")
          m = package_report.shift.match(/([a-z0-9\-]+)-([\d\.\-]+)..HEAD/)
          packages[m[1]] = {
              version: m[2],
              untagged_revisions: package_report.map{ |line| line.split(" ")[0] }
          }
        end
      end
    end
    packages
  end
end
