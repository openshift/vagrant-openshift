#!/bin/bash

# This script uses the current state of the repository to build a new vagrant-openshift
# gem, install it, and then exercise the CLI of the vagrant-openshfit plugin to test its
# functionality. This script honors the following environment variables:
#  - TEST_VM_NAME:    the name to use to identify the VM launched for testing
#  - TEST_VM_SIZE:    the VM size (as the AWS instance name) to use
#  - SKIP_INSTALL:    skips building and installing a new vagrant-openshift gem
#  - SKIP_CLEANUP:    skips cleaning up the VMs created for tests
#  - CLEANUP_RENAME:  cleans up instances by stopping and renaming instead of destroying them
#  - GOPATH_OVERRIDE: uses a temporary directory for $GOPATH instead of inheriting it from the host
#  - VERBOSE:         always show full command output, even a command succeeded

set -o errexit
set -o nounset
set -o pipefail

function cleanup_instance() {
	pushd "${OS_ROOT}" >/dev/null 2>&1
	if [[ -f ".vagrant-openshift.json" ]]; then
		if [[ -n "${CLEANUP_RENAME:-}" ]]; then
			vagrant modify-instance --stop --rename 'terminate'
		else
			vagrant destroy -f
		fi
	else
		# we were not able to clean up the instance, but the code
		# below will expect it to be gone and may fail later trying
		# to re-create it due to a name conflict, so we need to
		# fail early and loudly
		echo "[FAILURE] Could not clean up instance, exiting"
		exit 1
	fi
	rm -rf .vagrant
	popd >/dev/null 2>&1
}

function conditional_cleanup_instance() {
	if [[ -z "${SKIP_CLEANUP:-}" ]]; then
		cleanup_instance
	fi
}

# test_vagrant runs a vagrant command and allows us to only show output from failed commands
function test_vagrant() {
	echo "[INFO] Testing \`vagrant $*\`"
	if ! vagrant "$@" > /tmp/vagrant-openshift-test.log 2>&1; then
		cat /tmp/vagrant-openshift-test.log
		echo "[FAILURE] The command \`vagrant $*\` failed!"
		return 1
	elif [[ -n "${VERBOSE:-}" ]]; then
		cat /tmp/vagrant-openshift-test.log
	fi
	echo "[SUCCESS] The command \`vagrant $*\` succeeded!"
}

# First, build the new vagrant-openshift gem and install the plugin on the host
VOS_ROOT="$( cd "$( dirname "${BASH_SOURCE}" )/.."; pwd )"
pushd "${VOS_ROOT}" >/dev/null 2>&1
if [[ -z "${SKIP_INSTALL:-}" ]]; then
	echo "[INFO] Building new vagrant-openshift gem and installing plugin"
	hack/update.sh
	vagrant plugin install vagrant-aws
fi
popd >/dev/null 2>&1

OS_ROOT="./origin"
if [[ -n "${GOPATH_OVERRIDE:-}" ]]; then
	export GOPATH="${GOPATH_OVERRIDE}"
	mkdir -p "${GOPATH}"
	OS_ROOT="${GOPATH}/src/github.com/openshift/origin"
fi

test_vagrant origin-local-checkout --replace

# Next, create a VM and run our tests in it
pushd "${OS_ROOT}" >/dev/null 2>&1
test_vagrant origin-init --stage="os"                                \
                         --os="rhel7"                                \
                         --instance-type="${TEST_VM_SIZE:-m4.large}" \
                         "${TEST_VM_NAME:-vagrant-openshift-tests}"

for _ in $(seq 0 2) ; do
	if vagrant up --provider aws; then
		break
	fi

	echo "[WARNING] \`vagrant up\` failed - retrying"
	cleanup_instance
done

# We want to make sure we clean up after ourselves if this script exits unexpectedly
trap conditional_cleanup_instance EXIT

test_vagrant build-origin-base

test_vagrant clone-upstream-repos --clean
test_vagrant checkout-repos
test_vagrant build-origin-base-images
test_vagrant install-origin-assets-base

test_vagrant install-origin
test_vagrant build-origin --images
test_vagrant build-sti --binary-only

popd  >/dev/null 2>&1

echo "[SUCCESS] vagrant-openshift tests successful"