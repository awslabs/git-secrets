===========
git-secrets
===========

``git-secrets`` scans commits and commit messages for secret words and secret
patterns. If the commit or message matches one of the patterns in the
``.git-secrets`` file of a git repository or your globally defined secrets file
at ``~/.git-secrets``, then the commit is rejected.


Installing
----------

First clone the repository. Then run the following command::

    ./install.sh

The ``install.sh`` script will install a global ``git secrets`` git subcommand
that can be used ad-hoc with any git project. The command accepts the path to a
file to check and will report if any of the prohibited matches are found in the
file.

::

    $ git secrets scan path/to/file
    $ echo $?
    > 0

``git secrets scan`` will first scan the given file for any of the prohibited
regular expression patterns defined in the current git project's
``.git-secrets`` file and then scan the file using the globally defined secrets
file located at ``~/.git-secrets``. If neither of these *pattern files* can be
found, then ``git secrets`` will fail with exit code ``1``.


Installing git hooks for a project
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can install pre-commit, commit-msg, and prepare-commit-msg hooks to a
repository to ensure that prohibited words or patterns never make it into the
repository. This can be done by running the ``git secrets install`` command
while inside of a git repository.

::

    cd /path/to/git/repo
    git secrets install

You can also provide the path to the repository as a positional argument.

::

    git secrets install /path/to/git/repo

This project installs several hooks:

1. ``pre-commit``: Used to check if any of the files changed in the commit
   use prohibited patterns.
2. ``commit-msg``: Used to determine if a commit message contains a prohibited
   patterns.
3. ``prepare-commit-msg``: Used to determine if a merge commit will introduce
   a history that contains a prohibited pattern at any point.


Debian style directories
^^^^^^^^^^^^^^^^^^^^^^^^

Git only allows a single script to be executed per hook. If the repository
contains Debian style subdirectories like ``pre-commit.d`` and
``commit-msg.d``, then the git hooks will be installed into these directories,
which assumes that you've configured the corresponding hooks to execute all of
the scripts found in these directories. If these git subdirectories are not
present, then the git hooks will be installed to the git repo's ``.git/hooks``
directory, overwriting any previously configured hook. In the event that the
hooks are overwritten, a warning will be written to stdout.


Defining prohibited patterns
----------------------------

Regular expressions are used to determine if a commit or commit message
contains any prohibited patterns. These regular expressions are defined in text
files, called *pattern files* that contain regular expressions separated by new
lines.

git-secrets scans text using pattern files located in the ``.git-secrets`` file
in the root of a git directory, and a global ``~/.git-secrets`` file. If
neither a per-project ``.git-secrets`` or global ``~/.git-secrets`` file are
found, then ``git secrets`` and any git hook that relies on it will fail until
one is created.

.. note::

    A per-project ``.git-secrets`` file is NOT used when scanning the actual
    ``.git-secrets`` file in a repo during the ``pre-commit`` git hook. This
    is to allow the local secrets file to be committed to the repo, but still
    ensure that global ``~/.git-secrets`` or secrets found in the
    ``GIT_SECRETS_FILE`` environement variable are not present in the local
    ``.git-secrets`` file.


Example secrets file
~~~~~~~~~~~~~~~~~~~~

Here's an example ``~/.git-secrets`` file that uses PCRE regular expressions to
ensure that your AWS Access Key ID and Secret Access Key are not present in any
commit.

::

    (?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])
    =\s*("|'){0,1}(?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])("|'){0,1}

You could place the above contents into ``~/.git-secrets`` to ensure that none
of your git commits contain your access keys, and you could still define
per-project patterns by placing a file in the ``.git-secrets`` file of your
repo. Note: the secret key pattern checks to see if it is assigned to a value.

.. warning::

    If the secret terms mentioned in your pattern files are also secret, then
    you should not commit a .git-secrets file to your repository. Instead, rely
    upon the global ``~/.git-secrets`` file or use the ``GIT_SECRETS_FILE``
    environement variable to define the path to a pattern file on disk.


Testing
-------

Testing is done using ``make test``. Tests are executed using the
`bats <https://github.com/sstephenson/bats>`_ test runner for bash.
