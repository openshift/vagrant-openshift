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
      attr_accessor :cloud_domain, :ignore_packages, :additional_services, :container,
                    :advanced_puppet_values

      def initialize
        @ignore_packages      = UNSET_VALUE
        @cloud_domain         = UNSET_VALUE
        @additional_services  = UNSET_VALUE
        @container            = UNSET_VALUE
        @advanced_puppet_values = UNSET_VALUE
      end

      def finalize!
        @ignore_packages = []             if @ignore_packages == UNSET_VALUE
        @cloud_domain    = "example.com"  if @cloud_domain    == UNSET_VALUE
        @additional_services = []         if @additional_services == UNSET_VALUE
        @container           = "selinux"  if @container == UNSET_VALUE
        @advanced_puppet_values = {}      if @advanced_puppet_values == UNSET_VALUE
      end
    end
  end
end

