#!/usr/bin/perl
# 042_kr2_bounds.t - tests of rating bounds for PrefVote::KR2
use strict;
use warnings;
use autodie;
use Test::Exception;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::KR2;
use Test::More tests => 5 * 9;

# basic KR2 vote parameters - deepcopy and insert a levels setting before running test
Readonly::Hash my %kr2_params => (
    name    => "Test Vote",
    seats   => 1,
    choices => {
        ABNORMAL      => "abnormal and antisocial",
        BORING        => "boring as anything",
        CHAOTIC       => "chaotic unpredictable",
        DYSFUNCTIONAL => "dysfunctional incompetent",
        EVIL          => "evil villain",
        FACTIOUS      => "factious/divisive candidate",
    },
);
Readonly::Hash my %RATING_DEF => ( PrefVote::KR2::get_rating_def() );

# make a mutable copy of %kr2_params for tests
sub mutable_params
{
    my $levels = shift;
    my %params;
    foreach my $field ( qw(name seats) ) {
        $params{$field} = $kr2_params{$field};
    }
    $params{choices} = {};
    foreach my $choice ( keys %{$kr2_params{choices}} ) {
        $params{choices}{$choice} = $kr2_params{choices}{$choice};
    }
    $params{levels} = $levels;
    return %params;
}

# generate a hash to match contents of choices at a given KR2 levels setting
sub gen_choices_hash
{
    my $levels = shift;

    my %result = %{$kr2_params{choices}};
    foreach my $bound ( @{$RATING_DEF{$levels}{bounds}} ) {
        $result{$bound} = "[rating bound $bound]";
    }
    return \%result; 
}

# main loop
foreach my $i ( sort keys %RATING_DEF ) {
    my @param_test = mutable_params( $i );
    my $vote_obj;
    lives_ok( sub { $vote_obj = PrefVote::KR2->setup_instance(@param_test) },
        "level $i instantiate PrefVote::KR2" );
    ok( defined $vote_obj, "level $i instance(core_params) returned a defined value" );
    ok( ref $vote_obj,     "level $i instance(core_params) returned a reference" );
    isa_ok( $vote_obj, "PrefVote::KR2", "level $i instance(core_params) returned correct object" );
    is( $vote_obj->levels(), $i, "level $i levels attribute check" );
    is( $vote_obj->name(),  $kr2_params{name},  "level $i name attribute check" );
    is( $vote_obj->seats(), $kr2_params{seats}, "level $i seats attribute check" );
    is( scalar keys %{$vote_obj->{choices}},
        ( scalar keys %{$kr2_params{choices}} ) + ( scalar @{$RATING_DEF{$i}{bounds}} ),
        "level $i check number of choices includes bounds" );
    is_deeply( $vote_obj->choices(), gen_choices_hash( $i ), "level $i choices hash attribute check" );
}
