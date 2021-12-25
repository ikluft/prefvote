#!/usr/bin/perl
# 003_prefvote_core_ballot.t - tests for PrefVote::Core::Ballot
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 16;
use Readonly;
use PrefVote::Core::Ballot;

# constants for test fixtures
Readonly::Array my @choices_af => qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS);
Readonly::Array my @ballot_tests => (
    {ballot => [qw(EVIL FACTIOUS DYSFUNCTIONAL CHAOTIC ABNORMAL BORING)], total => 6},
    {ballot => [qw(BORING DYSFUNCTIONAL CHAOTIC EVIL ABNORMAL)], total => 5},
);

# choices should start empty (1 test)
my @choice_test_empty = PrefVote::Core::Ballot::get_choices();
is(scalar @choice_test_empty, 0, "choices begin empty");

# instantiation tests (6 tests)
PrefVote::Core::Ballot::set_choices(qw(FOO BAR));
my @choice_test_foobar = PrefVote::Core::Ballot::get_choices();
is(scalar @choice_test_foobar, 2, "choices=2 for foo/bar test");
my @foobar_choices = qw(FOO BAR);
my $test_obj = PrefVote::Core::Ballot->new(items => \@foobar_choices, quantity => 1);
ok(defined $test_obj, "new(...) returned a defined value");
ok(ref $test_obj, "new(...) returned a reference");
isa_ok($test_obj, "PrefVote::Core::Ballot", "new(...) returned correct object");
is(@{$test_obj->items()}, @foobar_choices, "choices saved correctly");

# tests with fictitious A-F candidates (10 tests)
PrefVote::Core::Ballot::set_choices(@choices_af);
my @choice_test_af = PrefVote::Core::Ballot::get_choices();
is(scalar @choice_test_af, 6, "choices=6 for A-F test");
my $choices_ref = PrefVote::Core::Ballot::get_choices();
is(ref $choices_ref, "HASH", "get_choices as scalar returns hashref");
foreach my $test (@ballot_tests) {
    {
        my @summary;
        foreach my $item (@{$test->{ballot}}) {
            if (exists $choices_ref->{$item}) {
                push @summary, substr $item, 0, 1;
            } else {
                push @summary, $item;
            }
        }
        my $summary_str = join "-", @summary;

        my $ballot_obj = PrefVote::Core::Ballot->new(items => $test->{ballot}, quantity => 1);
        is_deeply($ballot_obj->items(), $test->{ballot}, "ballot $summary_str contents test");
        is($ballot_obj->total_items(), $test->{total}, "ballot $summary_str has test->{total} valid items");
        is($ballot_obj->quantity(), 1, "ballot $summary_str starts with quantity=1");
        $ballot_obj->increment();
        is($ballot_obj->quantity(), 2, "ballot $summary_str increments to quantity=2");
    }
}
