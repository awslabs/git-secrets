===========
git-secrets
===========

``git-secrets`` scans commits, commit messages, and merges to prevent adding
secrets into your git repositories. If a commit, commit message, or any commit
in a ``--no-ff`` merge history matches one of your configured
prohibited regular expression patterns, then the commit is rejected.


Installing
----------

First clone the repository. Then run the following command::

    ./install.sh

The ``install.sh`` script will perform the following actions:

1. Install a global ``git secrets`` git subcommand that can be used ad-hoc with
   any git project.
2. If you have not configured a ``git config --get git-secrets.file`` setting
   and the current user has an exported ``$HOME`` directory, the install script
   will create a default ``.git-secrets`` file in your ``$HOME`` directory with
   600 permissions and configure the file with ``git config --global``. This
   configuration setting can be overridden on a per/repo basis if needed. You
   can use this global secrets file to prohibit secret patterns from all of
   your repositories.

.. warning::

    1. You MUST install the git hooks for every repo that you wish to use with
       git-secrets.
    2. No global secrets file will be used if the result of calling
       ``git config --get git-secrets.file`` does not return a value.


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


Scanning file
-------------

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
regular expression patterns defined in the current git project's
``.git-secrets`` file (if available) and then scan the file using the globally
defined secrets file determined by using ``git config --get git-secrets.file``.

.. note::

    Please note that the installation script will automatically configure a
    global secrets file at ``$HOME/.git-secrets`` where ``$HOME`` is the
    current user's HOME directory. This will only be configured if the user has
    an exported ``$HOME`` directory and an existing ``git-secrets.file``
    configuration cannot be found. We recommend that this file have ``600``
    permissions in order to ensure that no other user can read it.


Defining prohibited patterns
----------------------------

Regular expressions are used to determine if a commit or commit message
contains any prohibited patterns. These regular expressions are defined in text
files, called *pattern files* that contain regular expressions separated by new
lines.

``git-secrets`` scans text using pattern files located in the ``.git-secrets``
file in the root of a git directory, and a global pattern file configured using
the ``git-secrets.file`` git config setting.

.. important::

    If neither a per-project pattern file or global pattern file file are
    found, then ``git secrets`` and any git hook that relies on it will not
    perform any kind of validation.

You can specify your secrets file location using the ``git-secrets.file`` git
configuration setting. Configurating a pattern file using git config will
augment any local repo pattern file.

.. code-block:: bash

    # To configurare a global git-secrets file
    git config --global git-secrets.file /path/to/global/.git-secrets
    # To configurare a global git-secrets file in your HOME directory
    git config --global git-secrets.file ~/.git-secrets

.. note::

    A per-project ``.git-secrets`` file is NOT used when scanning the actual
    ``.git-secrets`` file in a repo during the ``pre-commit`` git hook. This
    is to allow the local secrets file to be committed to the repo, but still
    ensure that the global ``~/.git-secrets`` patterns are utilized.

.. tip::

    Use the ``--no-verify`` option in the even of a false-positive match in a
    commit, merge, or commit message.


Example secrets file
~~~~~~~~~~~~~~~~~~~~

Here's an example ``~/.git-secrets`` file that uses PCRE regular expressions to
to to ensure that your AWS Access Key ID and Secret Access Key are not present
in any commit.

::

    (?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])
    =\s*("|'){0,1}(?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])("|'){0,1}

You could place the above contents into your globally configured pattern file
(typically ``~/.git-secrets``) to ensure that none of your git commits contain
your access keys, and you could still define per-project patterns by placing a
file in the ``.git-secrets`` file of your repo. Note: in order to limit the
number of false positives, the secret key pattern checks to see if it is
assigned to a value.

.. warning::

    If the secret terms mentioned in your pattern files are also secret, then
    you should not commit a ``.git-secrets`` file to your repository. Instead,
    rely upon a globally configured pattern file.


Testing
-------

Testing is done using ``make test``. Tests are executed using the
`bats <https://github.com/sstephenson/bats>`_ test runner for bash.
