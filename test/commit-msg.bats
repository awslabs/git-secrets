#!/usr/bin/env bats
load test_helper

@test "Rejects commit messages with prohibited patterns" {
  setup_good_repo
  repo_run git-secrets --install $TEST_REPO
  run git commit -m '@todo in the message??'
  [ $status -eq 1 ]
  [ "${lines[0]}" == ".git/COMMIT_EDITMSG:1:@todo in the message??" ]
}

@test "Allows commit messages that do not match a prohibited pattern" {
  setup_good_repo
  repo_run git-secrets --install $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'This is OK'
  [ $status -eq 0 ]
}
