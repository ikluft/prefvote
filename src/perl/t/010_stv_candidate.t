#!/usr/bin/perl
# 010_stv_candidate.t - tests for PrefVote::STV::Candidate
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 21;
use Readonly;
use PrefVote::STV::Candidate;

# check type and default values (9 tests)
my $stv_cand_ref = PrefVote::STV::Candidate->new();
ok(defined $stv_cand_ref, "new(...) returned a defined value");
ok(ref $stv_cand_ref, "new(...) returned a reference");
isa_ok($stv_cand_ref, "PrefVote::STV::Candidate", "new(...) returned correct object");
is($stv_cand_ref->tally(), 0, "check default: tally = 0");
is($stv_cand_ref->winner(), 0, "check default: winner = 0");
is($stv_cand_ref->eliminated(), 0, "check default: eliminated = 0");
is($stv_cand_ref->place(), 0, "check default: place = 0");
is($stv_cand_ref->transfer(), 0, "check default: transfer = 0");
is($stv_cand_ref->surplus(), 0, "check default: surplus = 0");

# modify values via methods and check results (6 tests)
$stv_cand_ref->mark_as_winner(place => 1, tally => 42, surplus => 12, transfer => 10);
is($stv_cand_ref->winner(), 1, "winner: check winner = 1");
is($stv_cand_ref->place(), 1, "winner: check place = 1");
is($stv_cand_ref->tally(), 42, "winner: check tally = 42");
is($stv_cand_ref->surplus(), 12, "winner: check surplus = 12");
is($stv_cand_ref->transfer(), 10, "winner: check transfer = 10");
is($stv_cand_ref->eliminated(), 0, "winner: check eliminated = 0");

# make new object and test marking it eliminated (6 tests)
my $stv_cand_ref2 = PrefVote::STV::Candidate->new();
$stv_cand_ref2->mark_as_eliminated();
is($stv_cand_ref2->winner(), 0, "eliminated: check winner = 0");
is($stv_cand_ref2->place(), 0, "eliminated: check place = 0");
is($stv_cand_ref2->tally(), 0, "eliminated: check tally = 0");
is($stv_cand_ref2->surplus(), 0, "eliminated: check surplus = 0");
is($stv_cand_ref2->transfer(), 0, "eliminated: check transfer = 0");
is($stv_cand_ref2->eliminated(), 1, "eliminated: check eliminated = 1");
