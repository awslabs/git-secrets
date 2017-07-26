#!/usr/bin/env bash

set -e

if [ -f /etc/debian_version ]; then
    apt-get -y update
    apt-get -y install gcc wget
    apt-get -y install make git=$GIT_VER
elif [ -f /etc/redhat-release ]; then
    yum -y update
    yum -y install make git gcc wget
fi

wget https://ftp.gnu.org/gnu/bash/bash-$BASH_VER.tar.gz
tar -xvf bash*
cd bash-$BASH_VER
./configure --prefix=/usr \
    --bindir=/bin \
    --without-bash-malloc \
    --with-installed-readline
make
make install

# Clone git-secrets, install and run tests.
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make install
make test
