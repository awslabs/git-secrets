#!/usr/bin/env bats

load test_helper

@test "Installs git secrets" {
  run ./install.sh
  run git secrets -h
  [ $status -eq 0 ]
}
