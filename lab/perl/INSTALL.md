# Installing PrefVote for Perl

These instructions must be applied in all the perl module source code directories you with to run.
All of them are needed to run the test suite.

## building from Git repository

* Get the current source code by cloning the Git repository from https://github.com/ikluft/prefvote
* Make sure Perl5 is installed on your system, at least version 5.24. 5.40 or above is recommended.
* Make sure you can install local Perl modules without root - see https://metacpan.org/pod/local::lib
* Install Dist::Zilla. See https:://dzil.org/ for info.
* Install author build dependencies with the command "dzil authordeps --missing | cpanm"
* Install build dependencies with the command "dzil listdeps --missing | cpanm"
* build/test/install commands:
  * dzil build
  * dzil test
  * dzil install
