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

First clone the repository. Then run the following command:

.. code-block:: bash

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
``git config --get-all secrets.patternss``.


Defining prohibited patterns
----------------------------

egrep compatible regular expressions are used to determine if a commit or
commit message contains any prohibited patterns. These regular expressions are
defined using the ``git config`` command. It is important to note that
different systems use different versions of egrep. For example, when running on
OS X, you will use a different version of egrep than when running on something
like Ubuntu (BSD vs GNU).

.. note::

    You can run the ``install.sh`` script at any time to add a number of
    pre-configured patterns to your list of prohibited regular expressions,
    including AWS access keys and known AWS credentials stored in
    ``~/.aws/credentials``.

You can add prohibited regular expression patterns to your git config by
running the following command:

.. code-block:: bash

    git config --add secrets.patterns 'my regex pattern'

You can list the patterns that have been configured using the following
command:

.. code-block:: bash

    git config --get-all secrets.patterns

Patterns will by default be added to the local git repository only. Use the
``--global`` option to add the pattern to your global list of prohibited
patterns:

.. code-block:: bash

    git config --global --add secrets.patterns 'my regex pattern'


Ignoring false-positives
~~~~~~~~~~~~~~~~~~~~~~~~

Sometimes a regular expression might match false positives. For example, git
commit SHAs look a lot like AWS access keys. You can specify many different
regular expression patterns as false positives using the following command:

.. code-block:: bash

    git config --add secrets.allowed 'my regex pattern'

First, git-secrets will extract all lines from a file that contain a prohibited
match. Included in the matched results will be the full path to the name of
the file that was matched, followed ':', followed by the line number that was
matched, followed by the entire line from the file that was matched by a secret
pattern. Then, if you've defined ``secrets.allowed`` regular expressions,
git-secrets will check to see if all of the matched lines match at least one of
your registered ``secrets.allowed`` regular expressions. If all of the lines
that were flagged as secret are canceled out by an allowed match, then the
subject text does not contain any secrets. If any of the matched lines are not
matched by an allowed regular expression, then git-secrets will fail the
commit/merge/message.

.. important::

    Just as it is a bad practice to add ``secrets.patterns`` that are too
    greedy, it is also a bad practice to add ``secrets.allowed`` patterns that
    are too forgiving. Be sure to test out your patterns using ad-hoc calls to
    ``git secrets scan -f $filename`` to ensure they are working as intended.

Let's take a look at an example. Given the following subject text (stored in
``/tmp/example``)::

    This is a test!
    password=ex@mplepassword
    password=******
    More test...

And the following registered ``secrets.patterns`` and ``secrets.allowed``:

.. code-block:: bash

    git config --add secrets.patterns 'password\s*=\s*.+'
    git config --add secrets.allowed 'ex@mplepassword'

Running ``git secrets scan -f /tmp/example``, the result will
result in the following error output::

    /tmp/example:3:password=******

    [ERROR] Matched prohibited pattern

    Possible mitigations:

    - Mark false positives as allowed using: git config --add secrets.allowed ...
    - List your configured patterns: git config --get-all secrets.patterns
    - List your configured allowed patterns: git config --get-all secrets.allowed
    - Use --no-verify if this is a one-time false positive

Breaking this down, the ``secrets.patterns`` value of ``password\s*=\s*.+``
will match the following lines::

    /tmp/example:2:password=ex@mplepassword
    /tmp/example:3:password=******

...But the first match will be filtered out due to the fact that it matches the
``secrets.allowed`` regular expression of ``ex@mplepassword``. Because
there is still a remaining line that did not match, it is considered a secret.

Because that matching lines are placed on lines that start with the filename
and line number (e.g., ``/tmp/example:3:...``), you can create
``secrets.allowed`` patterns that take filenames and line numbers into account
in the regular expression. For example, you could whitelist an entire file
using something like:

.. code-block:: bash

    git config --add secrets.allowed '/tmp/example:.*'
    git secrets scan -f /tmp/example && echo $? # Outputs: 0

Alternatively, you could whitelist a specific line number of a file if that
line is unlikely to change using something like the following:

.. code-block:: bash

    git config --add secrets.allowed '/tmp/example:3:.*'
    git secrets scan -f /tmp/example && echo $? # Outputs: 0

Keep this in mind when creating ``secrets.allowed`` patterns to ensure that
your allowed patterns are not inadvertantly matched due to the fact that the
filename is included in the subject text that allowed patterns are matched
against.

.. note::

    At the implementation level, we use ``grep`` to first extract matches, then
    a negative grep using the ``-v`` option to check if all of the extracted
    matches were filtered out by an allowed pattern.


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
        patterns = [A-Z0-9]{20}
        patterns = (\"|')?(AWS_|aws_)?(SECRET|secret)(_ACCESS|_access)?_(KEY|key)(\"|')?\\s*(=|:|=>)\\s*(\"|')?[A-Za-z0-9/\\+=]{40}(\"|')?
        patterns = (\"|')?(AWS_|aws_)?(ACCOUNT|account)(_ID|_id)?(\"|')?\\s*(=|:|=>)\\s*(\"|')?[0-9]{4}\\-?[0-9]{4}\\-?[0-9]{4}(\"|')?
        ; AWS example key
        allowed = AKIAIOSFODNN7EXAMPLE
        ; AWS example secret key
        allowed = wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY

More information on git configuration can be found in the
`git documentation <https://git-scm.com/docs/git-config>`_.


Testing
-------

Testing is done using ``make test``. Tests are executed using the
`bats <https://github.com/sstephenson/bats>`_ test runner for bash.
