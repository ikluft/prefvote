#!/usr/bin/perl
# 004_prefvote_core.t - tests for PrefVote::Core

use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 65;
use Test::Exception;
use File::Basename;
use Readonly;
use YAML::XS;
use PrefVote::Core;

# constants for test fixtures
Readonly::Hash my %core_params => (
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
Readonly::Array my @ballot_tests => (
    {ballot => [qw(EVIL FACTIOUS DYSFUNCTIONAL CHAOTIC ABNORMAL BORING)], total => 6, hex => '453201'},
    {ballot => [qw(BORING DYSFUNCTIONAL CHAOTIC EVIL ABNORMAL CTHULU)], total => 5, hex => '13240'},
    {ballot => [qw(CTHULU)], exception => "PrefVote::Core::Exception"},
);
Readonly::Scalar my $input_dir => "t/test-inputs/".basename($0, ".t");
Readonly::Scalar my $yaml_file => "test.yaml";
Readonly::Scalar my $yaml_ballot_count => 50;
Readonly::Scalar my $yaml_name => "Test Vote";
Readonly::Scalar my $yaml_seats => 1;
Readonly::Scalar my $yaml_extra => [{extra => "test data"}];

# basic instantiation tests (29 tests)
sub basic_tests
{
    # instantiate voting object (7 tests)
    # never instantiate PrefVote::Core directly except for testing - use a subclass which implements a voting method
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Core->instance(%core_params)}, "instantiate PrefVote::Core");
    ok(defined $vote_obj, "instance(core_params) returned a defined value");
    ok(ref $vote_obj, "instance(core_params) returned a reference");
    isa_ok($vote_obj, "PrefVote::Core", "instance(core_params) returned correct object");
    is($vote_obj->name(), $core_params{name}, "name attribute check");
    is($vote_obj->seats(), $core_params{seats}, "seats attribute check");
    is_deeply($vote_obj->choices(), $core_params{choices}, "choices hash attribute check");

    # test existence of valid choices (12 tests)
    foreach my $key (sort keys %{$core_params{choices}}) {
        ok(PrefVote::Core->choice_exists($key), "class->choice_exists($key) -> true");
        ok($vote_obj->choice_exists($key), "obj->choice_exists($key) -> true");
    }

    # test non-existence of invalid choices (8 tests)
    foreach my $bogus (qw(BOGUS FOO 1 0)) {
        ok(not (PrefVote::Core->choice_exists($bogus)), "class->choice_exists($bogus) -> false");
        ok(not ($vote_obj->choice_exists($bogus)), "obj->choice_exists($bogus) -> false");
    }

    # test get_choices (2 tests)
    is(PrefVote::Core->get_choices(), keys %{$vote_obj->{choices}}, "class->get_choices() test - basic");
    is($vote_obj->get_choices(), keys %{$vote_obj->{choices}}, "obj->get_choices() test - basic");

    return;
}

# ballot input tests (12 tests)
# no counting of ballots is done here because in the top-level class we don't have a voting method subclass to do that
sub ballot_tests
{
    # get the existing instance (3 tests)
    my $vote_obj = PrefVote::Core->instance();
    ok(defined $vote_obj, "instance() returned a defined value");
    ok(ref $vote_obj, "instance() returned a reference");
    isa_ok($vote_obj, "PrefVote::Core", "instance() returned correct object");

    # verify empty ballot box at start (1 test)
    is($vote_obj->total_ballots(), 0, "obj->total_ballots() = 0 initially");

    # run through array of ballot input tests (19 tests)
    foreach my $test (@ballot_tests) {
        my @summary;
        foreach my $item (@{$test->{ballot}}) {
            if ($vote_obj->choice_exists($item)) {
                push @summary, substr $item, 0, 1;
            } else {
                push @summary, $item;
            }
        }
        my $summary_str = join "-", @summary;
        if (exists $test->{exception}) {
            throws_ok( sub {$vote_obj->submit_ballot(@{$test->{ballot}}); }, $test->{exception},
                "ballot $summary_str -> exception $test->{exception} as expected");
        } else {
            my $combo;
            lives_ok(sub {$combo = $vote_obj->submit_ballot(@{$test->{ballot}}); }, "ballot $summary_str");
            my $hex_index = $vote_obj->ballot_to_hex(@{$test->{ballot}});
            is($hex_index, $test->{hex}, "computed hex_index $hex_index as expected");
            is($combo, $hex_index, "combo $combo from submit_ballot matches hex_index");
            my $ballot_obj = $vote_obj->{ballots}{$combo};
            ok(defined $ballot_obj, "ballot lookup returns data");
            isa_ok($ballot_obj, "PrefVote::Core::Ballot", "ballot lookup returns correct object");
            is($ballot_obj->quantity(), 1, "ballot quantity starts at 1");
            lives_ok(sub {$vote_obj->submit_ballot(@{$test->{ballot}}); }, "ballot $summary_str resubmit"); 
            is($ballot_obj->quantity(), 2, "ballot quantity increments to 2 after identical ballot");
            if (exists $test->{total}) {
                is($ballot_obj->items_count(), $test->{total},
                    "ballot $summary_str has $test->{total} valid items");
            }
        }
    }

    # verify all ballot objects contain a hex_id matching their hash key (2 tests)
    foreach my $key ($vote_obj->ballots_keys()) {
        is($key, $vote_obj->ballots_get($key)->hex_id(), "ballot hex_id $key matches its hash key");
    }

    # count ballots (1 test)
    is($vote_obj->total_ballots(), 4, "obj->total_ballots() = 4");
    return;
}

# YAML tests (10 tests)
sub yaml_tests
{
    # locate YAML file for this test
    if (! -d $input_dir) {
            BAIL_OUT("can't find test inputs directory: expected $input_dir");
    }
    my $yaml_path = $input_dir."/".$yaml_file;
    if ( not -e $yaml_path) {
            BAIL_OUT("can't find YAML test input $yaml_path");
    }

    # load YAML file (10 tests)
    my $vote_obj;
    lives_ok( sub{ $vote_obj = PrefVote::Core::yaml2vote($yaml_path); }, "process YAML file");
    ok(defined $vote_obj, "yaml2vote() returned a defined value");
    ok(ref $vote_obj, "yaml2vote() returned a reference");
    isa_ok($vote_obj, "PrefVote::Core", "yaml2vote() returned correct object");
    is(PrefVote::Core->get_choices(), keys %{$vote_obj->{choices}}, "class->get_choices() test - YAML");
    is($vote_obj->get_choices(), keys %{$vote_obj->{choices}}, "obj->get_choices() test - YAML");
    is($vote_obj->name(), $yaml_name, "attribute check: name");
    is($vote_obj->seats(), $yaml_seats, "attribute check: seats");
    is($vote_obj->total_ballots(), $yaml_ballot_count, "ballot total - YAML");
    is_deeply($vote_obj->extra(), $yaml_extra, "extra YAML docs saved in extra attribute - YAML");
    return;
}

# run tests
basic_tests();
ballot_tests();
yaml_tests();
