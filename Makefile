help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  test     to perform unit tests."

# We use bats for testing: https://github.com/sstephenson/bats
test:
	test/bats/bin/bats test/

# The man page is completely derived from README.rst. Edits to
# README.rst require a rebuild of the man page.
man:
	rst2man.py README.rst > git-secrets.1

.PHONY: help test man
