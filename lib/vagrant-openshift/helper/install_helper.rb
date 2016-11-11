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

module Vagrant
  module Openshift
    module InstallHelper
      include CommandHelper

      # install_from_url installs an RPM repository from the given URL
      # SSL client certs and keys are installed and provided, but won't
      # be used unless they are necessary, so repositories that do not
      # use them can still function correctly with one .repo defenition
      def install_from_url(url)
        reponame = url.gsub(/[^a-zA-Z0-9]/,'')

        remote_write(@env[:machine], "/etc/yum.repos.d/#{reponame}.repo") {%{
[#{reponame}]
name=#{reponame}
baseurl=#{url}
enabled=1
gpgcheck=0
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
}}

        return reponame
      end

      # assemble_reponames assembles a list of repository names for use
      # with `yum install`, or provides `*` if no repository names are
      # provided
      def assemble_reponames(fresh_install, pre_existing)
        reponames = []

        # If the user didn't specify any names or install any custom
        # repositories, default to use all of the normally available
        # repositories on the system.
        if fresh_install.empty?() && pre_existing.empty?()
          reponames << '"*"'
        else
          reponames = fresh_install + pre_existing
        end

        return "--enablerepo=#{reponames.join(" --enablerepo=")}"
      end

      # format_versioned_package formats a pacakge name with a version
      # to allow for better UX on the command line. For instance, a
      # package `docker` should be called `docker` without a version but
      # `docker-1.11.3` with one, but the user only wants to provide the
      # `1.11.3` version, not the dash as well, so a simple concat is not
      # possible
      def format_versioned_package(name, version)
        if version
          "#{name}-#{version}"
        else
          name
        end
      end

      # uninstall_safely tries to uninstall the given package, but it
      # will fail if it fails to confirm that only the single package
      # given will be the removed
      def uninstall_safely(machine, package, force)
        stdout, stderr, _ = sudo(machine, "yum remove --assumeno -q #{package}", :timeout=>60, fail_on_error: false)

        # we want to match output like:
        # Remove  1 Package
        # Remove  20 Packages
        # Remove  1 Package (+1 Dependent package)
        # Remove  20 Packages (+20 Dependent packages)
        amount_pattern = /Remove\s+([0-9]+)\s+Packages?(\s+\(\+([0-9]+)\s+Dependent\s+packages?\))?/
        match = amount_pattern.match((stdout+stderr).join(""))

        unless match
          raise "Package removal statistics not found in `yum` output."
        end

        # if we can tell there's more than one package being removed, or if
        # there's any dependent packages being removed, we need to fail the
        # uninstall process unless the force flag has been set
        if (match.captures[0].to_i > 1 || match.captures[2]) && !force
          raise "Removing #{package} would also remove other packages, this is disabled by default for safety."
        end

        sudo(machine, "yum autoremove -y #{package}", :timeout=>60)
      end

      # isolated_install runs a full isolated installation of a package,
      # trying to remove previous versions if possible, setting up and
      # tearing down extra repositories, etc.
      def isolated_install(machine, package, version, repourls, reponames, force)
        # if the package is already installed and we can cleanly uninstall it, we should
        if machine.communicate.test("yum list installed #{package}")
          begin
            uninstall_safely(machine, package, force)
          rescue Exception => e
            $stderr.puts "Could not complete #{package} installation process, a previous #{package} install exists and removing it would not be clean:"
            $stderr.puts e.message
            $stderr.puts "If you want to continue anyway, try running the vagrant command again with `--force`"
            exit 1
          end
        end

        # Install user-specified repositories
        extra_repositories = []
        repourls.each do |url|
          extra_repositories << install_from_url(url)
        end

        # Install the package
        yum_config=%{-y --disablerepo="*"}
        yum_config+=%{ #{assemble_reponames(extra_repositories, reponames)}}
        yum_config+=%{ #{format_versioned_package(package, version)}}
        sudo(machine, "yum install #{yum_config}", :timeout=>60*30)

        # Disable all repositories that were installed for the express purpose of giving us the package
        extra_repositories.each do |repo|
          sudo(machine, "yum-config-manager --disable #{repo}", :timeout=>60*30)
        end
      end

    end
  end
end