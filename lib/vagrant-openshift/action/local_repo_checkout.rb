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
    module Action
      class LocalRepoCheckout
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          Constants.repos.each do |repo, url|
            repo_path = File.expand_path(repo)
            if Pathname.new(repo_path).exist?
              if @options[:replace]
                puts "Replacing: #{repo_path}"
                system("rm -rf #{repo_path}")
              else
                puts "Already cloned: #{repo}"
                next
              end
            end
            cloned = false
            if @options[:user]
              if system("git clone git@github.com:#{@options[:user]}/#{repo}")
                cloned = true
                Dir.chdir(repo) do
                  system("git remote add upstream #{url} && git fetch upstream")
                end
              else
                @env.ui.warn "Fork of repo #{repo} not found. Cloning read-only copy from upstream"
              end
            end
            if not cloned
              system("git clone #{url}")
            end
            Dir.chdir(repo) do
              system("git checkout #{@options[:branch]}")
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
