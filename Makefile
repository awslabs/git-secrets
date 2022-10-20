PREFIX ?= /usr/local
MANPREFIX ?= "${PREFIX}/share/man/man1"

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  test     to perform unit tests."
	@echo "  man      to build the man file from README.rst"
	@echo "  install  to install. Use PREFIX and MANPREFIX to customize."

generate_script:
	@./inject_version.sh

# We use bats for testing: https://github.com/sstephenson/bats
test: generate_script
	LANG=C test/bats/bin/bats test/

# The man page is completely derived from README.rst. Edits to
# README.rst require a rebuild of the man page.
man:
	rst2man.py README.rst > git-secrets.1

install: generate_script
	@mkdir -p ${DESTDIR}${MANPREFIX}
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f git-secrets ${DESTDIR}${PREFIX}/bin
	@cp -f git-secrets.1 ${DESTDIR}${MANPREFIX}

.PHONY: help generate_script test man
