#!/usr/bin/env bash
declare -r VERSION="0.0.1"
declare PATTERNS=""
[[ -t 0 && -t 1 ]] && declare -r IS_ATTY=1 || declare -r IS_ATTY=0

#######################################################################
# Help and error messages
#######################################################################

color() {
  [ $IS_ATTY -eq 1 ] && echo "$(tput setaf $1)${@:2}$(tput sgr 0)" || echo $2
}

die() { color 1 "$@" >&2; exit 1; }

version() {
  echo "git-secrets ${VERSION}"
}

usage() {
  version
  echo ""
  echo "Usage: git secrets <command> [<options>] [<args>]"
  echo
  echo "Options:"
  echo "  -h  Displays this message."
  echo "  -v  Displays the version number."
  echo
  echo "Commands:"
  echo "  scan     Scans the passed in file name for prohibited patterns."
  echo "  install  Installs git hooks for a repository."
  exit 0
}

scan_usage() {
  echo "Usage: git secrets scan [<options>] <filename>"
  echo
  echo "Scans the given file (FILENAME) for a list of prohibited patterns"
  echo "found by calling git config --get-all secrets.pattern. If any of"
  echo "these prohibited patterns are found found in the file, then the match"
  echo "is printed and the script fails."
  echo
  echo "Options:"
  echo "  -h  Displays this message."
  echo
  echo "Arguments:"
  echo "  filename  The path to a file on disk to scan. Pass - for stdin."
  exit 0
}

install_usage() {
  echo "Usage: git secrets install [<options>] <repo>"
  echo
  echo "Installs pre-commit and commit-msg hooks for the given repository."
  echo "If no repository argument is provided, then the command attempts"
  echo "to install hooks to a git repository in the working directory."
  echo
  echo "Git only allows a single script to be executed per hook. If the"
  echo "repository contains Debian style subdirectories like pre-commit.d"
  echo "and commit-msg.d, then the git hooks will be installed into these"
  echo "directories, which assumes that you've configured the corresponding"
  echo "hooks to execute all of the scripts found in these directories."
  echo
  echo "Options:"
  echo "  -h  Displays this message."
  echo
  echo "Arguments:"
  echo "  repo  The path to a git repository."
  exit 0
}

# Prints a warning that the commit contains a prohibited pattern.
# Arguments: $1: The first line of text to print.
prohibited_warning() {
  echo
  echo "Error: Prohibited pattern match"
  echo "==============================="
  echo
  echo "$1"
  echo
  echo "You can view the prohibited pattern matches in the above output."
  echo "Please remove these patterns, rebase, and resubmit the patch."
}

#######################################################################
# Helper functions
#######################################################################

load_secret_patterns() {
  PATTERNS="$(git config --get-all secrets.pattern)"
  # Warn if no patterns are configured.
  if [ -z "$PATTERNS" ]; then
    color 3 "No prohibited patterns have been defined" 1>&2
    cat << EOF 1>&2
========================================
You can add prohibited patterns by editing your .git/config file or by using
the following command for each prohibited pattern you wish to add:

    git config --add secrets.pattern <regex-pattern>

You can list all of the configured prohibited patterns by running the
following command:

    git config --get-all secrets.pattern
EOF
  fi
}

git_repo_root() {
  git status > /dev/null 2>&1 && git rev-parse --show-toplevel
}

check_pattern() {
  local pattern="$1" filename="$2" grep_cmd=$(git config --get secrets.grep)
  # Ensure the grep command is valid and executable.
  grep_cmd=$(which "${grep_cmd:-egrep}")
  [ ! -x "$grep_cmd" ] && die "Invalid secrets.grep command: ${grep_cmd}"
  GREP_OPTIONS='' $grep_cmd --colour -nw -H -e "${pattern}" "${filename}"
}

validate_filename() {
  [ -z "$1" ] && die "Empty or missing filename argument."
  [ ! -f "$1" ] && die "File not found: $1"
}

#######################################################################
# Git hook implementation functions
#######################################################################

prompt_for_input() {
  local pattern=$1 file=$2
  local -r affirmative="Yes. This is a false positive, allow it and continue."
  local -r negative="No. This is a secret. Do not commit it -- fail."
  echo "^^^ Matched prohibited pattern in ${file}: ${pattern}"
  echo "Do you wish to commit this anyway?"
  select yn in "${negative}" "${affirmative}"; do
    case $yn in
      [nN]* ) die "Found a secret in ${file}";;
      [Y]* ) break;;
    esac
  done
}

# Scans a file for prohibited patterns.
scan() {
  local -r filename="$1"
  load_secret_patterns
  # Validate the filename only if it is not stdin ("-")
  [ "${filename}" != "-" ] && validate_filename "${filename}"
  if [ ! -z "$PATTERNS" ]; then
    if [ $IS_ATTY -ne 1 ]; then
      # Check will all patterns at once
      check_pattern "$PATTERNS" "${filename}" && die "Found secrets"
    else
      # Check each pattern individually for user prompts.
      for pattern in $PATTERNS; do
        if check_pattern "${pattern}" "${filename}"; then
          prompt_for_input "${pattern}" "${filename}"
        fi
      done
    fi
  fi
}

# Scans a commit message for prohibited patterns.
commit_msg_hook() {
  local -r commit_msg_file="$1"
  git secrets scan "${commit_msg_file}" && exit 0
  prohibited_warning "Your commit message contains a prohibited pattern."
  exit 1
}

# NOTE: This is based on git's pre-commit.sample script.
# Allows the hook to reject commits for brand new repos.
determine_rev_to_diff() {
  [ git rev-parse --verify HEAD >/dev/null 2>&1 ] \
    && "HEAD" || echo "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
}

# Scans a commit for prohibited patterns.
pre_commit_hook() {
  local file found_match=0 against=$(determine_rev_to_diff)
  local changes=$(git diff-index --name-status --cached $against -- | cut -c3-)

  for file in $changes; do
    git secrets scan "${file}" || found_match=1
  done

  if [ "$found_match" -eq 1 ]; then
    prohibited_warning "Your commit contains a prohibited pattern."
    exit 1
  fi
}

# Determines if merging in a commit will introduce tainted history.
prepare_commit_msg_hook() {
  case "$2,$3" in
    merge,)
      local git_head=$(env | grep GITHEAD)  # e.g. GITHEAD_<sha>=release/1.43
      local sha="${git_head##*=}"           # Get just the SHA
      local branch=$(git symbolic-ref HEAD) # e.g. refs/heads/master
      local dest="${branch#refs/heads/}"    # cut out "refs/heads"
      echo "Checking if merging ${sha} into ${dest} adds prohibited history"
      git log "${dest}".."${sha}" -p | git secrets scan -
      ;;
    *) ;;
  esac
}

#######################################################################
# Git hook installation functions
#######################################################################

# Determines the approriate path for a hook to be installed
# This function respects any found $hook.d directories.
determine_hook_path() {
  local -r hook="$1" path="$2"
  local dest="${path}/.git/hooks/${hook}"
  local -r debian_dir="${path}/.git/hooks/${hook}.d"
  [ -d "${debian_dir}" ] && dest="${debian_dir}/git-secrets"
  [ -f "$dest" ] && color 3 "Overwriting $dest" 1>&2
  echo "$dest"
}

install_hook() {
  local -r dest="$1" name="$2" cmd="$3"
  [ -z "${dest}" ] && die "Expects the path to a file"
  [ -d "$(dirname ${dest})" ] || die "Directory not found: ${dest}"
  echo "#!/usr/bin/env bash" > "${dest}"
  echo "git secrets ${cmd} \"\$@\"" >> "${dest}"
  chmod +x "${dest}"
  color 2 "Installed ${name} hook to ${dest}"
}

install_hooks() {
  local dest git_repo="$1"
  dest=$(determine_hook_path "commit-msg" "${git_repo}")
  install_hook "${dest}" "commit-msg" "commit_msg_hook"
  dest=$(determine_hook_path "pre-commit" "${git_repo}")
  install_hook "${dest}" "pre-commit" "pre_commit_hook"
  dest=$(determine_hook_path "prepare-commit-msg" "${git_repo}")
  install_hook "${dest}" "prepare-commit-msg" "prepare_commit_msg_hook"
}

#######################################################################
# Dispatch to the appropriate functions
#######################################################################

main() {
  case "$cmd" in
    -h|--help|'') usage ;;
    -v|--version) version && exit 0 ;;
    commit_msg_hook|pre_commit_hook|prepare_commit_msg_hook) $cmd "$@" ;;
    scan)
      [ "$1" == "-h" ] && scan_usage
      scan "$@"
      ;;
    install)
      [ "$1" == "-h" ] && install_usage
      local git_repo_dir="$1"
      [ -z "${git_repo_dir}" ] && git_repo_dir=$(git_repo_root)
      install_hooks "$git_repo_dir"
      ;;
    *) die "Unknown command: $cmd" ;;
  esac
}

cmd=$1
shift
main "$@"
