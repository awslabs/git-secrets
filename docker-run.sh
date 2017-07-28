#!/usr/bin/env bash

set -e

if [ -f /etc/debian_version ]; then
    apt-get -y -q update
    echo "Installing gcc wget make git=$GIT_VER"
    apt-get -y -qq install gcc wget make git=$GIT_VER
elif [ -f /etc/redhat-release ]; then
    echo "Updating yum"
    yum -y -q update
    echo "Installing gcc wget make git"
    yum -y -q install make git gcc wget
fi

wget https://ftp.gnu.org/gnu/bash/bash-$BASH_VER.tar.gz
tar -zxf bash-$BASH_VER.tar.gz
cd bash-$BASH_VER
./configure --prefix=/usr \
    --bindir=/bin \
    --without-bash-malloc \
    --with-installed-readline \
    --quiet
make -s
make -s install

# Clone git-secrets, install and run tests.
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make -s install
make -s test
