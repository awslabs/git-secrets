#!/usr/bin/env bats

load test_helper

@test "no arguments prints usage instructions" {
  repo_run git-secrets.sh
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "git-secrets ") -ne 0 ]
  [ $(expr "${lines[1]}" : "Usage:") -ne 0 ]
}

@test "-h prints help" {
  repo_run git-secrets.sh -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "git-secrets ") -ne 0 ]
  [ $(expr "${lines[1]}" : "Usage:") -ne 0 ]
}

@test "-v prints version" {
  repo_run git-secrets.sh -v
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "git-secrets ") -ne 0 ]
}

@test "Invalid scan filename fails" {
  setup_repo && cd $TEST_REPO
  repo_run git-secrets.sh scan /path/to/not/there
  [ $status -eq 1 ]
  echo "$output" | grep "File not found: /path/to/not/there"
}

@test "Warns if secrets are not present" {
  setup_repo && cd $TEST_REPO
  git config --unset-all secrets.pattern || true
  repo_run git-secrets.sh scan $BATS_TEST_FILENAME
  [ $status -eq 0 ]
  echo "$output" | grep "No prohibited patterns have been defined"
}

@test "No prohibited matches exits 0" {
  setup_repo && cd $TEST_REPO
  echo 'it is ok' > "$BATS_TMPDIR/test.txt"
  repo_run git-secrets.sh scan "$BATS_TMPDIR/test.txt"
  [ $status -eq 0 ]
}

@test "Prohibited matches exits 1" {
  setup_repo && cd $TEST_REPO
  file="$TEST_REPO/test.txt"
  echo '@todo stuff' > $file
  echo 'this is forbidden right?' >> $file
  git config --get-all secrets.pattern > /tmp/patterns
  repo_run git-secrets.sh scan $file
  [ $status -eq 1 ]
  [ "${lines[0]}" == "$file:1:@todo stuff" ]
  [ "${lines[1]}" == "$file:2:this is forbidden right?" ]
}

@test "Only matches on word boundaries" {
  setup_repo && cd $TEST_REPO
  file="$TEST_REPO/test.txt"
  # Note that the following does not match as it is not a word.
  echo 'mesa Jar Jar Binks' > $file
  # The following do match because they are in word boundaries.
  echo 'foo.me' >> $file
  echo '"me"' >> $file
  repo_run git-secrets.sh scan $file
  [ $status -eq 1 ]
  [ "${lines[0]}" == "$file:2:foo.me" ]
  [ "${lines[1]}" == "$file:3:\"me\"" ]
}

@test "Can scan from stdin using -" {
  executable="${BATS_TEST_DIRNAME}/../git-secrets.sh scan -"
  setup_repo && cd $TEST_REPO
  echo "foo" | $executable
  echo "me" | $executable && exit 1 || true
}

@test "scan -h prints help" {
  repo_run git-secrets.sh scan -h
  [ $status -eq 0 ]
  [ "${lines[0]}" == "Usage: git secrets scan [<options>] <filename>" ]
}

@test "install -h prints help" {
  repo_run git-secrets.sh install -h
  [ $status -eq 0 ]
  [ "${lines[0]}" == "Usage: git secrets install [<options>] <repo>" ]
}

@test "installs hooks for repo" {
  ./install.sh
  setup_bad_repo
  repo_run git-secrets.sh install $TEST_REPO
  [ -f $TEST_REPO/.git/hooks/pre-commit ]
  [ -f $TEST_REPO/.git/hooks/prepare-commit-msg ]
  [ -f $TEST_REPO/.git/hooks/commit-msg ]
  delete_repo
}

@test "installs hooks for repo with Debian style directories" {
  ./install.sh
  setup_bad_repo
  mkdir $TEST_REPO/.git/hooks/pre-commit.d
  mkdir $TEST_REPO/.git/hooks/prepare-commit-msg.d
  mkdir $TEST_REPO/.git/hooks/commit-msg.d
  repo_run git-secrets.sh install $TEST_REPO
  [ -f $TEST_REPO/.git/hooks/pre-commit.d/git-secrets ]
  [ -f $TEST_REPO/.git/hooks/prepare-commit-msg.d/git-secrets ]
  [ -f $TEST_REPO/.git/hooks/commit-msg.d/git-secrets ]
  delete_repo
}
