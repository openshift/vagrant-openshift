#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

groupadd -f docker
usermod -a -G docker "${SSH_USER}"

ADDITIONAL_OPTIONS='--insecure-registry=172.30.0.0/16 --insecure-registry=ci.dev.openshift.redhat.com:5000'
sed -i "s,^OPTIONS='\\(.*\\)',OPTIONS='${ADDITIONAL_OPTIONS} \\1'," /etc/sysconfig/docker
sed -i "s,^OPTIONS=-\\(.*\\),OPTIONS='${ADDITIONAL_OPTIONS} -\\1'," /etc/sysconfig/docker
sed -i "s,^ADD_REGISTRY='\\(.*\\)',#ADD_REGISTRY='--add-registry=docker.io \\1'," /etc/sysconfig/docker

if [[ -z "${SKIP_VG:-}" ]]; then
    if lvdisplay docker-vg >/dev/null 2>&1; then
        VG="docker-vg"
    elif lvdisplay vg_vagrant >/dev/null 2>&1; then
        VG="vg_vagrant"
    elif lvdisplay fedora >/dev/null 2>&1; then
        VG="fedora"
    elif lvdisplay centos >/dev/null 2>&1; then
        VG="centos"
    else
        echo "[ERROR] Could not determine volume group to use for Docker storage!"
        exit 1
    fi

    lvcreate -n docker-data -l 70%FREE /dev/${VG}
    lvcreate -n docker-metadata -l 17%FREE /dev/${VG}
    lvcreate -n openshift-xfs-vol-dir -l 100%FREE /dev/${VG}
    mkfs.xfs /dev/${VG}/openshift-xfs-vol-dir
    mkdir -p /mnt/openshift-xfs-vol-dir
    echo /dev/${VG}/openshift-xfs-vol-dir /mnt/openshift-xfs-vol-dir xfs gquota 1 1 >> /etc/fstab
    mount /mnt/openshift-xfs-vol-dir
    chown -R "${SSH_USER}:${SSH_USER}" /mnt/openshift-xfs-vol-dir

    DOCKER_STORAGE_OPTIONS="  -s devicemapper"
    DOCKER_STORAGE_OPTIONS+=" --storage-opt dm.datadev=/dev/${VG}/docker-data"
    DOCKER_STORAGE_OPTIONS+=" --storage-opt dm.metadatadev=/dev/${VG}/docker-metadata"
    if [[ "$(repoquery --pkgnarrow=installed --qf '%{version}' docker)" =~ ^1\.[0-9]{2}\..* ]]; then
        # after Docker 1.10 we need to amend the devicemapper options
        DOCKER_STORAGE_OPTIONS+=" --storage-opt dm.use_deferred_removal=true"
        DOCKER_STORAGE_OPTIONS+=" --storage-opt dm.use_deferred_deletion=true"
    fi
    sed -i "s,^DOCKER_STORAGE_OPTIONS=.*,DOCKER_STORAGE_OPTIONS='${DOCKER_STORAGE_OPTIONS}'," /etc/sysconfig/docker-storage
fi

# Docker 1.8.2 now sets a TimeoutStartSec of 1 minute.  Unfortunately, for some
# reason the initial docker start up is now taking > 5 minutes.  Until that is fixed need this.
sed -i 's,TimeoutStartSec=.*,TimeoutStartSec=10min,'  /usr/lib/systemd/system/docker.service

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable docker
time systemctl start docker