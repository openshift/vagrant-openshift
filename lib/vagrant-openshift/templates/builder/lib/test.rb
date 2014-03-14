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
require 'open3'
require 'securerandom'

class Test
  @@SSH_TIMEOUT = 4800

  def test(options)
    @is_fedora = system("test -e /etc/fedora-release")
    reset_test_dir(false)

    test_queues = [[], [], [], []]

    if options[:broker_extended]
      (1..4).each do |i|
        test_queues[i-1] << build_cucumber_command("REST API Group #{i}", ["@broker_api#{i}"])
      end
      (1..4).each do |i|
        test_queues[i-1] << build_rake_command("OpenShift Broker Functionals Ext #{i}", "cd /data/openshift-test/broker; rake test:functionals_ext#{i}")
      end
      test_queues[0] << build_rake_command("OpenShift Broker OO Admin Scripts", "cd /data/openshift-test/broker; rake test:oo_admin_scripts")
    end

    if options[:node_extended]
      (1..3).each do |i|
        test_queues[i-1] << build_cucumber_command("Extended Node Group #{i}", ["@node_extended#{i}"])
      end
    end

    if options[:cart_extended]
      (1..3).each do |i|
        test_queues[i-1] << build_cucumber_command("Extended Cart Group #{i}", ["@cart_extended#{i}"])
      end
    end

    if options[:gear_extended]
      (1..3).each do |i|
        test_queues[i-1] << build_cucumber_command("Extended Gear Group #{i}", ["@gear_extended#{i}"])
      end
      (1..3).each do |i|
        test_queues[i-1] << build_rake_command("OpenShift Gear Functionals Ext #{i}", "cd /data/openshift-test/node; rake ext_gear_func_test#{i}")
      end
    end

    if options[:rhc_extended]
      test_queues[0] << build_cucumber_command("RHC Extended", ["@rhc_extended"])
      test_queues[1] << build_cucumber_command("RHC Integration",[],
                                               {"RHC_SERVER" => "broker.example.com", "RHC_DOMAIN" => "example.com"},
                                               nil,"/data/openshift-test/rhc/cucumber")
    end

    if options[:broker]
      test_queues[3] << build_rake_command("OpenShift Broker Units", "cd /data/openshift-test/broker; rake test:units", {}, false)
      test_queues[0] << build_rake_command("OpenShift Broker Integration", "cd /data/openshift-test/broker; rake test:integration", {}, false)
      (1..3).each do |i|
        test_queues[i-1] << build_rake_command("OpenShift Broker Functional #{i}", "cd /data/openshift-test/broker; rake test:functionals#{i}", {}, false)
      end
      #test_queues[1] << build_rake_command("OpenShift Admin Console Functional", "cd /data/openshift-test/broker; rake test:admin_console_functionals", {}, false)
      test_queues[3] << build_cucumber_command("Broker cucumber", ["@broker"])
    end

    if options[:node]
      test_queues[0] << build_rake_command("Node Essentials", "cd /data/openshift-test/node; rake essentials_test | tail -100; exit ${PIPESTATUS[0]}", {}, false)
      (1..3).each do |i|
        test_queues[i] << build_cucumber_command("Node Group #{i.to_s}", ["@node#{i.to_s}"])
      end
    end

    if options[:cart]
      (1..3).each do |i|
        test_queues[i] << build_cucumber_command("Cartridge Group #{i.to_s}", ["@cartridge#{i.to_s}"])
      end
    end

    if options[:rhc]
      if @is_fedora
        test_queues[0] << build_rake_command("RHC Spec", 'cd /data/openshift-test/rhc; bundle install --local && bundle exec rake spec', {"SKIP_RUNCON" => 1}, false)
      else
        test_queues[0] << build_rake_command("RHC Spec", 'cd /data/openshift-test/rhc; bundle install --path=/tmp/rhc_bundle && bundle exec rake spec', {}, false)
      end
    end

    run_tests_with_retry(test_queues)

    #These are special tests that cannot be written to work concurrently
    singleton_queue = []
    idle_all_gears

    if options[:node]
      singleton_queue << build_cucumber_command("Node singletons", ["@node_singleton"])
    end

    if options[:gear]
      singleton_queue << build_cucumber_command("Gear singletons", ["@gear_singleton"])
    end

    run_tests_with_retry([singleton_queue])
  end

  def run_tests_with_retry(test_queues)
    test_run_success = false
    (1..3).each do |retry_cnt|
      print "Test run ##{retry_cnt}\n\n\n"
      failure_queue = run_tests(test_queues)
      if failure_queue.empty?
        test_run_success = true
        break
      else
        reset_test_dir(true)
      end
      test_queues = [failure_queue]
    end
    exit 1 unless test_run_success
  end

  def run_tests(test_queues)
    threads = []
    failures = []

    test_queues.each do |tqueue|
      threads << Thread.new do
        test_queue = tqueue
        start_time = Time.new
        test_queue.each do |test|
          stdout_data = ""
          stderr_data = ""
          rc = -1

          Open3.popen3(test[:command]) do |stdin, stdout, stderr, wait_thr|
            pid = wait_thr.pid # pid of the started process.
            stdin.close

            stdout_data = stdout.read.chomp
            stderr_data = stderr.read.chomp

            stdout.close
            stderr.close
            rc = wait_thr.value # Process::Status object returned.
          end

          print %{
#######################################################################################################################
Test: #{test[:title]}
#######################################################################################################################

#{test[:command]}

#{stdout_data}
#{stderr_data}

#######################################################################################################################\n}

          test[:output]  = stdout_data + "\n" + stdout_data
          test[:exit_code]  = rc
          test[:success] = rc == 0
          test[:completed] = true

          still_running_tests = test_queues.map do |q|
            q.select{ |t| t[:completed] != true }
          end

          if still_running_tests.length > 0
            mins, secs = (Time.new - start_time).abs.divmod(60)
            print "\nStill Running Tests (#{mins}m #{secs.to_i}s):\n"
            still_running_tests.each_index do |q_idx|
              print "\t Queue #{q_idx}:\n"
              print still_running_tests[q_idx].map{ |t| "\t\t#{t[:title]}" }.join("\n"), "\n"
            end
            print "\n\n\n"
          end
        end
      end
    end

    threads.each { |t| t.join }

    failures = test_queues.map{ |q| q.select{ |t| t[:success] == false }}
    failures.flatten!
    retry_queue = []
    if failures.length > 0
      idle_all_gears
      print "Failures\n"
      print failures.map{ |f| f[:title] }.join("\n")
      print "\n\n\n"

      #process failures
      failures.each do |failed_test|
        if failed_test[:options].has_key?(:cucumber_rerun_file)
          retry_queue << build_cucumber_command(failed_test[:title], [], failed_test[:options][:env],
                                                failed_test[:options][:cucumber_rerun_file],
                                                failed_test[:options][:test_dir],
                                                "*.feature",
                                                failed_test[:options][:require_gemfile_dir],
                                                failed_test[:options][:other_outputs])
        elsif failed_test[:output] =~ /cucumber openshift-test\/tests\/.*\.feature:\d+/
          output.lines.each do |line|
            if line =~ /cucumber openshift-test\/tests\/(.*\.feature):(\d+)/
              test = $1
              scenario = $2
              if failed_test[:options][:retry_indivigually]
                retry_queue << build_cucumber_command(failed_test[:title], [], failed_test[:options][:env],
                                                      failed_test[:options][:cucumber_rerun_file],
                                                      failed_test[:options][:test_dir],
                                                      "#{test}:#{scenario}")
              else
                retry_queue << build_cucumber_command(failed_test[:title], [], failed_test[:options][:env],
                                                      failed_test[:options][:cucumber_rerun_file],
                                                      failed_test[:options][:test_dir],
                                                      "#{test}")
              end
            end
          end
        elsif failed_test[:options][:retry_indivigually] && failed_test[:output].include?("Failure:") && failed_test[:output].include?("rake_test_loader")
          found_test = false
          failed_test[:output].lines.each do |line|
            if line =~ /\A(test_\w+)\((\w+Test)\) \[\/.*\/(test\/.*_test\.rb):(\d+)\]:/
              found_test = true
              test_name = $1
              class_name = $2
              file_name = $3

              # determine if the first part of the command is a directory change
              # if so, include that in the retry command
              chdir_command = ""
              if cmd =~ /\A(cd .+?; )/
                chdir_command = $1
              end
              retry_queue << build_rake_command("#{class_name} (#{test_name})", "#{chdir_command} ruby -Ilib:test #{file_name} -n #{test_name}", true)
            end
          end
          retry_queue << {
              :command  => failed_test[:command],
              :options  => failed_test[:options],
              :title    => failed_test[:title]
          }
        else
          retry_queue << {
              :command => failed_test[:command],
              :options => failed_test[:options],
              :title   => failed_test[:title]
          }
        end
      end
    end
    retry_queue
  end

  def build_cucumber_command(title="", tags=[], test_env = {}, old_rerun_file=nil, test_dir="/data/openshift-test/tests",
      feature_file="*.feature", require_gemfile_dir=nil, other_outputs = nil)

    other_outputs ||= {:junit => '/tmp/rhc/cucumber_results'}
    rerun_file = "/tmp/rerun_#{SecureRandom.hex}.txt"
    opts = []
    opts << "--strict"
    opts << "-f progress"
    opts << "-f rerun --out #{rerun_file} "
    other_outputs.each do |formatter, file|
      opts << "-f #{formatter} --out #{file}"
    end
    if @is_fedora
      tags += ["~@fedora-18-only", "~@rhel-only", "~@not-fedora-19", "~@jboss", "~@not-origin"]
    else
      tags += ["~@fedora-18-only", "~@fedora-19-only", "~@not-rhel", "~@jboss", "~@not-origin"]
    end
    opts += tags.map{ |t| "-t #{t}"}
    opts << "-r #{test_dir}"
    if old_rerun_file.nil?
      opts << "#{test_dir}/#{feature_file}"
    else
      opts << "@#{old_rerun_file}"
    end
    if not require_gemfile_dir.nil?
      {:command => wrap_test_command("cd #{require_gemfile_dir}; bundle install --path=gems; bundle exec \"cucumber #{opts.join(' ')}\"", test_env),
       :options =>
           {:cucumber_rerun_file => rerun_file,
            :timeout => @@SSH_TIMEOUT,
            :test_dir => test_dir,
            :env => test_env,
            :require_gemfile_dir => require_gemfile_dir,
            :other_outputs => other_outputs
           },
       :title => title
      }
    else
      {:command => wrap_test_command("cucumber #{opts.join(' ')}", test_env),
       :options => {
           :cucumber_rerun_file => rerun_file,
           :timeout => @@SSH_TIMEOUT,
           :test_dir => test_dir,
           :env => test_env,
           :other_outputs => other_outputs
       },
       :title => title}
    end
  end

  def build_rake_command(title="", cmd="", test_env = {}, retry_indivigually=true)
    {:command => wrap_test_command(cmd, test_env), :options => {:retry_indivigually => retry_indivigually, :timeout => @@SSH_TIMEOUT, :env => test_env}, :title => title}
  end

  def wrap_test_command(command, test_env={})
    env_str = ""
    unless test_env.nil?
      test_env.each do |k,v|
        env_str += "export #{k}=#{v}; "
      end
    end
    if @is_fedora
      if test_env["SKIP_RUNCON"]
        "export REGISTER_USER=1 ; #{env_str} #{command}"
      else
        %{runcon system_u:system_r:openshift_initrc_t:s0-s0:c0.c1023 bash -c \"export REGISTER_USER=1 ; #{env_str} #{command}"}
      end
    else
      %{/usr/bin/scl enable ruby193 "export LANG=en_US.UTF-8 ; export REGISTER_USER=1; #{env_str} #{command}"}
    end
  end

  def reset_test_dir(backup=false)
    File.open('/tmp/reset_test_dir.sh', "w") do |file|
      file.write(%{
if [ -d /tmp/rhc ]
then
    if #{backup}
    then
        if \$(ls /tmp/rhc/run_* > /dev/null 2>&1)
        then
            rm -rf /tmp/rhc_previous_runs
            mkdir -p /tmp/rhc_previous_runs
            mv /tmp/rhc/run_* /tmp/rhc_previous_runs
        fi
        if \$(ls /tmp/rhc/* > /dev/null 2>&1)
        then
            for i in {1..100}
            do
                if ! [ -d /tmp/rhc_previous_runs/run_$i ]
                then
                    mkdir -p /tmp/rhc_previous_runs/run_$i
                    mv /tmp/rhc/* /tmp/rhc_previous_runs/run_$i
                    break
                fi
            done
        fi
        if \$(ls /tmp/rhc_previous_runs/run_* > /dev/null 2>&1)
        then
            mv /tmp/rhc_previous_runs/run_* /tmp/rhc/
            rm -rf /tmp/rhc_previous_runs
        fi
    else
        rm -rf /tmp/rhc
    fi
fi
mkdir -p /tmp/rhc/junit
})
    end

    system 'chmod +x /tmp/reset_test_dir.sh'
    system '/tmp/reset_test_dir.sh'
    system 'rm -rf /var/www/openshift/broker/tmp/cache/*'
  end

  def idle_all_gears
    is_fedora = system("test -e /etc/fedora-release")

    print "Idling all gears on remote instance\n"

    if is_fedora
      system('/sbin/service mcollective stop; /sbin/service mcollective start')
    else
      system('/sbin/service ruby193-mcollective stop; /sbin/service ruby193-mcollective start')
    end

    system(%{
            for gear in `oo-admin-ctl-gears list`; do
              oo-admin-ctl-gears idlegear $gear;
            done;
          })

    if is_fedora
      system('/sbin/service httpd reload')
    else
      system('/sbin/service httpd graceful')
    end

    print "Done\n"
  end
end
