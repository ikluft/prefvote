#!/usr/bin/perl
# 001module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
        PrefVote::STV
        PrefVote::STV::Round
        PrefVote::STV::Tally
        PrefVote::STV::Result
        );
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

