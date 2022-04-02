#!/usr/bin/perl
# 003_core_ballot.t - tests for PrefVote::Core::Ballot
use Modern::Perl qw(2013); # require 5.16.0 or later
use autodie;
use Carp qw(croak);
use Test::More tests => 28;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core::Ballot;

# constants for test fixtures
Readonly::Array my @choices_af => qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS);
Readonly::Array my @ballot_tests => (
    {ballot => [qw(EVIL FACTIOUS DYSFUNCTIONAL CHAOTIC ABNORMAL BORING)], total => 6, hex => '453201'},
    {ballot => [qw(BORING DYSFUNCTIONAL CHAOTIC EVIL ABNORMAL)], total => 5, hex => '13240'},
    {ballot => [qw(BORING DYSFUNCTIONAL CHAOTIC/FACTIOUS EVIL ABNORMAL)], total => 6, hex => '13[25]40'},
    {ballot => [qw(BORING/DYSFUNCTIONAL CHAOTIC/FACTIOUS EVIL/ABNORMAL)], total => 6, hex => '[13][25][04]'},
    {ballot => [qw(BORING/DYSFUNCTIONAL/CHAOTIC/FACTIOUS/EVIL/ABNORMAL)], total => 6, hex => '[012345]'},
);

# convert an array to a set of ballot items
sub array2ballot
{
    my $array_ref = shift;
    (ref $array_ref eq "ARRAY")
        or croak "array2ballot expected array ref, got ".(ref $array_ref);
    my @ballot;
    foreach my $item (@$array_ref) {
        if (index($item, "/") != -1) {
            push @ballot, set(split( "/", $item));
        } else {
            push @ballot, set($item);
        }
    }
    return \@ballot;
}

# abbreviate expected candidate names to first letter for brevity of test titles (they're named for A,B,C,D,E,F)
sub summary_name
{
    my $choices_ref = shift;
    my $item = shift;
    my @summary;

    # abbreviate candidate names where possible within group-tie or singular ballot-item
    if (index($item, "/") != -1) {
        # group-tie entry
        foreach my $subitem (sort split "/", $item) {
            if (exists $choices_ref->{$subitem}) {
                # abbreviate known candidate
                push @summary, substr $subitem, 0, 1;
            } else {
                # use full identifier for unknown candidate
                push @summary, $subitem;
            }
        }
    } elsif (exists $choices_ref->{$item}) {
        # abbreviate known candidate
        push @summary, substr $item, 0, 1;
    } else {
        # use full identifier for unknown candidate
        push @summary, $item;
    }
    return join "/", @summary;
}

# choices should start empty (1 test)
my @choice_test_empty = PrefVote::Core::Ballot::get_choices();
is(scalar @choice_test_empty, 0, "choices begin empty");

# instantiation tests (6 tests)
PrefVote::Core::Ballot::set_choices(qw(FOO BAR));
my @choice_test_foobar = PrefVote::Core::Ballot::get_choices();
is(scalar @choice_test_foobar, 2, "choices=2 for foo/bar test");
my @foobar_choices = qw(FOO BAR);
my $test_obj = PrefVote::Core::Ballot->new(items => array2ballot(\@foobar_choices), quantity => 1, hex_id => '10');
ok(defined $test_obj, "new(...) returned a defined value");
ok(ref $test_obj, "new(...) returned a reference");
isa_ok($test_obj, "PrefVote::Core::Ballot", "new(...) returned correct object");
is_deeply($test_obj->items(), array2ballot(\@foobar_choices), "choices saved correctly");

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
            push @summary, summary_name($choices_ref, $item);
        }
        my $summary_str = join "-", @summary;

        my $ballot_obj = PrefVote::Core::Ballot->new(items => array2ballot($test->{ballot}), quantity => 1, hex_id => $test->{hex});
        is_deeply($ballot_obj->items(), array2ballot($test->{ballot}), "ballot $summary_str contents test");
        is($ballot_obj->items_count(), $test->{total}, "ballot $summary_str has test->{total} valid items");
        is($ballot_obj->quantity(), 1, "ballot $summary_str starts with quantity=1");
        $ballot_obj->increment();
        is($ballot_obj->quantity(), 2, "ballot $summary_str increments to quantity=2");
    }
}
