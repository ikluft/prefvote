#!/usr/bin/perl
# 021_schulze_round.t - tests for PrefVote::Schulze::Round
use strict;
use warnings;
use autodie;
use Test::More tests => 37;
use Test::Exception;
use Readonly;
use PrefVote::Core;
use PrefVote::Schulze::Round;

# constants for test fixtures
Readonly::Array my @candidate_names => (qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS));

# check type and default values (9 tests)
my $schulze_round_ref;
dies_ok( sub { $schulze_round_ref  = PrefVote::Schulze::Round->new() }, "instantiate without minimal params -> dies" );
lives_ok( sub { $schulze_round_ref = PrefVote::Schulze::Round->new( number => 1 ) },
    "instantiate with minimal params -> no exception" );
ok( defined $schulze_round_ref, "new() returned a defined value" );
ok( ref $schulze_round_ref,     "new() returned a reference" );
isa_ok( $schulze_round_ref, "PrefVote::Schulze::Round", "new() returned correct object" );
is( $schulze_round_ref->number(), 1,     "number was set to 1" );
is( $schulze_round_ref->prev(),   undef, "prev is undef as expected" );
is_deeply( $schulze_round_ref->candidates(), [], "default: candidates list is empty" );
is_deeply( $schulze_round_ref->pair(),       {}, "default: pair hash is empty" );

# test init_round_candidates() (4 tests)
my $schulze_round_ref2;
lives_ok(
    sub {
        $schulze_round_ref2 = PrefVote::Schulze::Round->new(
            number     => 1,
            candidates => Readonly::Clone @candidate_names
        )
    },
    "instantiate with candidates -> no exception"
);
lives_ok( sub { $schulze_round_ref2->init_round_candidates() },
    "init_round_candidates() with candidates -> no exception" );
is_deeply( $schulze_round_ref2->candidates(), \@candidate_names, "candidate list contains correct data" );
is( $schulze_round_ref->prev(), undef, "prev is undef as expected" );

# test pair data matrix methods (24 tests)

# check empty table (3 tests)
is( $schulze_round_ref->get_preference( "ABNORMAL", "FACTIOUS" ), 0, "get_preference returns zero on empty table" );
is( $schulze_round_ref->get_win_order( "ABNORMAL", "FACTIOUS" ),  0, "get_win_order returns zero on empty table" );
is_deeply( $schulze_round_ref->pair(), {}, "pair hash still empty after read access" );

# check preference and initial creation of a PairData node (8 tests)
is( $schulze_round_ref->add_preference( "ABNORMAL", "FACTIOUS", 1 ),
    1, "add_preference(ABNORMAL,FACTIOUS, 1) returns 1" );
is_deeply( keys %{ $schulze_round_ref->{pair} },           qw(ABNORMAL), "pair keys are: ABNORMAL" );
is_deeply( keys %{ $schulze_round_ref->{pair}{ABNORMAL} }, qw(FACTIOUS), "pair{ABNORMAL} keys are: FACTIOUS" );
isa_ok( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}, "PrefVote::Schulze::PairData", "pair{ABNORMAL}{FACTIOUS}" );
is( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}->preference(), 1, "pair{ABNORMAL}{FACTIOUS}->preference is 1" );
is( $schulze_round_ref->get_preference( "ABNORMAL", "FACTIOUS" ), 1, "get_preference(ABNORMAL,FACTIOUS) returns 1" );
is( $schulze_round_ref->add_preference( "ABNORMAL", "FACTIOUS", 2 ),
    3, "add_preference(ABNORMAL,FACTIOUS, 2) returns 3" );
is( $schulze_round_ref->get_preference( "ABNORMAL", "FACTIOUS" ), 3, "get_preference(ABNORMAL,FACTIOUS) returns 3" );

# check predecessor (4 tests)
is( $schulze_round_ref->get_predecessor( "ABNORMAL", "FACTIOUS" ),
    "ABNORMAL", "default get_predecessor(ABNORMAL,FACTIOUS) returns ABNORMAL" );
is( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}->predecessor(),
    "ABNORMAL", "pair{ABNORMAL}{FACTIOUS}->predecessor is ABNORMAL" );
is( $schulze_round_ref->set_predecessor( "ABNORMAL", "FACTIOUS", "CHAOTIC" ),
    "CHAOTIC", "set_predecessor(ABNORMAL,FACTIOUS,CHAOTIC) returns CHAOTIC" );
is( $schulze_round_ref->get_predecessor( "ABNORMAL", "FACTIOUS" ),
    "CHAOTIC", "get_predecessor(ABNORMAL,FACTIOUS) returns CHAOTIC" );

# check strength (3 tests)
is( $schulze_round_ref->set_strength( "ABNORMAL", "FACTIOUS", 10 ),
    10, "set_strength(ABNORMAL,FACTIOUS, 10) returns 10" );
is( $schulze_round_ref->get_strength( "ABNORMAL", "FACTIOUS" ), 10, "get_strength(ABNORMAL,FACTIOUS) returns 10" );
is( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}->strength(), 10, "pair{ABNORMAL}{FACTIOUS}->strength is 10" );

# check win_order (6 tests)
is( $schulze_round_ref->set_win_order( "ABNORMAL", "FACTIOUS", 0 ), 0,
    "set_win_order(ABNORMAL,FACTIOUS, 0) returns 0" );
is( $schulze_round_ref->get_win_order( "ABNORMAL", "FACTIOUS" ), 0, "get_win_order(ABNORMAL,FACTIOUS) returns 0" );
is( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}->win_order(), 0, "pair{ABNORMAL}{FACTIOUS}->win_order is 0" );
is( $schulze_round_ref->set_win_order( "ABNORMAL", "FACTIOUS", 1 ), 1,
    "set_win_order(ABNORMAL,FACTIOUS, 1) returns 1" );
is( $schulze_round_ref->get_win_order( "ABNORMAL", "FACTIOUS" ), 1, "get_win_order(ABNORMAL,FACTIOUS) returns 1" );
is( $schulze_round_ref->{pair}{ABNORMAL}{FACTIOUS}->win_order(), 1, "pair{ABNORMAL}{FACTIOUS}->win_order is 1" );

# TODO: add unit tests for round processing - for now consider this covered by blackbox tests
