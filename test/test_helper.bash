#!/bin/bash

TEST_REPO="$BATS_TMPDIR/test-secrets"
TMP_SECRETS="$BATS_TMPDIR/.git-secrets"
REPO_TMP_SECRETS="$TEST_REPO/.git-secrets"

# Creates a simple secrets file
create_secrets() {
  dest=$TMP_SECRETS
  [ $1 -eq 1 ] && dest=$REPO_TMP_SECRETS
  echo "@todo" > "$dest"
  echo "forbidden|me" >> "$dest"
  chmod 600 $dest
}

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
  cd -
}

# Creates a repo that should fail
setup_bad_repo() {
  setup_repo
  create_secrets 1
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
  create_secrets 1
  echo 'hello!' > $TEST_REPO/data.txt
  cd $TEST_REPO && git add -A
  cd -
}
