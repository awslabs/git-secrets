#!/usr/bin/env bash
#
# Installs the `git secrets` command.
# This script will automatically configure a .git-secrets file in your
# $HOME directory and set the file to 600 permissions. A global git
# configuration setting is then set to ensure that all projects use this global
# configuration file.
#
# You can pass the path to the directory to install the script in argument 1.
#
# If no directory is passed, then the script will install the git subcommand to
# /usr/local/bin (if available) or as a last resort, git --exec-path.

pass() { echo " $(tput setaf 2)✓$(tput sgr 0) $1"; }
fail() { echo " $(tput setaf 1)✗$(tput sgr 0)" $1; exit 1; }
warn() { echo " $(tput setaf 3)-$(tput sgr 0)" $1; }

usage() {
  echo ""
  echo "Usage: ./install.sh [<path>]"
  echo
  echo "Installs the git secrets command and sets up your environment."
  echo
  echo "Arguments:"
  echo "  <path>  Specify a custom path to install the git-secrets command."
  echo "          By default, the command will be installed to /usr/local/bin"
  echo "          if it exists, otherwise, it will be installed to the path"
  echo "          specified by git --exec-path"
  echo
  echo "Options:"
  echo "  -h  Displays this message."
  echo
  exit 0
}

[ "$1" == "-h" ] && usage

INSTALL_DIR="${1}"

install_secrets() {
  if [ ! -z "${INSTALL_DIR}" ]; then
    # The user may pass in a custom installation directory.
    [ ! -d "${INSTALL_DIR}" ] && fail "${INSTALL_DIR} does not exist"
  elif [ -d "/usr/local/bin" ]; then
    # Use /usr/local/bin as the directory if it exists.
    INSTALL_DIR="/usr/local/bin"
  else
    # Fall back to using git --exec-path
    INSTALL_DIR="$(git --exec-path)"
  fi
  path="${INSTALL_DIR}/git-secrets"
  cp git-secrets.sh "${path}"
  chmod +x "${path}"
}

install_secrets \
  && pass "Installed git-secrets command at ${INSTALL_DIR}/git-secrets" \
  || fail "Could not install git-secrets at ${INSTALL_DIR}/git-secrets"

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

echo -e "\nSUCCESS: successfully install git-secrets\n"
