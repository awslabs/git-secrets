#!/usr/bin/env bats
load test_helper

@test "Rejects merges with prohibited patterns in history" {
  setup_good_repo
  repo_run git-secrets --install $TEST_REPO
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
}

@test "Allows merges that do not match prohibited patterns" {
  setup_good_repo
  cd $TEST_REPO
  repo_run git-secrets --install
  git commit -m 'OK'
  git checkout -b feature
  echo 'Not bad' > data.txt
  git add -A
  git commit -m 'Good commit'
  git checkout master
  run git merge --no-ff feature
  [ $status -eq 0 ]
}

@test "Works with detached HEAD" {
  setup_good_repo
  repo_run git-secrets --install
  cd $TEST_REPO
  git commit -m 'OK'
  git checkout -b branchA
  echo "A" > a.txt
  git add -A
  git commit -m "Commit to branchA"
  git checkout -f $(git rev-parse master)
  run git merge --no-ff branchA
  [ -z "$( echo $output | grep fatal )" ]
}

@test "Rejects bad merge with detached HEAD" {
  setup_good_repo
  repo_run git-secrets --install $TEST_REPO
  cd $TEST_REPO
  git commit -m 'OK'
  git checkout -b feature
  echo '@todo' > data.txt
  git add -A
  git commit -m 'Bad commit' --no-verify
  echo 'Fixing!' > data.txt
  git add -A
  git commit -m 'Fixing commit'
  git checkout -f $(git rev-parse master)
  run git merge --no-ff feature
  [ $status -eq 1 ]
}
