help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  test     to perform unit tests."

test:
	vendor/bats/bin/bats test/

.PHONY: help test
