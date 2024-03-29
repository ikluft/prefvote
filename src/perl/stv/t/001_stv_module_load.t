#!/usr/bin/perl
# 001_stv_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
    PrefVote::STV
    PrefVote::STV::Output
    PrefVote::STV::Round
    PrefVote::STV::Tally
);
plan tests => scalar @classes;

foreach my $class (@classes) {
    require_ok($class);
}

1;

