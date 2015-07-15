#!/usr/bin/env bash
#
# Installs the `git secrets` command.

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
