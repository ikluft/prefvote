#!/usr/bin/perl
# 001_rankedpairs_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
        PrefVote::RankedPairs
        );
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

