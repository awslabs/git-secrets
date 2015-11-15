===========
git-secrets
===========

``git-secrets`` prevents you from committing passwords and other sensitive
information to a git repository.

``git-secrets`` scans commits, commit messages, and ``--no-ff`` merges to
prevent adding secrets into your git repositories. If a commit,
commit message, or any commit in a ``--no-ff`` merge history matches one of
your configured prohibited regular expression patterns, then the commit is
rejected.


Installing
----------

First clone the repository. Then run the following command::

    ./install.sh

The ``install.sh`` script will perform the following actions:

1. Install the git-secrets command to your PATH.
2. Configure the appropriate command to use for grep.

.. warning::

    You MUST install the git hooks for every repo that you wish to use with
    git-secrets.


Installing git hooks for a repository
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can install ``pre-commit``, ``commit-msg``, and ``prepare-commit-msg``
hooks to a repository to ensure that prohibited words or patterns never make it
into the repository. This can be done by running the ``git secrets install``
command while inside of a git repository.

::

    cd /path/to/git/repo
    git secrets install

You can also provide the path to the repository as a positional argument.

::

    git secrets install /path/to/git/repo

``git-secrets`` installs several hooks:

1. ``pre-commit``: Used to check if any of the files changed in the commit
   use prohibited patterns.
2. ``commit-msg``: Used to determine if a commit message contains a prohibited
   patterns.
3. ``prepare-commit-msg``: Used to determine if a merge commit will introduce
   a history that contains a prohibited pattern at any point. Please note that
   this hook is only invoked for non fast-forward merges.


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


Scanning files
--------------

In addition to using hooks to automatically scan, you can scan files and text
ad-hoc using the ``git secrets scan`` command directly (for example, this might
be useful for testing your configured patterns).

The ``git-secrets scan`` command accepts the path to a file to check and will
report if any of the prohibited matches are found in the file.

::

    $ git secrets scan path/to/file
    $ echo $?
    > 0

``git secrets scan`` will first scan the given file for any of the prohibited
regular expression patterns defined by the result of
``git config --get-all secrets.patterns``.


Defining prohibited patterns
----------------------------

``egrep`` compatible Regular expressions are used to determine if a commit or
commit message contains any prohibited patterns. These regular expressions are
defined using the ``git config`` command.

You can add prohibited regular expression patterns to your git config by
running the following command:

.. code-block:: bash

    git config --add secrets.pattern 'my regex pattern'

You can list the patterns that have been configured using the following
command:

.. code-block:: bash

    git config --get-all secrets.pattern

Patterns will by default be added to the local git repository only. Use the
``--global`` option to add the pattern to your global list of prohibited
patterns:

.. code-block:: bash

    git config --global --add secrets.pattern 'my regex pattern'

You may find that it's easier to simply edit your git config file directly
rather than executing multiple ``git config --add`` commands from the command
line. The git configuration file is typically found in a git repository at
``.git/config``. Simply add a new ini section called "secrets" and place each
prohibited regular expression pattern on a new line using
``pattern=<regex>``. For example::

    [secrets]
        pattern = foo
        pattern = bar
        pattern = baz


Skipping validation
-------------------

Use the ``--no-verify`` option in the event of a false-positive match in a
commit, merge, or commit message. This will skip the execution of the
git hook and allow you to make the commit or merge.


Testing
-------

Testing is done using ``make test``. Tests are executed using the
`bats <https://github.com/sstephenson/bats>`_ test runner for bash.
