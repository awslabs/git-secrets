#!/bin/bash

export TEST_REPO="$BATS_TMPDIR/test-secrets"

# Deletes the test fixture repository
delete_repo() {
  rm -rf $TEST_REPO
}

# Creates a test fixture repository
setup_repo() {
  delete_repo
  # Create new git repo
  mkdir -p $TEST_REPO
  cd $TEST_REPO
  git init
  git config --local --add secrets.patterns '@todo'
  git config --local --add secrets.patterns 'forbidden|me'
  cd -
}

# Creates a repo that should fail
setup_bad_repo() {
  setup_repo
  echo '@todo more stuff' > $TEST_REPO/data.txt
  echo 'hi there' > $TEST_REPO/ok.txt
  echo 'another line... forbidden' > $TEST_REPO/failure1.txt
  echo 'me' > $TEST_REPO/failure2.txt
  cd $TEST_REPO && git add -A
  cd -
}

# Creates a repo that does not fail
setup_good_repo() {
  setup_repo
  echo 'hello!' > $TEST_REPO/data.txt
  cd $TEST_REPO && git add -A
  cd -
}

repo_run() {
  cmd=$1
  shift
  run "${BATS_TEST_DIRNAME}/../${cmd}" $@
}
