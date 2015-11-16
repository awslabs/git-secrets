#!/usr/bin/env bats

load test_helper

@test "Rejects commits with prohibited patterns in changeset" {
  repo_run install.sh
  setup_bad_repo
  repo_run git-secrets install -d $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'Contents are bad not the message'
  [ $status -eq 1 ]
  [ "${lines[0]}" == "data.txt:1:@todo more stuff" ]
  [ "${lines[1]}" == "failure1.txt:1:another line... forbidden" ]
  [ "${lines[2]}" == "failure2.txt:1:me" ]
  delete_repo
}

@test "Allows commits that do not match prohibited patterns" {
  repo_run install.sh
  setup_good_repo
  repo_run git-secrets install -d $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'This is fine'
  [ $status -eq 0 ]
  delete_repo
}
