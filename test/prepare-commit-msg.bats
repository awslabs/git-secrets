#!/usr/bin/env bats

load test_helper

@test "Rejects merges with prohibited patterns in history" {
  setup_good_repo
  repo_run install.sh
  repo_run git-secrets install -d $TEST_REPO
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

@test "Allows merges that do not match prohibited patterns" {
  setup_good_repo
  repo_run install.sh
  cd $TEST_REPO
  repo_run git-secrets install
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
