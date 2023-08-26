#!/usr/bin/perl
# 021_cef_votes.t - tests for PrefVote::Core

use strict;
use warnings;
use autodie;
use feature qw(say);
#use Test::More skip_all => "WIP TBD CYA TTFN";
use Test::More;
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
Readonly::Scalar my $debug_mode => (( $ENV{PREFVOTE_DEBUG} // 0 ) or ( $ENV{CEF_PARSER_DEBUG} // 0 )) and 1;
Readonly::Scalar my $input_dir => getcwd() . "/t/test-inputs/" . basename( $0, ".t" );
Readonly::Array my @ranking_tests => (
  {
      in => "",
      error => qr(^Syntax error at position 0, expected EMPTY_RANKING INT WORD),
  },
  {
      in => "975",
      out => [ [ '975' ] ],
  },
  {
      in => "foo",
      out => [ [ 'foo' ] ],
  },
  {
      in => "foo bar",
      out => [ [ 'foo bar' ] ],
  },
  {
      in => "foo bar > SNAFU = fnord",
      out => [ [ 'foo bar' ], [ 'SNAFU', 'fnord' ] ],
  },
  {
      in => "A = B > C = D > E = F",
      out => [ [ 'A', 'B' ], [ 'C', 'D' ], [ 'E', 'F' ] ],
  },
  {
      in => "A>B ^2",
      out => [ { weight => 2 }, [ 'A' ], [ 'B' ] ],
  },
  {
      in => "C>B>A * 700",
      out => [ { quantifier => 700 }, [ 'C' ], [ 'B' ], [ 'A' ] ],
  },
  {
      in => "A>B * 5 ^2",
      out => [ { quantifier => 5, weight => 2 }, [ 'A' ], [ 'B' ] ],
  },
  {
      in => "A>B ^2 *5",
      out => [ { quantifier => 5, weight => 2 }, [ 'A' ], [ 'B' ] ],
  },
  {
      in => "tag1 || A>B ^2 *5",
      out => [ { tags => [ qw(tag1)], quantifier => 5, weight => 2 }, [ 'A' ], [ 'B' ] ],
  },
  {
      in => "tag1, tag2 || A>B ^2 *5",
      out => [ { tags => [ qw(tag1 tag2)], quantifier => 5, weight => 2 }, [ 'A' ], [ 'B' ] ],
  },
  {
      in => "C>B>A * 700 * 2",
      error => qr(^Syntax error at position 13, found \* '\*'),
  },
  {
      in => "C>B>A ^ 7 ^ 2",
      error => qr(^Syntax error at position 11, found \^ '\^'),
  },
  {
      in => "tag1, tag2 || C>B>A ^ 7 ^ 2",
      error => qr(^Syntax error at position 25, found \^ '\^'),
  },
  {
      in => "tag1, , tag2 || C>B>A ^ 7 ^ 2",
      error => qr(^Syntax error at position 7, found , ',', expected INT WORD),
  },
  {
      in => "/EMPTY_RANKING/",
      out => [ ],
  },
  {
      in => "/EMPTY_RANKING/ * 350",
      out => [ { quantifier => 350 } ],
  },
  {
      in => "/EMPTY_RANKING/ * 350 ^ 2",
      out => [ { quantifier => 350, weight => 2 } ],
  },
  {
      in => "/EMPTY_RANKING/^2*350",
      out => [ { quantifier => 350, weight => 2 } ],
  },
  {
      in => "/EMPTY_RANKING/ * 350 * 2",
      error => qr(^Syntax error at position 23, found \* '\*'),
  },
  {
      in => "/EMPTY_RANKING/^7^2",
      error => qr(^Syntax error at position 18, found \^ '\^'),
  },
  {
      in => "tag1 || /EMPTY_RANKING/",
      out => [ { tags => [ qw(tag1)] } ],
  },
  {
      in => "tag1, tag2 || /EMPTY_RANKING/",
      out => [ { tags => [ qw(tag1 tag2)] } ],
  },
  {
      in => "tag1, , tag2 || /EMPTY_RANKING/",
      error => qr(^Syntax error at position 7, found , ',', expected INT WORD),
  },
  {
      in => ",",
      error => qr(^Syntax error at position 1, found , ',', expected EMPTY_RANKING INT WORD),
  },
  {
      in => "||",
      error => qr(^Syntax error at position 2, found TAGDELIM '||', expected EMPTY_RANKING INT WORD),
  },
  {
      in => "DYSFUNCTIONAL > FACTIOUS > ABNORMAL > CHAOTIC > EVIL > BORING",
      out => [ [ "DYSFUNCTIONAL" ], [ "FACTIOUS" ], [ "ABNORMAL" ], [ "CHAOTIC" ], [ "EVIL" ], [ "BORING" ] ],
  },
);

# count tests to declareTest::More total
sub count_tests
{
    my $total_tests = 1; # start with 1 for instantiation test
    foreach my $test ( @ranking_tests ) {
        if ( exists $test->{error}) {
            $total_tests += 2; # test count when errors expected
        } else {
            $total_tests += 2; # test count when success expected
        }
    }
    return $total_tests;
}

# declare test count
plan tests => count_tests();

# Condorcet Election Format (CEF) file tests
{
    # check correct class from new() method
    my $parser1 = PrefVote::Core::Input::CEF_Parser->new();
    isa_ok( $parser1, "PrefVote::Core::Input::CEF_Parser", "parser1");
}

# run per-line parser tests
my $test_group = 1;
foreach my $test_case ( @ranking_tests ) {
    # test for errors or successful parsing
    if ( exists $test_case->{error}) {
        # error expected
        SKIP: {
            if ( exists $test_case->{skip}) {
                # update count when tests added below
                skip $test_group . ": " . $test_case->{skip} . " ( " . $test_case->{in} . " )", 2;
            } else {
                my $parser = PrefVote::Core::Input::CEF_Parser->new();
                my $in_str = $test_case->{in};
                my $err_regex= $test_case->{error};
                my $result;
                dies_ok( sub { $result = $parser->parse( $in_str ); }, "$test_group: $in_str / dies as expected");
                my $err_result = $@;
                $debug_mode and say STDERR "$test_group: in: $in_str / result: error $err_result";
                like( $err_result, $err_regex, "$test_group: $in_str / expected error: $err_regex");
            }
        }
    } else {
        # successful parse expected
        SKIP: {
            if ( exists $test_case->{skip}) {
                # update count when tests added below
                skip $test_group . ": " . $test_case->{skip} . " ( " . $test_case->{in} . " )", 2;
            } else {
                my $parser = PrefVote::Core::Input::CEF_Parser->new();
                my $in_str = $test_case->{in};
                my $out_struct = $test_case->{out};
                my $result;
                lives_ok( sub { $result = $parser->parse( $in_str ); }, "$test_group: $in_str / parser runs");
                $debug_mode and say STDERR "$test_group: in: $in_str / result: " . Dumper( $result );
                is_deeply( $result, $out_struct, "$test_group: $in_str / data check" );
            }
        }
    }
    $test_group++;
}

1;
