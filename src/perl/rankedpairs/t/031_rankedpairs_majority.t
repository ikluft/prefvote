#!/usr/bin/perl
# 031_rankedpairs_majority.t - tests for PrefVote::RankedPairs::Majority
use strict;
use warnings;
use autodie;
use Test::More tests => 6;
use Test::Exception;
use Readonly;
use PrefVote::RankedPairs;
use PrefVote::RankedPairs::Majority;
use Set::Tiny qw(set);

# test data
Readonly::Array my @pair => (qw(foo bar));

# check type and default values (6 tests)
my $majority_ref;
dies_ok( sub { $majority_ref = PrefVote::RankedPairs::Majority->new() }, "Majorioty->new() dies as expected");
lives_ok( sub { $majority_ref = PrefVote::RankedPairs::Majority->new(cand => \@pair) },
    "Majority->new(pair) succeeds");
my @majority_elements = $majority_ref->cand_all();
is(scalar @majority_elements, 2, "got 2 elements from cand_all()");
is($majority_elements[0], $pair[0], "element 0 = ".$pair[0]);
is($majority_elements[1], $pair[1], "element 1 = ".$pair[1]);
is($majority_ref->stringify(), join(">",@pair), "Majority->stringify() = ".join(">",@pair));
