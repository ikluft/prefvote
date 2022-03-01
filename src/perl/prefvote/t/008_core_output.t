#!/usr/bin/perl
# 008_core_output.t - tests for PrefVote::Core::Output
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 40;
use Test::Exception;
use Readonly;
use Data::Dumper;
use PrefVote::Core;
use PrefVote::Core::Output;
use PrefVote::Core::Output::RawCapture; # mock-output class for testing

# constants for test fixtures

# PrefVote::Core instantiation parameters
Readonly::Hash my %core_params => (
    name => "Test Vote",
    seats => 1,
    choices => {
        ABNORMAL => "abnormal and antisocial",
        BORING => "boring as anything",
        CHAOTIC => "chaotic unpredictable",
        DYSFUNCTIONAL => "dysfunctional incompetent",
        EVIL => "evil villain",
        FACTIOUS => "factious/divisive candidate",
    },
);

# YAML mock input for PrefVote::Core::Output::main as if from stdin
Readonly::Scalar my $mock_input => "---
Core:
  choice_to_index:
    ABNORMAL: '0'
    BORING: '1'
    CHAOTIC: '2'
    DYSFUNCTIONAL: '3'
    EVIL: '4'
    FACTIOUS: '5'
  choice_to_result:
    ABNORMAL:
    - 2
    - placed
    BORING:
    - 5
    - eliminated
    CHAOTIC:
    - 5
    - eliminated
    DYSFUNCTIONAL:
    - 4
    - eliminated
    EVIL:
    - 3
    - eliminated
    FACTIOUS:
    - 1
    - selected
  choices:
    ABNORMAL: abnormal and antisocial
    BORING: boring as anything
    CHAOTIC: chaotic unpredictable
    DYSFUNCTIONAL: dysfunctional incompetent
    EVIL: evil villain
    FACTIOUS: factious/divisive
  index_to_choice:
    '0': ABNORMAL
    '1': BORING
    '2': CHAOTIC
    '3': DYSFUNCTIONAL
    '4': EVIL
    '5': FACTIOUS
  name: Test Vote
  seats: 1
  total_ballots: 50";

# expected results from PrefVote::Core::Output::RawCapture
Readonly::Array my @result_expected => (
          {
            'seats' => 1,
            'name' => 'Test Vote'
          },
          {
            'rows' => [
                        [
                          'Abbreviation',
                          'Name/description',
                          'Result'
                        ],
                        [
                          'FACTIOUS',
                          'factious/divisive',
                          '1/selected'
                        ],
                        [
                          'ABNORMAL',
                          'abnormal and antisocial',
                          '2/placed'
                        ],
                        [
                          'EVIL',
                          'evil villain',
                          '3/eliminated'
                        ],
                        [
                          'DYSFUNCTIONAL',
                          'dysfunctional incompetent',
                          '4/eliminated'
                        ],
                        [
                          'BORING',
                          'boring as anything',
                          '5/eliminated'
                        ],
                        [
                          'CHAOTIC',
                          'chaotic unpredictable',
                          '5/eliminated'
                        ]
                      ]
          }
);

# test fail-as-expected on empty command linea (2 tests)
{
    local @ARGV = ();
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Core->instance(%core_params)}, "1: instantiate PrefVote::Core");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty command line");
}

# test fail-as-expected on empty stdin (2 tests)
{
    local @ARGV = qw(--format=rawcapture --method=core);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Core->instance(%core_params)}, "2: instantiate PrefVote::Core");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty stdin");
}

# test with mock-stdin data (36 tests)
{
    local @ARGV = qw(--format=rawcapture --method=core);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Core->instance(%core_params)}, "2: instantiate PrefVote::Core");
    PrefVote::Core::Output::set_mock_stdin($mock_input);
    lives_ok(sub {PrefVote::Core::Output::main() }, "main processes YAML result");
    my $output = PrefVote::Core::Output::RawCapture::get_output();
    is(scalar keys %{$output->[0]}, 2, "output record 0: 2 items");
    foreach my $key (keys %{$result_expected[0]}) {
        is($output->[0]{$key}, $result_expected[0]{$key}, "output record 0: $key=".$result_expected[0]{$key});
    }
    is(scalar keys %{$output->[1]}, 1, "output record 1: 1 item");
    isa_ok($output->[1]{rows}, "ARRAY", "output record 1: rows is an array ref");
    my $row_count = scalar @{$result_expected[1]{rows}};
    is(scalar @{$output->[1]{rows}}, $row_count, "output record 1: $row_count rows");
    for (my $res_row=0; $res_row < $row_count; $res_row++) {
        my $col_count = scalar @{$result_expected[1]{rows}[$res_row]};
        is (scalar @{$output->[1]{rows}[$res_row]}, $col_count, "output record 1 row $res_row: $col_count columns");
        for (my $res_col=0; $res_col < $col_count; $res_col++) {
            is($output->[1]{rows}[$res_row][$res_col], $result_expected[1]{rows}[$res_row][$res_col],
                "output record 1 row $res_row col $res_col: '".$result_expected[1]{rows}[$res_row][$res_col]."'");
        }
    }
    #say STDERR "mock output: ".Dumper(PrefVote::Core::Output::RawCapture::get_output());
}

