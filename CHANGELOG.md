# CHANGELOG

## 1.3.0 - 2019-02-10

* Empty provider output is now excluded
  (https://github.com/awslabs/git-secrets/issues/34)
* Spaces are now supported in git exec path, making more Windows
  paths execute properly.
* Patterns with newlines and carriage returns are now loaded properly.
* Patterns that contain only "\n" are now ignored.
* Various Bash 4 fixes (https://github.com/awslabs/git-secrets/issues/66).
* Make IAM key scanning much more targeted.

## 1.2.1 - 2016-06-27

* Fixed an issue where secret provider commands were causing "command not
  found" errors due to a previously set IFS variable.
  https://github.com/awslabs/git-secrets/pull/30

## 1.2.0 - 2016-05-23

* Fixed an issue where spaces files with spaces in their names were not being
  properly scanned in the pre-commit hook.
* Now ignoring empty lines and comments (e.g., `#`) in the .gitallowed file.
* Fixed an issue where numbers were being compared to strings causing failures
  on some platforms.

## 1.1.0 - 2016-04-06

* Bug fix: the pre-commit hook previously only scanned the working directory
  rather than staged files. This release updates the pre-commit hook to instead
  scan staged files so that git-secrets will detect violations if the working
  directory drifts from the staging directory.
* Added the `--scan-history` subcommand so that you can scan your entire
  git history for violations.
* Added the ability to filter false positives by using a .gitallowed file.
* Added support for `--cached`, `--no-index`, and `--untracked` to the `--scan`
  subcommand.

## 1.0.1 - 2016-01-11

* Now works correctly with filenames in a repository that contain spaces when
  executing `git secrets --scan` with no provided filename (via `git grep`).
* Now works with git repositories with hundreds of thousands of files when
  using `git secrets --scan` with no provided filename (via `git grep`).

## 1.0.0 - 2015-12-10

* Initial release of ``git-secrets``.
