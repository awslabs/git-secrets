#!/usr/bin/env bash
#
# Installs the `git secrets` command and associated git commands.
# You can pass the path to the directory to install the script in argument 1.
# If no directory is passed, then the script will install the git subcommand to
# /usr/local/bin (if available) or as a last resort, git --exec-path.

INSTALL_DIR="$1"

# Show help if "-h" is provided.
if [ "$INSTALL_DIR" == "-h" ]; then
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
fi

pass() { echo -e " $(tput setaf 2)✓$(tput sgr 0) $1"; }
warn() { echo -e " $(tput setaf 3)-$(tput sgr 0)" $1; }
fail() { echo -e " $(tput setaf 1)✗$(tput sgr 0)" $1 && exit 1; }

# Installs git-secrets to an approriate path.
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
  cp git-secrets "${path}" && chmod +x "${path}" \
    && pass "Installed git-secrets command at ${INSTALL_DIR}/git-secrets" \
    || fail "Could not install git-secrets at ${INSTALL_DIR}/git-secrets"
}

# Determine the most appropriate grep for the system. gegrep is often used
# for extended greps to not overwrite system grep (e.g., homebrew).
set_grep_config() {
  local grep_command="$(git config --get secrets.grep)"
  if [ ! -z "${grep_command}" ]; then
    pass "grep command already configured: ${grep_command}"
    return
  elif [ -x "$(which gegrep 2>&1)" ]; then
    grep_command='gegrep'
  elif [ -x "$(which egrep 2>&1)" ]; then
    grep_command='egrep'
  else
    fail "Could not find grep on your system"
  fi
  git config --global --add secrets.grep "${grep_command}"
  pass "Configured grep command: ${grep_command}"
}

success_check() {
  git secrets -h > /dev/null 2>&1 \
    && pass "git-secrets has been installed successfully\n" \
    || fail "git-secrets did not install correctly\n"
}

echo -e "Installing git-secrets...\n"

install_secrets
set_grep_config
success_check
