#!/usr/bin/env bats
load test_helper

@test "Rejects commits with prohibited patterns in changeset" {
  setup_bad_repo
  repo_run git-secrets --install $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'Contents are bad not the message'
  [ $status -eq 1 ]
  [ "${lines[0]}" == "data.txt:1:@todo more stuff" ]
  [ "${lines[1]}" == "failure1.txt:1:another line... forbidden" ]
  [ "${lines[2]}" == "failure2.txt:1:me" ]
}

@test "Rejects commits with prohibited patterns in changeset with filename that contain spaces" {
  setup_bad_repo_with_spaces
  repo_run git-secrets --install $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'Contents are bad not the message'
  [ $status -eq 1 ]
  [ "${lines[0]}" == "da ta.txt:1:@todo more stuff" ]
}

@test "Scans staged files" {
  cd $TEST_REPO
  repo_run git-secrets --install $TEST_REPO
  echo '@todo more stuff' > $TEST_REPO/data.txt
  echo 'hi there' > $TEST_REPO/ok.txt
  git add -A
  echo 'fixed the working directory, but not staged' > $TEST_REPO/data.txt
  run git commit -m 'Contents are bad not the message'
  [ $status -eq 1 ]
  [ "${lines[0]}" == "data.txt:1:@todo more stuff" ]
}

@test "Allows commits that do not match prohibited patterns" {
  setup_good_repo
  repo_run git-secrets --install $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'This is fine'
  [ $status -eq 0 ]
  # Ensure deleted files are filtered out of the grep
  rm $TEST_REPO/data.txt
  echo 'aaa' > $TEST_REPO/data_2.txt
  run git add -A
  run git commit -m 'This is also fine'
  [ $status -eq 0 ]
}

@test "Rejects commits with prohibited patterns in changeset when AWS provider is enabled" {
  setup_bad_repo
  repo_run git-secrets --install $TEST_REPO
  repo_run git-secrets --register-aws $TEST_REPO
  cd $TEST_REPO
  run git commit -m 'Contents are bad not the message'
  [ $status -eq 1 ]
  echo "${lines}" | grep -vq 'git secrets --aws-provider: command not found'

  [ "${lines[0]}" == "data.txt:1:@todo more stuff" ]
  [ "${lines[1]}" == "failure1.txt:1:another line... forbidden" ]
  [ "${lines[2]}" == "failure2.txt:1:me" ]
}
