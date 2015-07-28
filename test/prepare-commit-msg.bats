#!/usr/bin/env bats

load test_helper

@test "Rejects merges with prohibited patterns in history" {
  setup_good_repo
  ./install.sh
  ./git-secrets.sh install $TEST_REPO
  create_secrets
  cd $TEST_REPO
  git commit -m 'OK'
  git checkout -b feature
  echo '@todo' > data.txt
  git add -A
  git commit -m 'Bad commit' --no-verify
  echo 'Fixing!' > data.txt
  git add -A
  git commit -m 'Fixing commit'
  git checkout master
  run git merge --no-ff feature
  [ $status -eq 1 ]
  [ "${lines[0]}" == \
    "Checking if merging feature into master adds prohibited history" ]
  delete_repo
}

@test "Allows commits that do not match prohibited patterns" {
  setup_good_repo
  ./install.sh
  ./git-secrets.sh install $TEST_REPO
  create_secrets
  cd $TEST_REPO
  git commit -m 'OK'
  git checkout -b feature
  echo 'Not bad' > data.txt
  git add -A
  git commit -m 'Good commit'
  git checkout master
  run git merge --no-ff feature
  [ $status -eq 0 ]
  delete_repo
}
