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

unset GOPATH

function cleanup_instance() {
	pushd "${OS_ROOT}"
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
	popd
}

function conditional_cleanup_instance() {
	if [[ -z "${SKIP_CLEANUP:-}" ]]; then
		cleanup_instance
	fi
}

# validate_version validates that the version of the package installed
# on the remote VM is equal to the expected version provided
function validate_version() {
	local package=$1
	local expected_version=$2
	local actual_version
	actual_version="$( vagrant ssh -c "rpm -q --queryformat='%{version}' '${package}'" )"
	if [[ ! "${expected_version}" = "${actual_version}" ]]; then
		echo "[FAILURE] Expected to find ${package}-${expected_version}, but got ${package}-${actual_version}."
		return 1
	fi
	echo "[SUCCESS] Found ${package}-${actual_version} on the remote machine."
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
pushd "${VOS_ROOT}"
if [[ -z "${SKIP_INSTALL:-}" ]]; then
	echo "[INFO] Building new vagrant-openshift gem and installing plugin"
	hack/update.sh
	vagrant plugin install vagrant-aws
fi
popd

OS_ROOT="./origin"
if [[ -n "${GOPATH_OVERRIDE:-}" ]]; then
	export GOPATH="${GOPATH_OVERRIDE}"
	mkdir -p "${GOPATH}"
	OS_ROOT="${GOPATH}/src/github.com/openshift/origin"
fi

test_vagrant origin-local-checkout --replace

# Next, create a VM and run our tests in it
pushd "${OS_ROOT}"
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

# The following steps ensure that we can build the `deps` image from the `os` base
test_vagrant build-origin-base

# Install Docker and Golang at specific versions
test_vagrant install-golang --golang.version=1.6.3 \
                            --repo=oso-rhui-rhel-server-releases-optional
validate_version 'golang' '1.6.3'

docker_repo='https://mirror.openshift.com/enterprise/rhel/dockertested/x86_64/os/'
test_vagrant install-docker --docker.version=1.12.6              \
                            --repourl="${docker_repo}"           \
                            --repo='oso-rhui-rhel-server-*'
validate_version 'docker' '1.12.6'

test_vagrant origin-local-checkout --replace --repo origin-web-console
test_vagrant clone-upstream-repos --clean --repo origin-web-console
test_vagrant sync-origin-console -s
test_vagrant install-origin-assets-base

test_vagrant clone-upstream-repos --clean --repo origin
test_vagrant checkout-repos --repo origin
test_vagrant build-origin-base-images
test_vagrant install-origin
test_vagrant build-origin --images

test_vagrant test-origin-console -d

test_vagrant origin-local-checkout --replace --repo source-to-image 
test_vagrant clone-upstream-repos --clean --repo source-to-image
test_vagrant sync-sti --clean --source
test_vagrant build-sti --binary-only

popd

echo "[SUCCESS] vagrant-openshift tests successful"
