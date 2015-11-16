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

# Add a pattern if it is not empty
add_pattern() {
  if [ "$1" != '' ]; then
    [ "$2" != '' ] && pass "Added prohibited pattern: $2"
    git config --add secrets.pattern "$1"
  fi
}

# Prompt the user for a y/n question
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

# Prompt the user to add a secret with context
pattern_prompt() {
  prompt "Add $2 to your git-secrets patterns? $1"
}

# Quote a regular expression
re_quote() {
  sed 's/[]\.|$(){}?+*^]/\\&/g' <<< "$*"
}

# Parse the given options and arguments.
########################################################

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

# 2) Call help to ensure it installed correctly
########################################################
git secrets -h > /dev/null 2>&1 \
  && pass "git-secrets has been installed successfully" \
  || fail "git-secrets did not install correctly"

# 3) Import common patterns from git configs
########################################################
git_ini_checks=('user.email' 'github.user' 'github.token')
for check in "${git_ini_checks[@]}"; do
  value=$(git config --get "${check}")
  value=$(re_quote "${value}")
  if [ "$value" != '' ] \
        && pattern_prompt "${value}" "git config --get ${check}"; then
    add_pattern "${value}" "${check}"
  fi
done

# 4) Add common patterns
########################################################
# Reusable regex patterns
aws="(AWS_|aws_)"
quote="(\"|')"
opt_quote="${quote}?"
connect="\s*(=|:|=>)\s*"
common_patterns=(
  'generic username: username=.+'
  'generic password: password=.+'
  'AWS Access Key ID: [A-Z0-9]{20}'
  "AWS Secret Access Key: ${opt_quote}${aws}?(SECRET|secret)(_ACCESS|_access)?_(KEY|key)${opt_quote}${connect}${opt_quote}[A-Za-z0-9/\+=]{40}${opt_quote}"
  "AWS account ID: ${opt_quote}${aws}?(ACCOUNT|account)(_ID|_id)?${opt_quote}${connect}${opt_quote}[0-9]{4}\-?[0-9]{4}\-?[0-9]{4}${opt_quote}"
)

for pattern in "${common_patterns[@]}"; do
  description="${pattern%: *}"
  value="${pattern#*: }"
  if pattern_prompt "${value}" "common patterns: ${description}"; then
    add_pattern "${value}" "${description}"
  fi
done

# 5) Import passwords from ~/.aws/credentials file
########################################################
if [ -x "$(which aws 2>&1)" ] \
      && [ -f ~/.aws/credentials ] \
      && prompt "Import credentials from ~/.aws/credentials?"; then
  profiles=$(GREP_OPTIONS='' egrep -e '^\[(.+)\]$' ~/.aws/credentials)
  paths=('aws_access_key_id' 'aws_secret_access_key')
  for profile in ${profiles[@]}; do
    # Strip the "[" and "]" characters.
    profile="${profile:1:${#profile}-2}"
    for path in ${paths[@]}; do
      check="${profile}.${path}"
      value="$(aws configure get "${check}")"
      add_pattern "$(re_quote $value)" "${check}"
    done
  done
fi

# 6) Last step: ensure secrets can scan correctly
########################################################
echo
echo '' | git secrets scan -f - \
  && pass 'Successfully installed' \
  || fail 'Failed to install correctly'
echo
