#!/usr/bin/perl
# 013_stv.t - tests for PrefVote::STV
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 19;
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

# run tests
basic_tests();
