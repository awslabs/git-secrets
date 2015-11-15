#!/usr/bin/env bash
#
# Checks if a given file contains any of the prohibited secret patterns.

declare -r VERSION="0.0.1"
declare PATTERNS=""

#######################################################################
# Help and error messages
#######################################################################

color() {
  if [ -t 1 ]; then
    echo "$(tput setaf $1)${@:2}$(tput sgr 0)"
  else
    echo $2
  fi
}

green() { color 2 "$@"; }
yellow() { color 3 "$@"; }
red() { color 1 "$@"; }
die() { red "$@" >&2; exit 1; }

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
  echo "You can view the prohibited pattern matches in the"
  echo "above output. Please remove these patterns, rebase,"
  echo "and resubmit the patch."
}

#######################################################################
# Helper functions
#######################################################################

load_secret_patterns() {
  PATTERNS="$(git config --get-all secrets.pattern)"
  # Warn if no patterns are configured.
  if [ -z "$PATTERNS" ]; then
    echo
    yellow "No prohibited patterns have been defined"
    echo "========================================"
    echo
    echo "You can add prohibited patterns by editing your .git/config file"
    echo "or by using the following command for each prohibited pattern you"
    echo -e "wish to add:\n"
    echo -e "$ git config --add secrets.pattern <regex-pattern>\n"
    echo "You can list all of the configured prohibited patterns by running"
    echo -e "the following command:\n"
    echo "$ git config --get-all secrets.pattern"
    echo
  fi
}

git_repo_root() {
  git status > /dev/null 2>&1 && git rev-parse --show-toplevel
}

negative_grep() {
  local -r pattern="$1"
  local -r filename="$2"
  local grep_cmd=$(git config --get secrets.grep)
  # Ensure the grep command is valid and executable.
  grep_cmd=$(which "${grep_cmd:-egrep}")
  [ ! -x "$grep_cmd" ] && die "Invalid secrets.grep command: ${grep_cmd}"
  GREP_OPTIONS='' $grep_cmd --colour -nw -H -e "${pattern}" "${filename}" \
    && return 1 || return 0
}

validate_filename() {
  local -r filename="$1"
  [ -z "${filename}" ] && die "Empty or missing filename argument."
  [ ! -f "${filename}" ] && die "File not found: ${filename}"
}

#######################################################################
# Git hook implementation functions
#######################################################################

# Scans a file for prohibited patterns.
scan() {
  local -r filename="$1"
  local -i return_code=0
  load_secret_patterns
  # Validate the filename only if it is not stdin ("-")
  [ "${filename}" != "-" ] && validate_filename "${filename}"
  if [ ! -z "$PATTERNS" ]; then
    negative_grep "${PATTERNS}" "${filename}"
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
determine_rev_to_diff() {
  if [ git rev-parse --verify HEAD >/dev/null 2>&1 ]; then
    echo "HEAD"
  else
    # Allows the hook to reject commits for brand new repos.
    echo "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  fi
}

# Scans a commit for prohibited patterns.
pre_commit_hook() {
  local -r against=$(determine_rev_to_diff)
  local -i found_match=0
  local changes=$(git diff-index --name-status --cached $against -- | cut -c3-)
  local file

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
  local -r hook="$1"
  local -r path="$2"
  local dest="${path}/.git/hooks/${hook}"
  local -r debian_dir="${path}/.git/hooks/${hook}.d"
  [ -d "${debian_dir}" ] && dest="${debian_dir}/git-secrets"
  [ -f "$dest" ] && yellow "Overwriting $dest" 1>&2
  echo "$dest"
}

install_hook() {
  local -r dest="$1"
  local -r name="$2"
  local -r cmd="$3"
  [ -z "${dest}" ] && die "Expects the path to a file"
  [ -d "$(dirname ${dest})" ] || die "Directory not found: ${dest}"
  echo "#!/usr/bin/env bash" > "${dest}"
  echo "git secrets ${cmd} \"\$@\"" >> "${dest}"
  chmod +x "${dest}"
  green "Installed ${name} hook to ${dest}"
}

install_hooks() {
  local -r git_repo="$1"
  local dest
  dest=$(determine_hook_path "commit-msg" "${git_repo}")
  install_hook "${dest}" "commit-msg" "_commit_msg_hook"
  dest=$(determine_hook_path "pre-commit" "${git_repo}")
  install_hook "${dest}" "pre-commit" "_pre_commit_hook"
  dest=$(determine_hook_path "prepare-commit-msg" "${git_repo}")
  install_hook "${dest}" "prepare-commit-msg" "_prepare_commit_msg_hook"
}

#######################################################################
# Dispatch to the appropriate functions
#######################################################################

# Show help if no options were provided.
[ $# -eq 0 ] && set -- -h

main() {
  case "$1" in
    -h) usage ;;
    -v) version && exit 0 ;;
    _commit_msg_hook) commit_msg_hook "$2" ;;
    _pre_commit_hook) pre_commit_hook ;;
    _prepare_commit_msg_hook) prepare_commit_msg_hook "$2" "$3" "$4" ;;
    scan)
      [ "$2" == "-h" ] && scan_usage
      scan "$2" "$3"
      ;;
    install)
      local git_repo_dir="$2"
      [ "${git_repo_dir}" == "-h" ] && install_usage
      [ -z "${git_repo_dir}" ] && git_repo_dir=$(git_repo_root)
      install_hooks "$git_repo_dir"
      ;;
    *) die "Unknown command '$1'" ;;
  esac
}

main "$@"
