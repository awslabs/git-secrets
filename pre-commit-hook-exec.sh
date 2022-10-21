#!/usr/bin/env bash
# pre-commit clones the git repo to a cache-directory that it manages.
# The entry script is executed using the absolute path to this cache-directory
# so we can use this to locate the git-secrets script and add it to PATH
# without requiring the user to manually install it.

set -eu

PARENTDIR=$(dirname "${BASH_SOURCE}")
export PATH="$PARENTDIR:$PATH"
exec git secrets --pre_commit_hook "$@"
