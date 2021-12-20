#!/usr/bin/perl
# 004_prefvote_core.t - tests for PrefVote::Core

use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 50;
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
    {ballot => [qw(EVIL FACTIOUS DYSFUNCTIONAL CHAOTIC ABNORMAL BORING)], total => 6},
    {ballot => [qw(BORING DYSFUNCTIONAL CHAOTIC EVIL ABNORMAL CTHULU)], total => 5},
    {ballot => [qw(CTHULU)], exception => "PrefVote::Core::Exception"},
);
Readonly::Scalar my $input_dir => "t/test-inputs/".basename($0, ".t");
Readonly::Scalar my $yaml_file => "test.yaml";
Readonly::Scalar my $yaml_ballot_count => 50;
Readonly::Scalar my $yaml_name => "Test Vote";
Readonly::Scalar my $yaml_seats => 1;
Readonly::Scalar my $yaml_extra => [{extra => "test data"}];

# basic instantiation tests (28 tests)
sub basic_tests
{
    # instantiate voting object (6 tests)
    # never instantiate PrefVote::Core directly except for testing - use a subclass which implements a voting method
    my $vote_obj = PrefVote::Core->instance(%core_params);
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

    # verify empty ballot box at start (2 tests)
    is(PrefVote::Core->total_ballots(), 0, "class->total_ballots() = 0 initially");
    is($vote_obj->total_ballots(), 0, "obj->total_ballots() = 0 initially");

    # run through array of ballot input tests (5 tests)
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
            lives_ok(sub {$vote_obj->submit_ballot(@{$test->{ballot}}); }, "ballot $summary_str"); 
            if (exists $test->{total}) {
                is($vote_obj->{ballots}[-1]->total_items(), $test->{total},
                    "ballot $summary_str has $test->{total} valid items");
            }
        }
    }

    # count ballots (2 tests)
    is(PrefVote::Core->total_ballots(), 2, "class->total_ballots() = 2");
    is($vote_obj->total_ballots(), 2, "obj->total_ballots() = 2");
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
