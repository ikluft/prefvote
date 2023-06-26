#!/usr/bin/perl
# 011_stv_result.t - tests for PrefVote::Core::Result
use strict;
use warnings;
use autodie;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
use Readonly;
use PrefVote::Core;
use PrefVote::Core::Result;
use Set::Tiny qw(set);

# debugging
BEGIN {
    if (PrefVote->debug()) {
        $Data::Dumper::Sortkeys = 1;
        $Data::Dumper::Indent = 1;
    }
}

# constants for test fixtures
Readonly::Array my @candidates => qw(ABOMINABLE BRAT);

# new() constructor expected failures (5 tests)
my $result_ref;
dies_ok( sub { $result_ref = PrefVote::Core::Result->new()},
    "new() no params - dies as expected");
dies_ok( sub { $result_ref = PrefVote::Core::Result->new(name => set(@candidates))},
    "new() missing type - dies as expected");
dies_ok( sub { $result_ref = PrefVote::Core::Result->new(type => "winner")},
    "new() missing name - dies as expected");
dies_ok( sub { $result_ref = PrefVote::Core::Result->new(name => "ABOMINABLE", type => "winner")},
    "new() name not array - dies as expected");
dies_ok( sub { $result_ref = PrefVote::Core::Result->new(name => set(@candidates), type => "foo")},
    "new() bad type value - dies as expected");

# constructor success and accessor verification (5 tests)
lives_ok( sub { $result_ref = PrefVote::Core::Result->new(name => set(@candidates), type => "winner")},
    "new() type = winner");
is($result_ref->type(), "winner", "accessor confirms type == winner");
is_deeply($result_ref->name(), set(@candidates), "accessor confirms name");
lives_ok( sub { $result_ref = PrefVote::Core::Result->new(name => set(@candidates), type => "eliminated")},
    "new() type = eliminated");
is($result_ref->type(), "eliminated", "accessor confirms type == eliminated");
