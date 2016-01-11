# CHANGELOG

## 1.0.1 - 2015-01-11

* Now works correctly with filenames in a repository that contain spaces when
  executing `git secrets --scan` with no provided filename (via `git grep`).
* Now works with git repositories with hundreds of thousands of files when
  using `git secrets --scan` with no provided filename (via `git grep`).

## 1.0.0 - 2015-12-10

* Initial release of ``git-secrets``.
