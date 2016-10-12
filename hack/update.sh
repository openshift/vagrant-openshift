#!/bin/bash

# This script will attempt to build the vagrant-openshift gem
# from the current source tree and install it locally in the
# vagrant plugin environment.

set -o errexit
set -o nounset
set -o pipefail

VAGRANT_OPENSHIFT_ROOT="$( cd "$( dirname "${BASH_SOURCE}" )/.."; pwd )"
pushd "${VAGRANT_OPENSHIFT_ROOT}" >/dev/null 2>&1

if ! git diff-index --quiet HEAD; then
	echo "[WARNING] Uncommited changes exist either in stage or in the working tree."
	echo "[WARNING] Commit them to proceed in building the plugin."
	exit 1
fi

echo "[INFO] Building vagrant-openshift gem using bundler..."
{
	bundle
	bundle install
	bundle exec rake
} >/tmp/vagrant-origin-update.log 2>&1
echo "[INFO] Full build and install logs placed at /tmp/vagrant-openshift-update.log"

vagrant plugin install pkg/vagrant-openshift-*.gem

popd >/dev/null 2>&1

echo "[INFO] Successfully built and installed vagrant-openshift plugin"