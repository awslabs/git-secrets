===========
git-secrets
===========

Prevents you from committing passwords and other sensitive information to a
git repository.


Synopsis
--------

::

    git secrets --install [-d | --dir <repo>]
    git secrets --scan <files>...


Description
-----------

``git-secrets`` scans commits, commit messages, and ``--no-ff`` merges to
prevent adding secrets into your git repositories. If a commit,
commit message, or any commit in a ``--no-ff`` merge history matches one of
your configured prohibited regular expression patterns, then the commit is
rejected.


Installing git-secrets
~~~~~~~~~~~~~~~~~~~~~~

It is recommended to run the ``install.sh`` script from the
`git-secrets <https://github.com/awslabs/git-secrets>`_ repository to install
``git-secrets``. ``install.sh`` will copy ``git-secrets`` to the appropriate
path (either ``/usr/local/bin`` or ``$(git --exec-path)``), and will ask you
through a series of prompts if you would like to seed you secrets configuration
with common secrets. This includes scanning for AWS credentials, AWS account
IDs, and other pieces of information found in your git config.

.. warning::

    You're not done yet! You MUST install the git hooks for every repo that
    you wish to use with ``git secrets --install``.


Options
-------

Operation Modes
~~~~~~~~~~~~~~~

Each of these options must appear first on the command line.

--install
    Installs hooks for a repository. Once the hooks are installed for a git
    repository, commits and non-ff merges for that repository will be prevented
    from committing secrets.

    Usage: ``git secrets --install [-d | --dir <repo>]``

--scan
    Scans one or more files for secrets. When a file contains a secret, the
    matched text from the file being scanned will be written to stdout and the
    script will exit with a non-zero RC. Each matched line will be written with
    the name of the file that matched, a colon, the line number that matched,
    a colon, and then the line of text that matched.

    Usage: ``git secrets --scan <files>...``


Options for ``--install``
~~~~~~~~~~~~~~~~~~~~~~~~~

-d, --dir
    When provided, installs git hooks to the given repository. The current
    directory is assumed if ``--dir`` is not provided.

    The following git hooks are installed:

    1. ``pre-commit``: Used to check if any of the files changed in the commit
       use prohibited patterns.
    2. ``commit-msg``: Used to determine if a commit message contains a
       prohibited patterns.
    3. ``prepare-commit-msg``: Used to determine if a merge commit will
       introduce a history that contains a prohibited pattern at any point.
       Please note that this hook is only invoked for non fast-forward merges.

    .. note::

        Git only allows a single script to be executed per hook. If the
        repository contains Debian style subdirectories like ``pre-commit.d``
        and ``commit-msg.d``, then the git hooks will be installed into these
        directories, which assumes that you've configured the corresponding
        hooks to execute all of the scripts found in these directories. If
        these git subdirectories are not present, then the git hooks will be
        installed to the git repo's ``.git/hooks`` directory, overwriting any
        previously configured hook. In the event that the hooks are
        overwritten, a warning will be written to stdout.


Examples
^^^^^^^^

Install git hooks to the current directory::

    cd /path/to/my/repository
    git secrets --install

Install git hooks to a repository other than the current directory::

    git secrets --install -d /path/to/my/repository


Options for ``--scan``
~~~~~~~~~~~~~~~~~~~~~~

<files>...
    The path to one or more files on disk to scan for secrets.


Examples
^^^^^^^^

Scans a file for secrets::

    git secrets --scan /path/to/file

Scans multiple files for secrets::

    git secrets --scan /path/to/file /path/to/other/file

You can scan by globbing::

    git secrets --scan /path/to/directory/*


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

::

    git config --add secrets.patterns 'my regex pattern'

You can list the patterns that have been configured using the following
command:

::

    git config --get-all secrets.patterns

Patterns will by default be added to the local git repository only. Use the
``--global`` option to add the pattern to your global list of prohibited
patterns:

::

    git config --global --add secrets.patterns 'my regex pattern'


Ignoring false-positives
------------------------

Sometimes a regular expression might match false positives. For example, git
commit SHAs look a lot like AWS access keys. You can specify many different
regular expression patterns as false positives using the following command:

::

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
    ``git secrets --scan $filename`` to ensure they are working as intended.

Example walkthrough
~~~~~~~~~~~~~~~~~~~

Let's take a look at an example. Given the following subject text (stored in
``/tmp/example``)::

    This is a test!
    password=ex@mplepassword
    password=******
    More test...

And the following registered ``secrets.patterns`` and ``secrets.allowed``:

::

    git config --add secrets.patterns 'password\s*=\s*.+'
    git config --add secrets.allowed 'ex@mplepassword'

Running ``git secrets --scan /tmp/example``, the result will
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

::

    git config --add secrets.allowed '/tmp/example:.*'
    git secrets --scan /tmp/example && echo $?
    # Outputs: 0

Alternatively, you could whitelist a specific line number of a file if that
line is unlikely to change using something like the following:

::

    git config --add secrets.allowed '/tmp/example:3:.*'
    git secrets --scan /tmp/example && echo $?
    # Outputs: 0

Keep this in mind when creating ``secrets.allowed`` patterns to ensure that
your allowed patterns are not inadvertantly matched due to the fact that the
filename is included in the subject text that allowed patterns are matched
against.

.. note::

    At the implementation level, we use ``grep`` to first extract matches, then
    a negative grep using the ``-v`` option to check if all of the extracted
    matches were filtered out by an allowed pattern.


Manually editing your git config
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You may find that it's easier to simply edit your git config file directly
rather than executing multiple ``git config --add`` commands from the command
line. You can edit a project's config file using the following command:

::

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


Skipping validation
-------------------

Use the ``--no-verify`` option in the event of a false-positive match in a
commit, merge, or commit message. This will skip the execution of the
git hook and allow you to make the commit or merge.


About
------

- Author: Michael Dowling <https://github.com/mtdowling>
- Issue tracker: This project's source code and issue tracker can be found at
  `https://github.com/awslabs/git-secrets <https://github.com/awslabs/git-secrets>`_
