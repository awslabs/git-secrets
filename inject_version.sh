#!/bin/bash

# set from Makefile
VERSION="$(date +v%Y%m%d)-$(git describe --tags --always)"

# shellcheck says set and then export.
export VERSION

# shellcheck disable=SC2016
envsubst '$VERSION' < git-secrets.build > git-secrets

chmod 755 git-secrets
