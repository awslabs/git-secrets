#!/usr/bin/env bash
#
# Installs the `git secrets` command and associated git commands.
# You can pass the path to the directory to install the script in argument 1.
# If no directory is passed, then the script will install the git subcommand to
# /usr/local/bin (if available) or as a last resort, git --exec-path.

# Show help if "-h" is provided.
if [ "$1" == "-h" ]; then
  echo "usage: install.sh [<path>]"
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

pass() {
  echo -e " $(tput setaf 2)✓$(tput sgr 0) $1";
}

fail() {
  echo -e " $(tput setaf 1)✗$(tput sgr 0) $1"
  exit 1
}

set_grep_command() {
  git config --global --add secrets.grep "$1"
  pass "Configured grep command: $1"
}

echo -e "Installing git-secrets...\n"

# Determine the appropriate directory to install
########################################################
install_dir="$1"
if [ ! -z "$install_dir" ]; then
  # The user may pass in a custom installation directory.
  [ ! -d "${install_dir}" ] && fail "${install_dir} does not exist"
elif [ -d "/usr/local/bin" ]; then
  # Use /usr/local/bin as the directory if it exists.
  install_dir="/usr/local/bin"
else
  # Fall back to using git --exec-path
  install_dir="$(git --exec-path)"
fi

# Installs git-secrets to an approriate path.
########################################################
path="${install_dir}/git-secrets"
cp git-secrets "${path}" && chmod +x "${path}" \
  && pass "Installed git-secrets command at ${install_dir}/git-secrets" \
  || fail "Could not install git-secrets at ${install_dir}/git-secrets"

# Determine the most appropriate grep for the system. gegrep is sometimes
# used for extended greps to not overwrite system grep (e.g., homebrew).
########################################################
if [ ! -z "$(git config --get secrets.grep)" ]; then
  pass "grep command already configured"
elif [ -x "$(which gegrep 2>&1)" ]; then
  set_grep_command 'gegrep'
elif [ -x "$(which egrep 2>&1)" ]; then
  set_grep_command 'egrep'
else
  fail "Could not find grep on your system"
fi

# Last step: call help to ensure it installed correctly
########################################################
git secrets -h > /dev/null 2>&1 \
  && pass "git-secrets has been installed successfully\n" \
  || fail "git-secrets did not install correctly\n"
