#!/usr/bin/perl
# 001module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
        PrefVote
        PrefVote::Core::Ballot
        PrefVote::Core::Exception
        PrefVote::Core::InternalDataException
        PrefVote::Core::TestSpec
        PrefVote::Core
        PrefVote::Exception
        );
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

