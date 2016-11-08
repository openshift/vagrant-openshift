#!/bin/bash

set -o errexit

# we depend on a version of Docker that's newer than the RPMS in
# RHEL, so we need to install our own repository and install from
# there
if [[ -e /etc/redhat-release && ! -e /etc/fedora-release && ! -e /etc/centos-release ]]; then
	mv "$(dirname "${BASH_SOURCE}")/dockerextra.repo" /etc/yum.repos.d/
fi