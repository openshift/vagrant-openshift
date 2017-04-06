#!/bin/bash

set -o errexit

yum install -y                       \
            augeas                   \
            bind                     \
            bind-utils               \
            bridge-utils             \
            bsdtar                   \
            btrfs-progs-devel        \
            bzip2                    \
            bzr                      \
            ctags                    \
            device-mapper-devel      \
            e2fsprogs                \
            ethtool                  \
            firefox                  \
            fontconfig               \
            gcc                      \
            gcc-c++                  \
            git                      \
            glibc-static             \
            gnuplot                  \
            gpgme                    \
            gpgme-devel              \
            hg                       \
            httpie                   \
            iscsi-initiator-utils    \
            java-1.?.0-openjdk       \
            jq                       \
            kernel-devel             \
            krb5-devel               \
            libassuan                \
            libassuan-devel          \
            libnetfilter_queue-devel \
            libselinux-devel         \
            lsof                     \
            make                     \
            mlocate                  \
            ntp                      \
            openldap-clients         \
            openssl                  \
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
