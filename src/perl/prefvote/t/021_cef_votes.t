#!/usr/bin/perl
# 021_cef_votes.t - tests for PrefVote::Core

use strict;
use warnings;
use autodie;
use feature qw(say);
#use Test::More skip_all => "WIP TBD CYA TTFN";
use Test::More tests => 2;
use Test::Exception;
use File::Basename qw(basename);
use Readonly;
use Cwd qw(getcwd);
use Set::Tiny qw(set);
use YAML::XS;
use PrefVote::Core;
use PrefVote::Core::Ballot;
use PrefVote::Core::Input::CEF_Parser;

# temp
use Data::Dumper;

# input directory for CEF data files
Readonly::Scalar my $input_dir => getcwd() . "/t/test-inputs/" . basename( $0, ".t" );
Readonly::Array my @ranking_tests => (
  { in => "A = B > C = D > E = F", out => [ [ 'A', 'B' ], [ 'C', 'D' ], [ 'E', 'F' ] ] },
);

# Condorcet Election Format (CEF) file tests
my $parser1 = PrefVote::Core::Input::CEF_Parser->new();
isa_ok( $parser1, "PrefVote::Core::Input::CEF_Parser", "parser1");

# run per-line parser tests
foreach my $test_case ( @ranking_tests ) {
    my $in_str = $test_case->{in};
    my $out_struct = $test_case->{out};
    my $result = $parser1->parse( $in_str );
    # say STDERR "in: $in_str / result: " . Dumper( $result );
    is_deeply( $result, $out_struct, "parser line: $in_str" );
}

1;
