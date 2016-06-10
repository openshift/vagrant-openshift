#!/bin/bash

set -o errexit

cd /tmp

# Add signing key for Chrome repo
wget https://dl.google.com/linux/linux_signing_key.pub
rpm --import linux_signing_key.pub

# Add Chrome yum repo
yum-config-manager --add-repo=http://dl.google.com/linux/chrome/rpm/stable/x86_64

# Install chrome
yum install -y google-chrome-stable

# Install chromedriver
wget https://chromedriver.storage.googleapis.com/2.16/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
mv chromedriver /usr/bin/chromedriver
chown root /usr/bin/chromedriver
chmod 755 /usr/bin/chromedriver