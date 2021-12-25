#!/usr/bin/perl
# 013_stv.t - tests for PrefVote::STV
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 43;
use Test::Exception;
use Readonly;
use PrefVote::STV;

# constants for test fixtures
Readonly::Hash my %stv_params => (
    name => "Test Vote",
    seats => 1,
    choices => {
        ABNORMAL => "abnormal and antisocial",
        BORING => "boring as anything",
        CHAOTIC => "chaotic unpredictable",
        DYSFUNCTIONAL => "dysfunctional incompetent",
        EVIL => "evil villain",
        FACTIOUS => "factious/divisive candidate",
    },
);


# basic instantiation tests (19 tests)
sub basic_tests
{
    # instantiate voting object (7 tests)
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::STV->instance(%stv_params)}, "instantiate PrefVote::STV");
    ok(defined $vote_obj, "instance(core_params) returned a defined value");
    ok(ref $vote_obj, "instance(core_params) returned a reference");
    isa_ok($vote_obj, "PrefVote::STV", "instance(core_params) returned correct object");
    is($vote_obj->name(), $stv_params{name}, "name attribute check");
    is($vote_obj->seats(), $stv_params{seats}, "seats attribute check");
    is_deeply($vote_obj->choices(), $stv_params{choices}, "choices hash attribute check");
    
    # test PrefVote::STV attributes start out empty (12 tests)
    isa_ok($vote_obj->{winners}, "ARRAY", "attribute: winners is an array ref - direct access");
    isa_ok($vote_obj->winners(), "ARRAY", "attribute: winners is an array ref - method access");
    is(scalar @{$vote_obj->winners()}, 0, "attribute: winners is empty - method access");
    isa_ok($vote_obj->{eliminated}, "ARRAY", "attribute: eliminated is an array ref - direct access");
    isa_ok($vote_obj->eliminated(), "ARRAY", "attribute: eliminated is an array ref - method access");
    is(scalar @{$vote_obj->eliminated()}, 0, "attribute: eliminated is empty - method access");
    isa_ok($vote_obj->{rounds}, "ARRAY", "attribute: rounds is an array ref - direct access");
    isa_ok($vote_obj->rounds(), "ARRAY", "attribute: rounds is an array ref - method access");
    is(scalar @{$vote_obj->rounds()}, 0, "attribute: rounds is empty - method access");
    isa_ok($vote_obj->{candidates}, "HASH", "attribute: candidates is a hash ref - direct access");
    isa_ok($vote_obj->candidates(), "HASH", "attribute: candidates is a hash ref - method access");
    is(scalar keys %{$vote_obj->candidates()}, 0, "attribute: candidates is empty - method access");
}

# test functions
sub func_tests
{
    # init_candidates (21 tests)
    my $vote_obj = PrefVote::STV->instance(%stv_params);
    lives_ok(sub {$vote_obj->init_candidates()}, "init_candidates() - no exception");
    isa_ok($vote_obj->{candidates}, "HASH", "candidates attribute is a HASH ref");
    is(scalar keys %{$vote_obj->{candidates}}, scalar keys %{$stv_params{choices}},
        "init_candidates: correct number of candidates");
    foreach my $name (keys %{$stv_params{choices}}) {
        ok(exists $vote_obj->{candidates}{$name}, "init_candidates: $name entry exists");
        isa_ok($vote_obj->{candidates}{$name}, 'PrefVote::STV::Candidate', "init_candidates: $name ref");
        is($vote_obj->{candidates}{$name}{name}, $name, "init_candidates: $name entry contains its own name");
    }

    # new_round and clear_candidate_tallies (3 tests)
    is(scalar @{$vote_obj->{rounds}}, 0, "rounds begins empty");
    lives_ok(sub {$vote_obj->new_round()}, "new_round() - no exception");
    is(scalar @{$vote_obj->{rounds}}, 1, "rounds got 1 entry");
    
}

# run tests
basic_tests();
func_tests();
