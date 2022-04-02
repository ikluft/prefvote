#!/usr/bin/perl
# 010_stv_tally.t - tests for PrefVote::STV::Tally
use Modern::Perl qw(2013); # require 5.16.0 or later
use autodie;
use Test::More tests => 23;
use Readonly;
use PrefVote::STV::Tally;

# check type and default values (10 tests)
my $stv_tally_ref = PrefVote::STV::Tally->new(name => 'test1');
ok(defined $stv_tally_ref, "new() returned a defined value");
ok(ref $stv_tally_ref, "new() returned a reference");
isa_ok($stv_tally_ref, "PrefVote::STV::Tally", "new() returned correct object");
is($stv_tally_ref->name(), "test1", "default: name = test1");
is($stv_tally_ref->votes(), 0, "default: votes = 0");
is($stv_tally_ref->winner(), 0, "default: winner = 0");
is($stv_tally_ref->eliminated(), 0, "default: eliminated = 0");
is($stv_tally_ref->place(), undef, "default: place = undef");
is($stv_tally_ref->transfer(), undef, "default: transfer = undef");
is($stv_tally_ref->surplus(), undef, "default: surplus = undef");

# modify values via methods and check results (6 tests)
# Except for booleans, these numbers are made-up. The only significance is the test reads back the same number.
$stv_tally_ref->mark_as_winner(place => 1, votes => 42, surplus => 12, transfer => 10);
is($stv_tally_ref->winner(), 1, "winner: check winner = 1");
is($stv_tally_ref->place(), 1, "winner: check place = 1");
is($stv_tally_ref->votes(), 42, "winner: check votes = 42");
is($stv_tally_ref->surplus(), 12, "winner: check surplus = 12");
is($stv_tally_ref->transfer(), 10, "winner: check transfer = 10");
is($stv_tally_ref->eliminated(), 0, "winner: check eliminated = 0");

# make new object and test marking it eliminated (7 tests)
my $stv_tally_ref2 = PrefVote::STV::Tally->new(name => 'test2');
$stv_tally_ref2->mark_as_eliminated();
is($stv_tally_ref2->name(), "test2", "default: name = test2");
is($stv_tally_ref2->winner(), 0, "eliminated: check winner = 0");
is($stv_tally_ref2->votes(), 0, "eliminated: check votes = 0");
is($stv_tally_ref2->place(), undef, "eliminated: check place = undef");
is($stv_tally_ref2->surplus(), undef, "eliminated: check surplus = undef");
is($stv_tally_ref2->transfer(), undef, "eliminated: check transfer = undef");
is($stv_tally_ref2->eliminated(), 1, "eliminated: check eliminated = 1");
