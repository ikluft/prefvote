#!/usr/bin/perl
# 020_cef_ballot.t - tests for Condorcet Election Format ballot parsing in PrefVote::Core::Input
use strict;
use warnings;
use autodie;
use Carp qw(croak);
use Test::More;
use Readonly;
use PrefVote::Core::Input;

#use Data::Dumper;
#use feature qw(say);

# constants for test fixtures
Readonly::Array my @cef_ballot_tests => (
    {
        name        => 'A > B > C from CEF spec example',
        line        => "Candidate_A > Candidate_B > Candidate_C",
        line_params => {},
        expect      => [ ['Candidate_A'], ['Candidate_B'], ['Candidate_C'] ],
    },
    {
        name        => 'C > A = B from CEF spec example',
        line        => "Candidate_C > Candidate_A = Candidate_B",
        line_params => {},
        expect      => [ ['Candidate_C'], [ 'Candidate_A', 'Candidate_B' ] ],
    },
    {
        name        => 'B = A > C from CEF spec example',
        line        => "Candidate_B = Candidate_A > Candidate_C",
        line_params => {},
        expect      => [ [ 'Candidate_B', 'Candidate_A' ], ['Candidate_C'] ],
    },
    {
        name        => 'C from CEF spec example',
        line        => "Candidate_C",
        line_params => {},
        expect      => [ ['Candidate_C'] ],
    },
    {
        name        => 'B > C from CEF spec example',
        line        => "Candidate_B > Candidate_C",
        line_params => {},
        expect      => [ ['Candidate_B'], ['Candidate_C'] ],
    },
);

# tests of CEF parser
plan tests => scalar @cef_ballot_tests;

my $fake_pv_c_i = bless {}, "PrefVote::Core::Input";
foreach my $test (@cef_ballot_tests) {
    my @pref_order = $fake_pv_c_i->cef_fetch_prefs( $test->{line}, $test->{line_params} );

    #say STDERR 'pref_order: '.Dumper(\@pref_order);
    is_deeply( \@pref_order, $test->{expect}, $test->{name} );
}

