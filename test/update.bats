#!/usr/bin/env bats
load test_helper

export TEST_REMOTE="$BATS_TMPDIR/test-remote.git"

setup_remote() {
  delete_remote
  mkdir -p $TEST_REMOTE
  cd $TEST_REMOTE
  git init --bare
  git config --local --add secrets.patterns '@todo'
  git config --local --add secrets.patterns 'forbidden|me'
  git config --local --add secrets.patterns '#hash'
  cat <<-SCRIPT >> hooks/update
#!/usr/bin/env bash
$(cd $BATS_TEST_DIRNAME/..; pwd)/git-secrets --update_hook -- "\$@"
SCRIPT
  chmod +x hooks/update
  cd -
}

delete_remote() {
  [ -d $TEST_REMOTE ] && rm -rf $TEST_REMOTE || true
}

alias_function() {
  eval "${1}() $(declare -f ${2} | sed 1d)"
}

alias_function _setup setup
setup() {
  _setup
  repo_run git config --unset-all secrets
  setup_remote
}

alias_function _teardown teardown
teardown() {
  _teardown
  delete_remote
}

@test "Pushes branch contained allowed words" {
  echo 'todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Create test.txt"
  run git push $TEST_REMOTE master
  [ $status -eq 0 ]
}

@test "fails to push branch contained secret words" {
  hashes=()

  echo '@todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Create test.txt"
  hashes+=( $(git rev-parse HEAD) )

  run git push $TEST_REMOTE master
  [ $status -eq 1 ]
  echo "$output" | grep -F "remote: ${hashes[0]}:test.txt:1:@todo"
}

@test "fails to push branch when secret words got mixed in a commit" {
  hashes=()

  cd $TEST_REPO
  echo 'todo'  > $TEST_REPO/test1.txt
  echo '@todo' > $TEST_REPO/test2.txt
  echo 'TODO'  > $TEST_REPO/test3.txt
  git add -A
  git commit -m "Create files"
  hashes+=( $(git rev-parse HEAD) )

  run git push $TEST_REMOTE master
  [ $status -eq 1 ]
  echo "$output" | grep -F "remote: ${hashes[0]}:test2.txt:1:@todo"
}

@test "fails to push branch even if secret words are fixed" {
  hashes=()

  cd $TEST_REPO
  echo 'todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Create test.txt"
  hashes+=( $(git rev-parse HEAD) )

  echo '@todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Update test.txt"
  hashes+=( $(git rev-parse HEAD) )

  echo 'todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Update test.txt"
  hashes+=( $(git rev-parse HEAD) )

  run git push $TEST_REMOTE master
  [ $status -eq 1 ]
  echo "$output" | grep -F "remote: ${hashes[1]}:test.txt:1:@todo"
}

@test "Pushes branch when secret words set as allowed patterns" {
  hashes=()

  cd $TEST_REMOTE
  git config --local --add secrets.allowed '@todo'

  cd $TEST_REPO
  echo 'todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Create test.txt"
  hashes+=( $(git rev-parse HEAD) )

  echo '@todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Update test.txt"
  hashes+=( $(git rev-parse HEAD) )

  echo 'todo' > $TEST_REPO/test.txt
  git add -A
  git commit -m "Update test.txt"
  hashes+=( $(git rev-parse HEAD) )

  run git push $TEST_REMOTE master
  [ $status -eq 0 ]
}
