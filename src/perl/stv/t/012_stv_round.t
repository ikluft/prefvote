#!/usr/bin/perl
# 012_stv_round.t - tests for PrefVote::STV::Round
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 54;
use Test::Exception;
use Readonly;
use PrefVote::Core;
use PrefVote::STV::Round;

# constants for test fixtures
Readonly::Array my @candidate_names => (qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS));
Readonly::Array my @set_result_tests => (
    {name => [qw(ABNORMAL)], type => 'winner', description => '1 winner'},
    {name => [qw(BORING)], type => 'eliminated', description => '1 eliminated'},
    {name => [qw(CHAOTIC DYSFUNCTIONAL)], type => 'winner', description => '2 winner'},
    {name => [qw(EVIL FACTIOUS)], type => 'eliminated', description => '1 eliminated'},
    {name => [qw(ABOMINABLE)], exception => 'PrefVote::STV::Round::TypeMissingException',
        description => 'TypeMissingException as expected'},
    {type => 'eliminated', exception => 'PrefVote::STV::Round::NameMissingException',
        description => 'NameMissingException as expected'},
    {name => 'ABOMINABLE', type => 'eliminated', exception => 'PrefVote::STV::Round::NameNotArrayException',
        description => 'scalar -> NameNotArrayException as expected'},
    {name => sub{ return "foo" }, type => 'eliminated', exception => 'PrefVote::STV::Round::NameNotArrayException',
        description => 'CODE -> NameNotArrayException as expected'},
    {name => [qw(ABOMINABLE)], type => 'eliminated', exception => 'PrefVote::STV::Round::InvalidCandidateException',
        description => 'InvalidCandidateException as expected'},
);

# check type and default values (11 tests)
my $stv_round_ref;
dies_ok(sub {$stv_round_ref = PrefVote::STV::Round->new()}, "instantiate without minimal params -> dies");
lives_ok(sub {$stv_round_ref = PrefVote::STV::Round->new(number => 1)},
    "instantiate with minimal params -> no exception");
ok(defined $stv_round_ref, "new() returned a defined value");
ok(ref $stv_round_ref, "new() returned a reference");
isa_ok($stv_round_ref, "PrefVote::STV::Round", "new() returned correct object");
is($stv_round_ref->number(), 1, "number was set to 1");
is($stv_round_ref->prev(), undef, "prev is undef as expected");
is($stv_round_ref->votes_used(), 0, "default: votes_used = 0");
is_deeply($stv_round_ref->candidates(), [], "default: candidates list is empty");
is($stv_round_ref->quota(), 0, "default: quota = 0");
throws_ok(sub {$stv_round_ref->init_candidate_tally()}, "PrefVote::STV::Round::PrevMissingException",
    "init_candidate_tally() missing candidate data");

# test init_candidate_tally (4 tests)
my $stv_round_ref2;
lives_ok(sub {$stv_round_ref2 = PrefVote::STV::Round->new(number => 1,
    candidates => Readonly::Clone @candidate_names)}, "instantiate with candidates -> no exception");
lives_ok(sub {$stv_round_ref2->init_candidate_tally()}, "init_candidate_tally() with candidates -> no exception");
is_deeply($stv_round_ref2->candidates(), \@candidate_names, "candidate list contains correct data");
is($stv_round_ref->prev(), undef, "prev is undef as expected");

# test add_votes_used() (5 tests)
lives_ok(sub {$stv_round_ref2->add_votes_used(10)}, "add_votes_used(10) -> no exception");
is($stv_round_ref2->votes_used(), 10, "votes_used = 10");
lives_ok(sub {$stv_round_ref2->add_votes_used(10)}, "add_votes_used(10) again -> no exception");
is($stv_round_ref2->votes_used(), 20, "votes_used = 20");
throws_ok(sub {$stv_round_ref2->add_votes_used(-10)}, 'PrefVote::STV::Round::NegativeIncrementException',
    "add_votes_used(-10) -> throws NegativeIncrementException as expected");

# test sort_candidates() (5 tests)
# the sorting function needs to be in the context of sort() called within PrefVote::STV::Round package
lives_ok( sub{$stv_round_ref2->sort_candidates(sub{ return $_[1] cmp $_[0] })},
    "sort descending -> no exception");
is_deeply($stv_round_ref2->{candidates}, [reverse @candidate_names], "candidates in reversed order");
lives_ok( sub{$stv_round_ref2->sort_candidates(sub{ return $_[0] cmp $_[1] })},
    "sort ascending -> no exception");
is_deeply($stv_round_ref2->{candidates}, \@candidate_names, "candidates in original order");
throws_ok( sub{$stv_round_ref2->sort_candidates(0)}, 'PrefVote::STV::Round::BadSortingFnException',
    "bad sort function -> throws BadSortingFnException as expected");

# test set_result() (25 tests)
foreach my $test (@set_result_tests) {
    my $round_ref = PrefVote::STV::Round->new(number => 2, prev => $stv_round_ref2);
    if (exists $test->{exception}) {
        # expected exception test
        throws_ok( sub {$round_ref->set_result(
            (exists $test->{name} ? (name => $test->{name}) : ()),
            (exists $test->{type} ? (type => $test->{type}) : ()))},
            $test->{exception}, $test->{description});
    } else {
        # test with no expected exception
        lives_ok(sub {$round_ref->init_candidate_tally()}, "init_candidate_tally() -> no exception");
        lives_ok(sub {$round_ref->set_result(
            (exists $test->{name} ? (name => $test->{name}) : ()),
            (exists $test->{type} ? (type => $test->{type}) : ()))},
            $test->{description}." - no exception");
        is($round_ref->{result}{type}, $test->{type}, $test->{description}." - type");
        ok($round_ref->{result}{name}->contains(@{$test->{name}}), $test->{description}." - name");
        isa_ok($round_ref->{prev}, "PrefVote::STV::Round", "prev points to a round");
        is($round_ref->{prev}, $stv_round_ref2, "prev points to the round that was given to it");
    }
}
