#--
# Copyright 2014 Red Hat, Inc.
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
      class SetupBindHost
        include CommandHelper

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          domain = env[:machine].config.openshift.cloud_domain
          sudo(env[:machine], %{
yum install -y bind bind-utils
NAMESERVERS=$(cat /etc/resolv.conf | grep -w nameserver | cut -d' ' -f 2 )
FORWARDERS=$(echo $NAMESERVERS | sed 's/ /; /g')
pushd /var/named
  rm -rf K*.*.*
  /usr/sbin/dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom -K /var/named #{domain}
  KEYSTRING=$(grep Key: K#{domain}.*.private | cut -d' ' -f 2)
  echo 'forwarders { '$FORWARDERS'; };' > forwarders.conf
  echo $'key #{domain} {\n algorithm HMAC-MD5;\n secret "'$KEYSTRING$'";\n};' > #{domain}.key
  cat <<EOF> #{domain}.zones
zone "#{domain}" IN {
  type master;
  file "dynamic/#{domain}.db";
  allow-update { key #{domain}; };
};
EOF
  touch dynamic/#{domain}.db
  cat <<EOF> dynamic/#{domain}.db
\\$ORIGIN .
\\$TTL 1  ; 1 seconds (for testing only)
#{domain} IN SOA  ns1.#{domain}. hostmaster.#{domain}. (
        2011112904 ; serial
        60         ; refresh (1 minute)
        15         ; retry (15 seconds)
        1800       ; expire (30 minutes)
        10         ; minimum (10 seconds)
        )
      NS  ns1.#{domain}.
      MX  10 mail.#{domain}.
\\$ORIGIN #{domain}.
mail      A 127.0.0.1
master      A 192.168.1.1
ns1     A 127.0.0.1
node                    A       192.168.1.10
; test records
testns1     TXT "reserved namespace testns1"
;testns2    TXT "to be added by tests"
testns3                 TXT     "reserved to add apps"
testns4                 TXT     "reserved to delete apps"
testapp4-testns4        CNAME   node.#{domain}.com.
EOF
popd
pushd /etc/
mv named.conf named.conf.old
cat <<EOF> named.conf
options {
  listen-on port 53 { 127.0.0.1; 172.17.42.1; };
  listen-on-v6 port 53 { ::1; };
  directory   "/var/named";
  dump-file   "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  allow-query     { any; };
  recursion yes;
  dnssec-enable yes;
  dnssec-validation no;
  dnssec-lookaside auto;
  bindkeys-file "/etc/named.iscdlv.key";
  managed-keys-directory "/var/named/dynamic";
  pid-file "/run/named/named.pid";
  session-keyfile "/run/named/session.key";
  forward only;
  include "forwarders.conf";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/var/named/#{domain}.zones";
include "#{domain}.key";
EOF
if ! cat /etc/dhcp/dhclient.conf | grep 'prepend domain-name-servers 172.17.42.1;' 2>&1 > /dev/null ; then
  echo "$(cat /etc/dhcp/dhclient.conf)\nprepend domain-name-servers 172.17.42.1;" > /etc/dhcp/dhclient.conf;
fi
systemctl enable named
systemctl restart named
service network restart
BIND_CONF=#{Vagrant::Openshift::Constants.plugins_conf_dir}/dns/bind/conf
mkdir -p $BIND_CONF
pushd $BIND_CONF
cat <<EOF> openshift-origin-dns-bind.conf
# Settings related to the bind variant of an OpenShift DNS plugin

# The DNS server
BIND_SERVER="172.17.42.1"

# The DNS server's port
BIND_PORT=53

# The key name for your zone
BIND_KEYNAME="#{domain}"

# base64-encoded key, most likely from /var/named/example.com.key.
BIND_KEYVALUE="$KEYSTRING"

# The base zone for the DNS server
BIND_ZONE="#{domain}"
EOF
popd
            })
          @app.call(env)
        end
      end
    end
  end
end