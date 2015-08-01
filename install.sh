#!/usr/bin/env bash
#
# Installs the `git secrets` command.
# This script will automatically configure a .git-secrets file in your
# $HOME directory and set the file to 600 permissions. A global git
# configuration setting is then set to ensure that all projects use this global
# configuration file.

pass() { echo "$(tput setaf 2) ✓ $1$(tput sgr 0)"; }
fail() { echo "$(tput setaf 1) ✗ $1$(tput sgr 0)"; exit 1; }
warn() { echo "$(tput setaf 3) - $1$(tput sgr 0)"; }

install_secrets() {
  cp git-secrets.sh "$1" && chmod +x "$1"
}

command_path="$(git --exec-path)"/git-secrets
install_secrets "${command_path}" \
  && pass "Installed git-secrets command at ${command_path}" \
  || fail "Could not install git-secrets at ${command_path}"

[ -f "${HOME}/.git-secrets" ] \
  && pass "Found global secrets file at ${HOME}/.git-secrets" \
  || warn "No .git-secrets file was found at ${HOME}/.git-secrets"

git secrets -v > /dev/null 2>&1 \
  && pass "git-secrets has been installed successfully" \
  || fail "git-secrets did not install correctly"

# Install a default secrets file if one is not set.
global="$(git config --get git-secrets.file)"

if [ ! -z "${global}" ]; then
  pass "Found a global git-secrets configuration setting: ${global}"
elif [ ! -z "${HOME}" ]; then
  global_file="${HOME}/.git-secrets"
  if [ ! -f "${global_file}" ]; then
    touch "${global_file}"
    chmod 600 "${global_file}"
    pass "Created a global git-secrets file at ${global_file}"
  else
    pass "Found an existing global git-secrets file at ${global_file}"
  fi
  git config --global git-secrets.file "${global_file}" \
    && pass "Configured a global git-secrets file at ${global_file}" \
    || warn "Could not configutr global git-secrets file for ${global_file}"
fi
