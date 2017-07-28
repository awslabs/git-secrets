#!/usr/bin/env bash

set -e

if [ -f /etc/debian_version ]; then
    echo "Updating apt-get"
    apt-get -qq -y update
    echo "Installing gcc wget make git=$GIT_VER"
    apt-get -y install gcc wget make git=$GIT_VER > /dev/null
elif [ -f /etc/redhat-release ]; then
    echo "Updating yum"
    yum -q -y update
    echo "Installing gcc wget make git"
    yum -y install make git gcc wget > /dev/null
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
