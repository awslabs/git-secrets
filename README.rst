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

1. Install the ``git-secrets`` command to your PATH.
2. Ask if you want to install a number of pre-configured prohibited patterns.
3. Ask if you want to import known credentials from ``~/.aws/credentials`` as
   prohibited.
4. Ensure that it was installed correctly.

.. warning::

    You're not done yet! You MUST install the git hooks for every repo that
    you wish to use with ``git secrets install``.


Installing git hooks for a repository
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can install ``pre-commit``, ``commit-msg``, and ``prepare-commit-msg``
hooks to a repository to ensure that prohibited words or patterns never make it
into the repository. This can be done by running the ``git secrets install``
command while inside of a git repository.

.. code-block:: bash

    cd /path/to/git/repo
    git secrets install

You can also provide the path to the repository using the ``--dir`` option.

.. code-block:: bash

    git secrets install --dir /path/to/git/repo

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


Skipping validation
^^^^^^^^^^^^^^^^^^^

Use the ``--no-verify`` option in the event of a false-positive match in a
commit, merge, or commit message. This will skip the execution of the
git hook and allow you to make the commit or merge.


Scanning files
--------------

In addition to using hooks to automatically scan, you can scan files and text
ad-hoc using the ``git secrets scan`` command directly (for example, this might
be useful for testing your configured patterns).

The ``git-secrets scan`` command accepts the path to a file to check and will
report if any of the prohibited matches are found in the file.

.. code-block:: bash

    $ git secrets scan -f path/to/file
    $ echo $?
    > 0

``git secrets scan`` will first scan the given file for any of the prohibited
regular expression patterns defined by the result of
``git config --get-all secrets.patterns``.


Defining prohibited patterns
----------------------------

egrep compatible regular expressions are used to determine if a commit or
commit message contains any prohibited patterns. These regular expressions are
defined using the ``git config`` command.

It is important to note that different systems use different versions of egrep.
For example, when running on OS X, you will use a different version of egrep
than when running on something like Ubuntu (BSD vs GNU). You can customize
which egrep is used by ``git-secrets`` if these slight differences change the
behavior of your regular expressions. The ``secrets.grep`` git configuration
setting specifies the grep command to use. You must include any arguments
leading up to but not including the patterns and filename when configuring a
custom grep setting (for example, ``gegrep -nwH`` could be used to utilize
the egrep installed by running ``brew install grep``).

.. note::

    You can run the ``install.sh`` script at any time to add a number of
    pre-configured patterns to your list of prohibited regular expressions,
    including AWS access keys and known AWS credentials stored in
    ``~/.aws/credentials``.

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


Manually editing git config
~~~~~~~~~~~~~~~~~~~~~~~~~~~

You may find that it's easier to simply edit your git config file directly
rather than executing multiple ``git config --add`` commands from the command
line. You can edit a project's config file using the following command:

.. code-block:: bash

    git config -e

Simply add a new ini section called "secrets" and place each prohibited
regular expression line using ``pattern=<regex>``. For example, your git
config might look something like this::

    [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
        ignorecase = true
        precomposeunicode = true
    [remote "origin"]
        url = git@github.com:foo/bar
        fetch = +refs/heads/*:refs/remotes/origin/*
    [secrets]
        pattern = username=.+
        pattern = password=.+
        pattern = [A-Z0-9]{20}
        pattern = (\"|')?(AWS_|aws_)?(SECRET|secret)(_ACCESS|_access)?_(KEY|key)(\"|')?\\s*(=|:|=>)\\s*(\"|')?[A-Za-z0-9/\\+=]{40}(\"|')?
        pattern = (\"|')?(AWS_|aws_)?(ACCOUNT|account)(_ID|_id)?(\"|')?\\s*(=|:|=>)\\s*(\"|')?[0-9]{4}\\-?[0-9]{4}\\-?[0-9]{4}(\"|')?

More information on git configuration can be found in the
`git documentation <https://git-scm.com/docs/git-config>`_.


Testing
-------

Testing is done using ``make test``. Tests are executed using the
`bats <https://github.com/sstephenson/bats>`_ test runner for bash.
