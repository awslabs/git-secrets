#!/usr/bin/env bats

load test_helper

@test "no arguments prints usage instructions" {
  repo_run git-secrets
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "usage: git secrets") -ne 0 ]
}

@test "-h prints help" {
  repo_run git-secrets -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "usage: git secrets") -ne 0 ]
}

@test "Invalid scan filename fails" {
  setup_repo && cd $TEST_REPO
  repo_run git-secrets scan -f /path/to/not/there
  [ $status -eq 1 ]
  echo "$output" | grep "File not found: /path/to/not/there"
}

@test "Does not require secres" {
  setup_repo && cd $TEST_REPO
  git config --unset-all secrets.pattern || true
  repo_run git-secrets scan -f $BATS_TEST_FILENAME
  [ $status -eq 0 ]
}

@test "No prohibited matches exits 0" {
  setup_repo && cd $TEST_REPO
  echo 'it is ok' > "$BATS_TMPDIR/test.txt"
  repo_run git-secrets scan -f "$BATS_TMPDIR/test.txt"
  [ $status -eq 0 ]
}

@test "Prohibited matches exits 1" {
  setup_repo && cd $TEST_REPO
  file="$TEST_REPO/test.txt"
  echo '@todo stuff' > $file
  echo 'this is forbidden right?' >> $file
  repo_run git-secrets scan -f $file
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
  repo_run git-secrets scan -f $file
  [ $status -eq 1 ]
  [ "${lines[0]}" == "$file:2:foo.me" ]
  [ "${lines[1]}" == "$file:3:\"me\"" ]
}

@test "Can scan from stdin using -" {
  setup_repo && cd $TEST_REPO
  echo "foo" | "${BATS_TEST_DIRNAME}/../git-secrets" scan -f -
  echo "me" | "${BATS_TEST_DIRNAME}/../git-secrets" scan -f - && exit 1 || true
}

@test "scan -h prints help" {
  repo_run git-secrets scan -h
  [ $(expr "${lines[0]}" : "usage: git secrets scan") -ne 0 ]
}

@test "install -h prints help" {
  repo_run git-secrets install -h
  [ $(expr "${lines[0]}" : "usage: git secrets install") -ne 0 ]
}

@test "installs hooks for repo" {
  repo_run install.sh
  setup_bad_repo
  repo_run git-secrets install -d $TEST_REPO
  [ -f $TEST_REPO/.git/hooks/pre-commit ]
  [ -f $TEST_REPO/.git/hooks/prepare-commit-msg ]
  [ -f $TEST_REPO/.git/hooks/commit-msg ]
  delete_repo
}

@test "installs hooks for repo with Debian style directories" {
  repo_run install.sh
  setup_bad_repo
  mkdir $TEST_REPO/.git/hooks/pre-commit.d
  mkdir $TEST_REPO/.git/hooks/prepare-commit-msg.d
  mkdir $TEST_REPO/.git/hooks/commit-msg.d
  repo_run git-secrets install -d $TEST_REPO
  [ -f $TEST_REPO/.git/hooks/pre-commit.d/git-secrets ]
  [ -f $TEST_REPO/.git/hooks/prepare-commit-msg.d/git-secrets ]
  [ -f $TEST_REPO/.git/hooks/commit-msg.d/git-secrets ]
  delete_repo
}
