PREFIX ?= /usr/local
MANPREFIX ?= "${PREFIX}/share/man/man1"

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  test     to perform unit tests."
	@echo "  man      to build the man file from README.rst"
	@echo "  install  to install. Use PREFIX and MANPREFIX to customize."

# We use bats-core for testing: https://github.com/bats-core/bats-core
test: test/bats-core/bin/bats
	@LANG=C test/bats-core/bin/bats test/

test/bats-core/bin/bats:
	@git submodule init test/bats-core
	@git submodule update test/bats-core

# The man page is completely derived from README.rst. Edits to
# README.rst require a rebuild of the man page.
man:
	@rst2man.py README.rst > git-secrets.1

install:
	@mkdir -p ${DESTDIR}${MANPREFIX}
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f git-secrets ${DESTDIR}${PREFIX}/bin
	@cp -f git-secrets.1 ${DESTDIR}${MANPREFIX}

.PHONY: help test man
