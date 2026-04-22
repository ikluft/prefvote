#!/usr/bin/perl
# 001_kr2_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
    PrefVote::KR2
    PrefVote::KR2::Output
    PrefVote::KR2::PairData
);
plan tests => scalar @classes;

foreach my $class (@classes) {
    require_ok($class);
}

1;
