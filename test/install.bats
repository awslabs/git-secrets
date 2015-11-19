#!/usr/bin/env bats

load test_helper

@test "Installs git secrets" {
  run ./install.sh
  run git secrets
  [ $status -eq 0 ]
}

@test "Install -h" {
  run ./install.sh -h
  [ $(expr "${lines[0]}" : "usage: install.sh") -ne 0 ]
}
