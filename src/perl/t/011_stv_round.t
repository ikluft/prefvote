#!/usr/bin/perl
# 011_stv_round.t - tests for PrefVote::STV::Round
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 46;
use Test::Exception;
use Readonly;
use PrefVote::Core;
use PrefVote::STV::Round;

# constants for test fixtures
Readonly::Array my @add_candidate_tests => (qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS));
Readonly::Array my @set_result_tests => (
    {name => [qw(ABNORMAL)], type => 'winner', description => '1 winner'},
    {name => [qw(BORING)], type => 'eliminated', description => '1 eliminated'},
    {name => [qw(CHAOTIC DYSFUNCTIONAL)], type => 'winner', description => '2 winner'},
    {name => [qw(EVIL FACTIOUS)], type => 'eliminated', description => '1 eliminated'},
    {name => [qw(ABOMINABLE)], exception => 'PrefVote::STV::Round::TypeMissingException',
        description => 'missing type parameter exception as expected'},
    {type => 'eliminated', exception => 'PrefVote::STV::Round::NameMissingException',
        description => 'missing name parameter exception as expected'},
    {name => 'ABOMINABLE', type => 'eliminated', exception => 'PrefVote::STV::Round::NameNotArrayException',
        description => 'invalid scalar name parameter exception as expected'},
    {name => sub{ return "foo" }, type => 'eliminated', exception => 'PrefVote::STV::Round::NameNotArrayException',
        description => 'invalid CODE name parameter exception as expected'},
    {name => [qw(ABOMINABLE)], type => 'eliminated', exception => 'PrefVote::STV::Round::InvalidCandidateException',
        description => 'invalid candidate exception as expected'},
);

# check type and default values (6 tests)
my $stv_round_ref = PrefVote::STV::Round->new();
ok(defined $stv_round_ref, "new() returned a defined value");
ok(ref $stv_round_ref, "new() returned a reference");
isa_ok($stv_round_ref, "PrefVote::STV::Round", "new() returned correct object");
is($stv_round_ref->votes_used(), 0, "default: votes_used = 0");
is_deeply($stv_round_ref->candidates(), [], "default: candidates list is empty");
is($stv_round_ref->quota(), 0, "default: quota = 0");

# test add_candidates() (13 tests)
for (my $i=0; $i < scalar @add_candidate_tests; $i++) {
    my $cand_name = $add_candidate_tests[$i];
    $stv_round_ref->add_candidate($cand_name);
    is($stv_round_ref->{candidates}[-1], $cand_name, "added candidate ".$cand_name);
    is(scalar @{$stv_round_ref->{candidates}}, $i+1, "result has ".($i+1)." items");
}
is_deeply($stv_round_ref->{candidates}, \@add_candidate_tests, "full candidate list");

# test add_votes_used() (5 tests)
lives_ok(sub {$stv_round_ref->add_votes_used(10)}, "add_votes_used(10) -> no exception");
is($stv_round_ref->votes_used(), 10, "votes_used = 10");
lives_ok(sub {$stv_round_ref->add_votes_used(10)}, "add_votes_used(10) again -> no exception");
is($stv_round_ref->votes_used(), 20, "votes_used = 20");
throws_ok(sub {$stv_round_ref->add_votes_used(-10)}, 'PrefVote::STV::Round::NegativeIncrementException',
    "add_votes_used(-10) -> throws NegativeIncrementException as expected");

# test sort_candidates() (5 tests)
# the sorting function needs to be in the context of sort() called within PrefVote::STV::Round package
lives_ok( sub{$stv_round_ref->sort_candidates(sub{ return $PrefVote::STV::Round::b cmp $PrefVote::STV::Round::a })},
    "sort descending -> no exception");
is_deeply($stv_round_ref->{candidates}, [reverse @add_candidate_tests], "candidates in reversed order");
lives_ok( sub{$stv_round_ref->sort_candidates(sub{ return $PrefVote::STV::Round::a cmp $PrefVote::STV::Round::b })},
    "sort ascending -> no exception");
is_deeply($stv_round_ref->{candidates}, \@add_candidate_tests, "candidates in original order");
throws_ok( sub{$stv_round_ref->sort_candidates()}, 'PrefVote::STV::Round::BadSortingFnException',
    "missing sort function -> throws BadSortingFnException as expected");

# test set_result() (17 tests)
foreach my $test (@set_result_tests) {
    my @rounds;
    my $round_ref = PrefVote::STV::Round->new( candidates => \@add_candidate_tests);
    if (exists $test->{exception}) {
        # expected exception test
        throws_ok( sub {$round_ref->set_result(
            (exists $test->{name} ? (name => $test->{name}) : ()),
            (exists $test->{type} ? (type => $test->{type}) : ()))},
            $test->{exception}, $test->{description});
    } else {
        # test with no expected exception
        lives_ok( sub {$round_ref->set_result(
            (exists $test->{name} ? (name => $test->{name}) : ()),
            (exists $test->{type} ? (type => $test->{type}) : ()))},
            $test->{description}." - no exception");
        is($round_ref->{result}{type}, $test->{type}, $test->{description}." - type");
        is_deeply($round_ref->{result}{name}, $test->{name}, $test->{description}." - name");
    }
}
