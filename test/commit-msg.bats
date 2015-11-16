#!/usr/bin/env bats

load test_helper

@test "Rejects commit messages with prohibited patterns" {
  repo_run install.sh
  setup_good_repo
  repo_run git-secrets install -d $TEST_REPO
  cd $TEST_REPO
  run git commit -m '@todo in the message??'
  [ $status -eq 1 ]
  [ "${lines[0]}" == ".git/COMMIT_EDITMSG:1:@todo in the message??" ]
  delete_repo
}

@test "Allows commit messages that do not match a prohibited pattern" {
  repo_run install.sh
  setup_good_repo
  repo_run git-secrets install -d $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'This is OK'
  [ $status -eq 0 ]
  delete_repo
}
