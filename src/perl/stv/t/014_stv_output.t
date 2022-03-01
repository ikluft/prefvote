#!/usr/bin/perl
# 014_stv_output.t - tests for PrefVote::STV::Output
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use open ":std", ":encoding(UTF-8)";
use Test::More tests => 92;
use Test::Exception;
use Readonly;
use Data::Dumper;
use PrefVote::STV;
use PrefVote::STV::Output;
use PrefVote::Core::Output::RawCapture; # mock-output class for testing

# constants for test fixtures

# PrefVote::STV instantiation parameters
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
STV:
  choice_to_index:
    ABNORMAL: '0'
    BORING: '1'
    CHAOTIC: '2'
    DYSFUNCTIONAL: '3'
    EVIL: '4'
    FACTIOUS: '5'
  choice_to_result:
    ABNORMAL:
    - 5
    - eliminated
    BORING:
    - 2
    - eliminated
    CHAOTIC:
    - 4
    - eliminated
    DYSFUNCTIONAL:
    - 5
    - eliminated
    EVIL:
    - 2
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
  eliminated:
  - - DYSFUNCTIONAL
    - ABNORMAL
  - - CHAOTIC
  - - EVIL
    - BORING
  index_to_choice:
    '0': ABNORMAL
    '1': BORING
    '2': CHAOTIC
    '3': DYSFUNCTIONAL
    '4': EVIL
    '5': FACTIOUS
  name: Test Vote
  rounds:
  - candidates:
    - FACTIOUS
    - EVIL
    - BORING
    - CHAOTIC
    - ABNORMAL
    - DYSFUNCTIONAL
    number: 1
    quota: 25
    result:
      name:
      - DYSFUNCTIONAL
      - ABNORMAL
      type: eliminated
    tally:
      ABNORMAL:
        eliminated: 1
        name: ABNORMAL
        votes: 3
        winner: 0
      BORING:
        eliminated: 0
        name: BORING
        votes: 10
        winner: 0
      CHAOTIC:
        eliminated: 0
        name: CHAOTIC
        votes: 8
        winner: 0
      DYSFUNCTIONAL:
        eliminated: 1
        name: DYSFUNCTIONAL
        votes: 3
        winner: 0
      EVIL:
        eliminated: 0
        name: EVIL
        votes: 12
        winner: 0
      FACTIOUS:
        eliminated: 0
        name: FACTIOUS
        votes: 14
        winner: 0
    votes_used: 50
  - candidates:
    - FACTIOUS
    - EVIL
    - BORING
    - CHAOTIC
    number: 2
    quota: 25
    result:
      name:
      - CHAOTIC
      type: eliminated
    tally:
      BORING:
        eliminated: 0
        name: BORING
        votes: 11
        winner: 0
      CHAOTIC:
        eliminated: 1
        name: CHAOTIC
        votes: 10
        winner: 0
      EVIL:
        eliminated: 0
        name: EVIL
        votes: 13
        winner: 0
      FACTIOUS:
        eliminated: 0
        name: FACTIOUS
        votes: 16
        winner: 0
    votes_used: 50
  - candidates:
    - FACTIOUS
    - BORING
    - EVIL
    number: 3
    quota: 24.5
    result:
      name:
      - EVIL
      - BORING
      type: eliminated
    tally:
      BORING:
        eliminated: 1
        name: BORING
        votes: 16
        winner: 0
      EVIL:
        eliminated: 1
        name: EVIL
        votes: 16
        winner: 0
      FACTIOUS:
        eliminated: 0
        name: FACTIOUS
        votes: 17
        winner: 0
    votes_used: 49
  - candidates:
    - FACTIOUS
    number: 4
    quota: 22.5
    result:
      name:
      - FACTIOUS
      type: winner
    tally:
      FACTIOUS:
        eliminated: 0
        name: FACTIOUS
        place: 1
        surplus: 22.5
        transfer: 0.5
        votes: 45
        winner: 1
    votes_used: 45
  - candidates: []
    number: 5
    quota: 0
    tally: {}
    votes_used: 0
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
                          'BORING',
                          'boring as anything',
                          '2/eliminated'
                        ],
                        [
                          'EVIL',
                          'evil villain',
                          '2/eliminated'
                        ],
                        [
                          'CHAOTIC',
                          'chaotic unpredictable',
                          '4/eliminated'
                        ],
                        [
                          'ABNORMAL',
                          'abnormal and antisocial',
                          '5/eliminated'
                        ],
                        [
                          'DYSFUNCTIONAL',
                          'dysfunctional incompetent',
                          '5/eliminated'
                        ]
                      ]
          },
          {
            'rows' => [
                        [
                          'Round #',
                          'Quota',
                          'FACTIOUS',
                          'BORING',
                          'EVIL',
                          'CHAOTIC',
                          'ABNORMAL',
                          'DYSFUNCTIONAL'
                        ],
                        [
                          1,
                          '25',
                          '14',
                          '10',
                          '12',
                          '8',
                          "3 \x{274c}",
                          "3 \x{274c}"
                        ],
                        [
                          2,
                          '25',
                          '16',
                          '11',
                          '13',
                          "10 \x{274c}",
                          "\x{274c}",
                          "\x{274c}"
                        ],
                        [
                          3,
                          '24.5',
                          '17',
                          "16 \x{274c}",
                          "16 \x{274c}",
                          "\x{274c}",
                          "\x{274c}",
                          "\x{274c}"
                        ],
                        [
                          4,
                          '22.5',
                          "45 \x{2705}",
                          "\x{274c}",
                          "\x{274c}",
                          "\x{274c}",
                          "\x{274c}",
                          "\x{274c}"
                        ]
                      ]
          }
);

# test fail-as-expected on empty command linea (2 tests)
{
    local @ARGV = ();
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::STV->instance(%core_params)}, "1: instantiate PrefVote::STV");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty command line");
}

# test fail-as-expected on empty stdin (2 tests)
{
    local @ARGV = qw(--format=rawcapture --method=stv);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::STV->instance(%core_params)}, "2: instantiate PrefVote::STV");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty stdin");
}

# test with mock-stdin data (88 tests)
{
    local @ARGV = qw(--format=rawcapture --method=stv);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::STV->instance(%core_params)}, "2: instantiate PrefVote::STV");
    PrefVote::Core::Output::set_mock_stdin($mock_input);
    lives_ok(sub {PrefVote::Core::Output::main() }, "main processes YAML result");
    my $output = PrefVote::Core::Output::RawCapture::get_output();
    # expected result entry 0
    is(scalar keys %{$output->[0]}, 2, "output record 0: 2 items");
    foreach my $key (keys %{$result_expected[0]}) {
        is($output->[0]{$key}, $result_expected[0]{$key}, "output record 0: $key=".$result_expected[0]{$key});
    }
    # tables in expected result entry 1 & 2
    foreach my $num (1..2) {
        is(scalar keys %{$output->[$num]}, scalar keys %{$result_expected[$num]},
            "output record $num: ".(scalar keys %{$result_expected[$num]})." item");
        isa_ok($output->[$num]{rows}, "ARRAY", "output record $num: rows is an array ref");
        foreach my $attr (qw(title subtitle)) {
            if (exists $result_expected[$num]{$attr}) {
                is($output->[$num]{$attr}, $result_expected[$num]{$attr},
                    "output record $num: $attr = ".$result_expected[$num]{$attr});
            } else {
                ok((not exists $output->[$num]{$attr}), "output record $num: $attr should not exist");
            }
        }
        my $row_count = scalar @{$result_expected[$num]{rows}};
        is(scalar @{$output->[$num]{rows}}, $row_count, "output record $num: $row_count rows");
        for (my $res_row=0; $res_row < $row_count; $res_row++) {
            my $col_count = scalar @{$result_expected[$num]{rows}[$res_row]};
            is (scalar @{$output->[$num]{rows}[$res_row]}, $col_count,
                "output record $num row $res_row: $col_count columns");
            for (my $res_col=0; $res_col < $col_count; $res_col++) {
                is($output->[$num]{rows}[$res_row][$res_col], $result_expected[$num]{rows}[$res_row][$res_col],
                    "output record $num row $res_row col $res_col: '"
                        .$result_expected[$num]{rows}[$res_row][$res_col]."'");
            }
        }
    }
    #PrefVote::STV::Output->debug_print("output = ".Dumper($output));
}

