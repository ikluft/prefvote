#!/usr/bin/perl
# 007_core_round.t - tests for PrefVote::Core::Round
use strict;
use warnings;
use autodie;
use Test::More tests => 56;
use Test::Exception;
use Readonly;
use PrefVote::Core;
use PrefVote::Core::Round;
use Data::Dumper;

# constants for test fixtures
Readonly::Array my @candidate_names => (qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS));
Readonly::Array my @set_result_tests => (
    { name => [qw(ABNORMAL)],              type => 'winner',     description => '1 winner' },
    { name => [qw(BORING)],                type => 'eliminated', description => '1 eliminated' },
    { name => [qw(CHAOTIC DYSFUNCTIONAL)], type => 'winner',     description => '2 winner' },
    { name => [qw(EVIL FACTIOUS)],         type => 'eliminated', description => '1 eliminated' },
    {
        name        => [qw(ABOMINABLE)],
        exception   => 'PrefVote::Core::Round::TypeMissingException',
        description => 'TypeMissingException as expected'
    },
    {
        type        => 'eliminated',
        exception   => 'PrefVote::Core::Round::NameMissingException',
        description => 'NameMissingException as expected'
    },
    {
        name        => 'ABOMINABLE',
        type        => 'eliminated',
        exception   => 'PrefVote::Core::Round::NameNotArrayException',
        description => 'scalar -> NameNotArrayException as expected'
    },
    {
        name        => sub { return "foo" },
        type        => 'eliminated',
        exception   => 'PrefVote::Core::Round::NameNotArrayException',
        description => 'CODE -> NameNotArrayException as expected'
    },
    {
        name        => [qw(ABOMINABLE)],
        type        => 'eliminated',
        exception   => 'PrefVote::Core::Round::InvalidCandidateException',
        description => 'InvalidCandidateException as expected'
    },
);

# check type and default values (9 tests)
my $core_round_ref;
dies_ok( sub { $core_round_ref  = PrefVote::Core::Round->new() }, "instantiate without minimal params -> dies" );
lives_ok( sub { $core_round_ref = PrefVote::Core::Round->new( number => 1 ) },
    "instantiate with minimal params -> no exception" );
ok( defined $core_round_ref, "new() returned a defined value" );
ok( ref $core_round_ref,     "new() returned a reference" );
isa_ok( $core_round_ref, "PrefVote::Core::Round", "new() returned correct object" );
is( $core_round_ref->number(), 1,     "number was set to 1" );
is( $core_round_ref->prev(),   undef, "prev is undef as expected" );
is_deeply( $core_round_ref->candidates(), [], "default: candidates list is empty" );
throws_ok(
    sub { $core_round_ref->init_round_candidates() },
    "PrefVote::Core::Round::PrevMissingException",
    "init_round_candidates() missing candidate data"
);

# test init_round_candidates() (4 tests)
my $core_round_ref2;
lives_ok(
    sub {
        $core_round_ref2 = PrefVote::Core::Round->new(
            number     => 1,
            candidates => Readonly::Clone @candidate_names
        )
    },
    "instantiate with candidates -> no exception"
);
lives_ok( sub { $core_round_ref2->init_round_candidates() },
    "init_round_candidates() with candidates -> no exception" );
is_deeply( $core_round_ref2->candidates(), \@candidate_names, "candidate list contains correct data" );
is( $core_round_ref->prev(), undef, "prev is undef as expected" );

# test set_result() (43 tests)
foreach my $test (@set_result_tests) {
    my $round_ref;
    lives_ok(
        sub { $round_ref = PrefVote::Core::Round->new( number => 2, prev => $core_round_ref2 ) },
        $test->{description} . " instantiate with candidates -> no exception"
    );
    lives_ok( sub { $round_ref->init_round_candidates() },
        $test->{description} . " - init_round_candidates() -> no exception" );

    #say STDERR "debug: ".$test->{description}." round dump: ".Dumper($round_ref);
    #say STDERR "debug: ".$test->{description}." test dump: ".Dumper($test);
    if ( exists $test->{exception} ) {

        # expected exception test
        throws_ok(
            sub {
                $round_ref->set_result(
                    ( exists $test->{name} ? ( name => $test->{name} ) : () ),
                    ( exists $test->{type} ? ( type => $test->{type} ) : () )
                )
            },
            $test->{exception},
            $test->{description}
        );
    } else {

        # test with no expected exception
        lives_ok(
            sub {
                $round_ref->set_result(
                    ( exists $test->{name} ? ( name => $test->{name} ) : () ),
                    ( exists $test->{type} ? ( type => $test->{type} ) : () )
                )
            },
            $test->{description} . " - no exception"
        );
        is( $round_ref->{result}{type}, $test->{type}, $test->{description} . " - type" );
        if ( exists $round_ref->{result}{name} ) {
            ok( $round_ref->{result}{name}->contains( @{ $test->{name} } ), $test->{description} . " - name" );
        } else {
            fail( $test->{description} . " - name fails because round_ref->{result}{name} doesn't exist" );
        }
        isa_ok( $round_ref->{prev}, "PrefVote::Core::Round", "prev points to a round" );
        is( $round_ref->{prev}, $core_round_ref2, "prev points to the round that was given to it" );
    }
}
