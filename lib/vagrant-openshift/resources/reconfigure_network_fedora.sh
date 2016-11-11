#!/bin/bash

set -o errexit

if [[ -e /etc/fedora-release ]]; then
    if [[ ! -L /etc/udev/rules.d/80-net-setup-link.rules ]]; then
        # If it's not already done, we need to enforce the older eth* naming
        # sequence on Fedora machines as Vagrant isn't compatible with the
        # systemd197 name changes.
        ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
        rm -f /etc/sysconfig/network-scripts/ifcfg-enp0s3
    fi
fi