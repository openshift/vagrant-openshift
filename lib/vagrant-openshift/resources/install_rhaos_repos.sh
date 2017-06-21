#!/bin/bash

set -o errexit

# on RHEL machines, if we're installing or using OSE, we will need the
# following repositories in order to fetch OSE-specific RPMs

mv "$(dirname "${BASH_SOURCE}")/rhaos31.repo" /etc/yum.repos.d/
mv "$(dirname "${BASH_SOURCE}")/rhaos32.repo" /etc/yum.repos.d/
mv "$(dirname "${BASH_SOURCE}")/rhaos33.repo" /etc/yum.repos.d/
mv "$(dirname "${BASH_SOURCE}")/rhaos34.repo" /etc/yum.repos.d/
mv "$(dirname "${BASH_SOURCE}")/rhaos35.repo" /etc/yum.repos.d/
mv "$(dirname "${BASH_SOURCE}")/rhaos36.repo" /etc/yum.repos.d/
