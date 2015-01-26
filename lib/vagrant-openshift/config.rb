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

module Vagrant
  module Openshift
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :cloud_domain, :repos_base, :os_repo, :os_updates_repo,
                    :optional_repo, :os_extras_repo, :os_scl_repo

      def initialize
        super

        @cloud_domain         = UNSET_VALUE
        @repos_base           = UNSET_VALUE
        @os_repo              = nil
        @os_updates_repo      = nil
        @os_extras_repo       = nil
        @optional_repo        = nil
        @os_scl_repo          = nil
      end

      def finalize!
        super

        @cloud_domain    = "example.com"  if @cloud_domain    == UNSET_VALUE
        @repos_base = nil         if @repos_base == UNSET_VALUE
      end
    end
  end
end

