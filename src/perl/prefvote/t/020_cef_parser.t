#!/usr/bin/perl
# 020_cef_parser.t - tests for PrefVote::Core::Input::CEF_Parser

use strict;
use warnings;
use autodie;
use feature qw(say);
use Test::More;
use Test::Exception;
use Readonly;
use Set::Tiny qw(set);
use YAML::XS;
use PrefVote::Core;
use PrefVote::Core::Ballot;
use PrefVote::Core::Input::CEF_Parser;

# temp
use Data::Dumper;

# input directory for CEF data files
Readonly::Scalar my $debug_mode => ( ( $ENV{PREFVOTE_DEBUG} // 0 ) or ( $ENV{CEF_PARSER_DEBUG} // 0 ) ) and 1;
Readonly::Array my @ranking_tests => (

    # tests from CEF spec examples
    {
        in  => "Candidate_A > Candidate_B > Candidate_C",
        out => [ ['Candidate_A'], ['Candidate_B'], ['Candidate_C'] ],
    },
    {
        in  => "Candidate_C > Candidate_A = Candidate_B",
        out => [ ['Candidate_C'], [ 'Candidate_A', 'Candidate_B' ] ],
    },
    {
        in  => "Candidate_B = Candidate_A > Candidate_C",
        out => [ [ 'Candidate_B', 'Candidate_A' ], ['Candidate_C'] ],
    },
    {
        in  => "Candidate_C",
        out => [ ['Candidate_C'] ],
    },
    {
        in  => "Candidate_B > Candidate_C",
        out => [ ['Candidate_B'], ['Candidate_C'] ],
    },

    # tests bassed on syntax features
    {
        in    => "",
        error => qr(^Syntax error at position 0, expected EMPTY_RANKING INT WORD),
    },
    {
        in  => "975",
        out => [ ['975'] ],
    },
    {
        in  => "975string",
        out => [ ['975string'] ],
    },
    {
        in  => "foo",
        out => [ ['foo'] ],
    },
    {
        in  => "foo bar",
        out => [ ['foo bar'] ],
    },
    {
        in  => "foo bar > SNAFU = fnord",
        out => [ ['foo bar'], [ 'SNAFU', 'fnord' ] ],
    },
    {
        in  => "A = B > C = D > E = F",
        out => [ [ 'A', 'B' ], [ 'C', 'D' ], [ 'E', 'F' ] ],
    },
    {
        in  => "A>B ^2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "A>B ^2",
        out => [ { weight => 2 }, ['A'], ['B'] ],
    },
    {
        in  => "C>B>A * 700",
        out => [ { quantifier => 700 }, ['C'], ['B'], ['A'] ],
    },
    {
        in  => "A>B * 5 ^2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "A>B * 5 ^2",
        out => [ { quantifier => 5, weight => 2 }, ['A'], ['B'] ],
    },
    {
        in  => "A>B ^2 *5",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "A>B ^2 *5",
        out => [ { quantifier => 5, weight => 2 }, ['A'], ['B'] ],
    },
    {
        in  => "tag1 || A>B ^2 *5",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "tag1 || A>B ^2 *5",
        out => [ { tags => [qw(tag1)], quantifier => 5, weight => 2 }, ['A'], ['B'] ],
    },
    {
        in  => "tag1, tag2 || A>B ^2 *5",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "tag1, tag2 || A>B ^2 *5",
        out => [ { tags => [qw(tag1 tag2)], quantifier => 5, weight => 2 }, ['A'], ['B'] ],
    },
    {
        in  => "tag2,tag1||A>B*5^2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "tag2,tag1||A>B*5^2",
        out => [ { tags => [qw(tag1 tag2)], quantifier => 5, weight => 2 }, ['A'], ['B'] ],
    },
    {
        in    => "C>B>A * 700 * 2",
        error => qr(^Syntax error at position 13, found \* '\*'),
    },
    {
        in    => "C>B>A ^ 7 ^ 2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in    => "C>B>A ^ 7 ^ 2",
        error => qr(^Syntax error at position 11, found \^ '\^'),
    },
    {
        in    => "tag1, tag2 || C>B>A ^ 7 ^ 2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in    => "tag1, tag2 || C>B>A ^ 7 ^ 2",
        error => qr(^Syntax error at position 25, found \^ '\^'),
    },
    {
        in    => "tag1, , tag2 || C>B>A ^ 7 ^ 2",
        error => qr(^Syntax error at position 7, found , ',', expected INT WORD),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in    => "tag1, , tag2 || C>B>A ^ 7 ^ 2",
        error => qr(^Syntax error at position 7, found , ',', expected INT WORD),
    },
    {
        in  => "/EMPTY_RANKING/",
        out => [],
    },
    {
        in  => "/EMPTY_RANKING/ * 350",
        out => [ { quantifier => 350 } ],
    },
    {
        in  => "/EMPTY_RANKING/ * 350 ^ 2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "/EMPTY_RANKING/ * 350 ^ 2",
        out => [ { quantifier => 350, weight => 2 } ],
    },
    {
        in  => "/EMPTY_RANKING/^2*350",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in  => "/EMPTY_RANKING/^2*350",
        out => [ { quantifier => 350, weight => 2 } ],
    },
    {
        in    => "/EMPTY_RANKING/ * 350 * 2",
        error => qr(^Syntax error at position 23, found \* '\*'),
    },
    {
        in    => "/EMPTY_RANKING/^7^2",
        error => qr(^weight not permitted without weight_allowed flag),
    },
    {
        vote_def => { params => { weight_allowed => 1 }},
        in    => "/EMPTY_RANKING/^7^2",
        error => qr(^Syntax error at position 18, found \^ '\^'),
    },
    {
        in  => "tag1 || /EMPTY_RANKING/",
        out => [ { tags => [qw(tag1)] } ],
    },
    {
        in  => "tag1, tag2 || /EMPTY_RANKING/",
        out => [ { tags => [qw(tag1 tag2)] } ],
    },
    {
        in    => "tag1, , tag2 || /EMPTY_RANKING/",
        error => qr(^Syntax error at position 7, found , ',', expected INT WORD),
    },
    {
        in    => ",",
        error => qr(^Syntax error at position 1, found , ',', expected EMPTY_RANKING INT WORD),
    },
    {
        in    => "||",
        error => qr(^Syntax error at position 2, found TAGDELIM '||', expected EMPTY_RANKING INT WORD),
    },
    {
        in  => "DYSFUNCTIONAL > FACTIOUS > ABNORMAL > CHAOTIC > EVIL > BORING",
        out => [ ["DYSFUNCTIONAL"], ["FACTIOUS"], ["ABNORMAL"], ["CHAOTIC"], ["EVIL"], ["BORING"] ],
    },
    {
        in    => "A >",
        error => qr(^Syntax error at position 3, expected INT WORD),
    },
    {
        in    => "> A",
        error => qr(^Syntax error at position 1, found > '>', expected EMPTY_RANKING INT WORD),
    },
);

# count tests to declareTest::More total
sub count_tests
{
    my $total_tests = 1;    # start with 1 for instantiation test
    foreach my $test (@ranking_tests) {
        if ( exists $test->{error} ) {
            $total_tests += 2;    # test count when errors expected
        } else {
            $total_tests += 2;    # test count when success expected
        }
    }
    return $total_tests;
}

# convert vote definition structure into a string
# recursive function to return a string for a vote definition structure or a portion within one
sub votedef2str
{
    my $vote_def = shift;

    # if we got a scalar, treat it as a leaf node and return it
    if ( not ref $vote_def ) {
        return $vote_def;
    }

    # handle array
    if ( ref $vote_def eq "ARRAY" ) {
        return '[' . join(",", map( votedef2str($_), @$vote_def)) . ']';
    }

    # handle hash
    if ( ref $vote_def eq "HASH" ) {
        return '{' . join(",", map($_ . "=>" . votedef2str($vote_def->{$_}), sort keys %$vote_def)) . '}';
    }

    # otherwise stringify it
    return "" . $vote_def;
}

# declare test count
plan tests => count_tests();

# run per-line parser tests
{
    my $test_group = 1;
    my $parser     = PrefVote::Core::Input::CEF_Parser->new();

    # check correct class from new() method
    isa_ok( $parser, "PrefVote::Core::Input::CEF_Parser", "parser1" );

    # perform tests from list
    foreach my $test_case (@ranking_tests) {

        # stringify vote_def for test name
        my $def_suffix = "";
        if ( exists $test_case->{vote_def}) {
            $def_suffix = " / " . votedef2str($test_case->{vote_def});
        }

        # test for errors or successful parsing
        if ( exists $test_case->{error} ) {

            # error expected
        SKIP: {
                if ( exists $test_case->{skip} ) {

                    # update count when tests added below
                    skip $test_group . ": " . $test_case->{skip} . " ( " . $test_case->{in} . " )", 2;
                } else {
                    my $in_str    = $test_case->{in};
                    my $err_regex = $test_case->{error};
                    my $vote_def  = $test_case->{vote_def} // {};
                    my $result;
                    dies_ok( sub { $result = $parser->parse($in_str, $vote_def); },
                        "$test_group: $in_str$def_suffix / dies as expected" );
                    my $err_result = $@;
                    $debug_mode and say STDERR "$test_group: in: $in_str$def_suffix / result: error $err_result";
                    like( $err_result, $err_regex, "$test_group: $in_str$def_suffix / expected error: $err_regex" );
                }
            }
        } else {

            # successful parse expected
        SKIP: {
                if ( exists $test_case->{skip} ) {

                    # update count when tests added below
                    skip $test_group . ": " . $test_case->{skip} . " ( " . $test_case->{in} . " )", 2;
                } else {
                    my $in_str     = $test_case->{in};
                    my $out_struct = $test_case->{out};
                    my $vote_def   = $test_case->{vote_def} // {};
                    my $result;
                    lives_ok( sub { $result = $parser->parse($in_str, $vote_def); },
                        "$test_group: $in_str$def_suffix / parser runs" );
                    $debug_mode and say STDERR "$test_group: in: $in_str$def_suffix / result: " . Dumper($result);
                    is_deeply( $result, $out_struct, "$test_group: $in_str$def_suffix / data check" );
                }
            }
        }
        $test_group++;
    }
}

1;
