#!/usr/bin/env bash

set -e

if [ -z ${GIT_VER+x} ]; then
    GIT_CMD="git"
else
    GIT_CMD="git=$GIT_VER"
fi

if [ -f /etc/debian_version ]; then
    echo "Updating apt-get"
    apt-get -qq -y update
    echo "Installing gcc wget make"
    apt-get -y install gcc wget make > /dev/null
    apt-get -y install dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev

elif [ -f /etc/redhat-release ]; then
    echo "Updating yum"
    yum -q -y update
    echo "Installing gcc wget make"
    dnf -y install dh-autoreconf curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel
    yum -y install make gcc wget > /dev/null
    ln -s /usr/bin/db2x_docbook2texi /usr/bin/docbook2x-texi
fi

# Install git from source
wget https://www.kernel.org/pub/software/scm/git/git-$GIT_VER.tar.gz
tar -zxf git-$GIT_VER.tar.gz
cd git-$GIT_VER
make -s configure
./configure --prefix=/usr --quiet
make -s all
make -s install 

# Install bash from source
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

cd /
# Clone git-secrets, install and run tests.
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make -s install
make -s test
