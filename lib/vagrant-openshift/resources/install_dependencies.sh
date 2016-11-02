#!/bin/bash

set -o errexit

yum install -y                       \
            augeas                   \
            bzr                      \
            bridge-utils             \
            bzip2                    \
            bind                     \
            bsdtar                   \
            btrfs-progs-devel        \
            bind-utils               \
            ctags                    \
            device-mapper-devel      \
            ethtool                  \
            e2fsprogs                \
            firefox                  \
            fontconfig               \
            git                      \
            gcc                      \
            gcc-c++                  \
            glibc-static             \
            gnuplot                  \
            httpie                   \
            hg                       \
            iscsi-initiator-utils    \
            jq                       \
            java-1.?.0-openjdk       \
            kernel-devel             \
            krb5-devel               \
            libselinux-devel         \
            libnetfilter_queue-devel \
            lsof                     \
            make                     \
            mlocate                  \
            ntp                      \
            openldap-clients         \
            openvswitch              \
            rubygems                 \
            screen                   \
            ShellCheck               \
            socat                    \
            sqlite-devel             \
            strace                   \
            sysstat                  \
            tcpdump                  \
            tig                      \
            tmux                     \
            unzip                    \
            vim                      \
            wget                     \
            xfsprogs                 \
            xorg-x11-utils           \
            Xvfb                     \
            yum-utils                \
            zip