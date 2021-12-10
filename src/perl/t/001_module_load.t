#!/usr/bin/perl
# 001module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
        PrefVote
        PrefVote::Core::Ballot
        PrefVote::Core
        PrefVote::STV
        PrefVote::STV::Round
        PrefVote::STV::Candidate
        PrefVote::STV::Result
        );
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

