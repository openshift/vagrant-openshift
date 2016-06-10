#!/bin/bash

set -o errexit

yum install -y golang

if [[ ! -e /etc/fedora-release ]] && go version | grep -q 'go1\.4'; then
    # Prior to go1.5, the cgo symbol tables were not provided in the base golang
    # package on RHEL and CentOS, so if we've installed go1.4.x and we're not on
    # Fedora, we need to also install `golang-pkg-linux-amd64'
    yum install -y golang-pkg-linux-amd64
fi