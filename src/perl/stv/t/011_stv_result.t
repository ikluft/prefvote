#!/usr/bin/perl
# 011_stv_result.t - tests for PrefVote::STV::Result
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 10;
use Test::Exception;
use Readonly;
use PrefVote::Core;
use PrefVote::STV::Result;

# constants for test fixtures
Readonly::Array my @candidates => qw(ABOMINABLE);

# new() constructor expected failures (5 tests)
my $result_ref;
dies_ok( sub { $result_ref = PrefVote::STV::Result->new()},
    "new() no params - dies as expected");
dies_ok( sub { $result_ref = PrefVote::STV::Result->new(name => \@candidates)},
    "new() missing type - dies as expected");
dies_ok( sub { $result_ref = PrefVote::STV::Result->new(type => "winner")},
    "new() missing name - dies as expected");
dies_ok( sub { $result_ref = PrefVote::STV::Result->new(name => "ABOMINABLE", type => "winner")},
    "new() name not array - dies as expected");
dies_ok( sub { $result_ref = PrefVote::STV::Result->new(name => \@candidates, type => "foo")},
    "new() bad type value - dies as expected");

# constructor success and accessor verification (5 tests)
lives_ok( sub { $result_ref = PrefVote::STV::Result->new(name => \@candidates, type => "winner")},
    "new() type = winner");
is($result_ref->type(), "winner", "accessor confirms type == winner");
is_deeply($result_ref->name(), \@candidates, "accessor confirms name");
lives_ok( sub { $result_ref = PrefVote::STV::Result->new(name => \@candidates, type => "eliminated")},
    "new() type = eliminated");
is($result_ref->type(), "eliminated", "accessor confirms type == eliminated");
