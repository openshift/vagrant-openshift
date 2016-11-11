#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ ! -e /etc/fedora-release ]]; then
    sed -i 's,^SELINUX=.*,SELINUX=permissive,' /etc/selinux/config
    setenforce 0
fi

systemctl enable ntpd

# Force socket reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

mkdir -p /data/src
mkdir -p /data/pkg
mkdir -p /data/bin

GO_VERSION=($(go version))
echo "Detected go version: $(go version)"

chown -R "${SSH_USER}:${SSH_USER}" /data

sed -i "s,^#DefaultTimeoutStartSec=.*,DefaultTimeoutStartSec=240s," /etc/systemd/system.conf