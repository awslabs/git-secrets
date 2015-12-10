#!/bin/bash
export TEST_REPO="$BATS_TMPDIR/test-repo"
export TEMPLATE_DIR="${BATS_TMPDIR}/template"
INITIAL_PATH="${PATH}"

setup() {
  setup_repo
  [ -d "${TEMPLATE_DIR}" ] && rm -rf "${TEMPLATE_DIR}"
  export PATH="${BATS_TEST_DIRNAME}/..:${INITIAL_PATH}"
  cd $TEST_REPO
}

teardown() {
  delete_repo
  export PATH="${INITIAL_PATH}"
}

delete_repo() {
  [ -d $TEST_REPO ] && rm -rf $TEST_REPO || true
}

setup_repo() {
  delete_repo
  mkdir -p $TEST_REPO
  cd $TEST_REPO
  git init
  git config --local --add secrets.patterns '@todo'
  git config --local --add secrets.patterns 'forbidden|me'
  cd -
}

repo_run() {
  cmd="$1"
  shift
  cd "${TEST_REPO}"
  run "${BATS_TEST_DIRNAME}/../${cmd}" $@
  cd -
}

# Creates a repo that should fail
setup_bad_repo() {
  cd $TEST_REPO
  echo '@todo more stuff' > $TEST_REPO/data.txt
  echo 'hi there' > $TEST_REPO/ok.txt
  echo 'another line... forbidden' > $TEST_REPO/failure1.txt
  echo 'me' > $TEST_REPO/failure2.txt
  git add -A
  cd -
}

# Creates a repo that does not fail
setup_good_repo() {
  cd $TEST_REPO
  echo 'hello!' > $TEST_REPO/data.txt
  git add -A
  cd -
}
