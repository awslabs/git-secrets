#!/usr/bin/env bash
OPTIONS_SPEC="\
install.sh [(-d ... | --install-dir=...)] [-y|--yes] [-n|--no]

Installs the git secrets command and sets up your environment.

By default, the command will be installed to /usr/local/bin if it exists,
otherwise, it will be installed to the path specified by git --exec-path. You
can provide a completely custom install directory using --install-dir.

When run in interactive mode, the installer will prompt you to seed your list
of prohibited secrets with common patterns and by checking various variables
found in your environment including credentials stored in ~/.aws/credentials.
--
d,install-dir       Specify a custom path to install git-secrets
y,yes               Set this flag to install all common secret patterns
n,no                Set this flag to not install any common secret patterns
h,help              Displays this message
"

. "$(git --exec-path)/git-sh-setup"

[[ -t 0 && -t 1 ]] && declare -r IS_ATTY=1 || declare -r IS_ATTY=0
declare INSTALL_DIR INSTALL_COMMON=0 NON_INTERACTIVE=0

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

add_pattern() {
  if [ "$1" != '' ]; then
    [ "$2" != '' ] && pass "Added prohibited pattern: $2"
    git config --add secrets.pattern "$1"
  fi
}

prompt() {
  [ "$INSTALL_COMMON" -eq 1 ] && return 0
  [ "$NON_INTERACTIVE" -eq 1 ] && return 1
  [ "$IS_ATTY" -eq 0 ] && return 1
  echo -e "\n$1"
  read -n 1 -p "[y/n] [enter for yes] " yn
  echo
  case $yn in
    [Nn]* ) return 1 ;;
    * ) return 0 ;;
  esac
}

pattern_prompt() {
  prompt "Add '$1' ($2) to your git-secrets patterns?"
}

while [ $# -gt 0 ]; do
  opt="$1"
  shift
  case "$opt" in
    -h) usage ;;
    -n) NON_INTERACTIVE=1 ;;
    -y) INSTALL_COMMON=1 ;;
    -d) INSTALL_DIR="$1"; shift ;;
    --) break ;;
    *) die "Unexpected option: $opt" ;;
  esac
done

echo -e "Installing git-secrets...\n"

# 1) Copies git-secrets to the approriate path.
########################################################
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

# 2) Determine the most appropriate grep for the system. gegrep is sometimes
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

# 3) Call help to ensure it installed correctly
########################################################
git secrets -h > /dev/null 2>&1 \
  && pass "git-secrets has been installed successfully" \
  || fail "git-secrets did not install correctly"

# 4) Import common patterns from git configs
########################################################
git_ini_checks=('user.email' 'github.user' 'github.token')
for check in "${git_ini_checks[@]}"; do
  value=$(git config --get "${check}")
  if [ "$value" != '' ] \
        && pattern_prompt "${value}" "git config --get ${check}"; then
    add_pattern "${value}" "${check}"
  fi
done

# 5) Add common patterns
########################################################
common_patterns=(
  'generic username: username=.+'
  'generic password: password=.+'
  'AWS access key ID: (?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])'
  'AWS secret access key: (?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])'
)

for pattern in "${common_patterns[@]}"; do
  description="${pattern%: *}"
  value="${pattern#*: }"
  if pattern_prompt "${value}" "common patterns: ${description}"; then
    add_pattern "${value}" "${description}"
  fi
done

# 6) Import passwords from you ~/.aws/credentials file
########################################################
if [ -x "$(which aws 2>&1)" ] \
      && [ -f ~/.aws/credentials ] \
      && prompt "Import credentials from ~/.aws/credentials?"; then
  profiles=$(egrep -oh '^\[(.+)\]$' ~/.aws/credentials)
  for profile in ${profiles[@]}; do
    # Strip the "[" and "]" characters.
    profile="${profile:1:${#profile}-2}"
    check="${profile}.aws_access_key_id"
    add_pattern $(aws configure get "${check}") "${check}"
    check="${profile}.aws_secret_access_key"
    add_pattern $(aws configure get "${check}") "${check}"
  done
fi

# 7) Last step: ensure secrets can scan correctly
########################################################
echo
echo '' | git secrets scan -f - \
  && pass 'Successfully installed' \
  || fail 'Failed to install correctly'
echo
