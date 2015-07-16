#!/usr/bin/env bash
#
# Installs the `git secrets` command.
#
# You can pass the path to the directory to install the script in argument 1.
#
# If no directory is passed, then the script will install the git subcommand to
# /usr/local/bin (if available) or as a last resort, git --exec-path.

pass() { echo "$(tput setaf 2) ✓ $1$(tput sgr 0)"; }
fail() { echo "$(tput setaf 1) ✗ $1$(tput sgr 0)"; exit 1; }
warn() { echo "$(tput setaf 3) - $1$(tput sgr 0)"; }

install_secrets() {
  path="$1/git-secrets"
  cp git-secrets.sh "${path}"
  chmod +x "${path}"
}

INSTALL_DIR="${1}"

if [ ! -z "${INSTALL_DIR}" ]; then
  [ ! -d "${INSTALL_DIR}" ] && fail "${INSTALL_DIR} does not exist"
elif [ -d "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
else
  INSTALL_DIR="$(git --exec-path)"
fi

install_secrets "${INSTALL_DIR}" \
  && pass "Installed git-secrets command at ${INSTALL_DIR}" \
  || fail "Could not install git-secrets at ${INSTALL_DIR}"

[ -f "${HOME}/.git-secrets" ] \
  && pass "Found global secrets file at ${HOME}/.git-secrets" \
  || warn "No .git-secrets file was found at ${HOME}/.git-secrets"

git secrets -v > /dev/null 2>&1 \
  && pass "git-secrets has been installed successfully" \
  || fail "git-secrets did not install correctly"
