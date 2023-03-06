#!/usr/bin/perl
# 022_schulze_output.t - tests for PrefVote::Schulze::Output
use Modern::Perl qw(2013); # require 5.16.0 or later
use autodie;
use open ":std", ":encoding(UTF-8)";
use Test::More tests => 104;
use Test::Exception;
use Readonly;
use Data::Dumper;
use PrefVote::Schulze;
use PrefVote::Schulze::Output;
use PrefVote::Core::Output::RawCapture; # mock-output class for testing

# constants for test fixtures

# PrefVote::Schulze instantiation parameters
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
Schulze:
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
    - placed
    BORING:
    - 4
    - placed
    CHAOTIC:
    - 3
    - placed
    DYSFUNCTIONAL:
    - 6
    - placed
    EVIL:
    - 1
    - selected
    FACTIOUS:
    - 2
    - placed
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
  rounds:
  - candidates:
    - ABNORMAL
    - BORING
    - CHAOTIC
    - DYSFUNCTIONAL
    - EVIL
    - FACTIOUS
    number: 1
    pair:
      ABNORMAL:
        BORING:
          predecessor: ABNORMAL
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 21
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 22
          strength: 1
          win_order: 1
        EVIL:
          predecessor: BORING
          preference: 15
          strength: -7
          win_order: 0
        FACTIOUS:
          predecessor: EVIL
          preference: 17
          strength: -7
          win_order: 0
      BORING:
        ABNORMAL:
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          preference: 22
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 26
          strength: 6
          win_order: 1
        EVIL:
          predecessor: BORING
          preference: 20
          strength: -7
          win_order: 0
        FACTIOUS:
          predecessor: EVIL
          preference: 18
          strength: -7
          win_order: 0
      CHAOTIC:
        ABNORMAL:
          preference: 23
          strength: 2
          win_order: 1
        BORING:
          preference: 24
          strength: 2
          win_order: 1
        DYSFUNCTIONAL:
          predecessor: CHAOTIC
          preference: 29
          strength: 15
          win_order: 1
        EVIL:
          predecessor: BORING
          preference: 17
          strength: -7
          win_order: 0
        FACTIOUS:
          predecessor: EVIL
          preference: 17
          strength: -7
          win_order: 0
      DYSFUNCTIONAL:
        ABNORMAL:
          preference: 21
          strength: -1
          win_order: 0
        BORING:
          predecessor: ABNORMAL
          preference: 20
          strength: -1
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 14
          strength: -2
          win_order: 0
        EVIL:
          predecessor: BORING
          preference: 16
          strength: -7
          win_order: 0
        FACTIOUS:
          predecessor: EVIL
          preference: 18
          strength: -7
          win_order: 0
      EVIL:
        ABNORMAL:
          preference: 32
          strength: 17
          win_order: 1
        BORING:
          preference: 27
          strength: 7
          win_order: 1
        CHAOTIC:
          preference: 29
          strength: 12
          win_order: 1
        DYSFUNCTIONAL:
          preference: 30
          strength: 14
          win_order: 1
        FACTIOUS:
          predecessor: EVIL
          preference: 23
          strength: 1
          win_order: 1
      FACTIOUS:
        ABNORMAL:
          preference: 30
          strength: 13
          win_order: 1
        BORING:
          preference: 28
          strength: 10
          win_order: 1
        CHAOTIC:
          preference: 29
          strength: 12
          win_order: 1
        DYSFUNCTIONAL:
          predecessor: CHAOTIC
          preference: 29
          strength: 12
          win_order: 1
        EVIL:
          preference: 22
          strength: -1
          win_order: 0
    result:
      name:
      - EVIL
      type: winner
    win_flag:
      EVIL: 1
  - candidates:
    - ABNORMAL
    - BORING
    - CHAOTIC
    - DYSFUNCTIONAL
    - FACTIOUS
    number: 2
    pair:
      ABNORMAL:
        BORING:
          predecessor: ABNORMAL
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 21
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 22
          strength: 1
          win_order: 1
        FACTIOUS:
          predecessor: BORING
          preference: 17
          strength: -10
          win_order: 0
      BORING:
        ABNORMAL:
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          preference: 22
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 26
          strength: 6
          win_order: 1
        FACTIOUS:
          predecessor: BORING
          preference: 18
          strength: -10
          win_order: 0
      CHAOTIC:
        ABNORMAL:
          preference: 23
          strength: 2
          win_order: 1
        BORING:
          preference: 24
          strength: 2
          win_order: 1
        DYSFUNCTIONAL:
          predecessor: CHAOTIC
          preference: 29
          strength: 15
          win_order: 1
        FACTIOUS:
          predecessor: BORING
          preference: 17
          strength: -10
          win_order: 0
      DYSFUNCTIONAL:
        ABNORMAL:
          preference: 21
          strength: -1
          win_order: 0
        BORING:
          predecessor: ABNORMAL
          preference: 20
          strength: -1
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 14
          strength: -2
          win_order: 0
        FACTIOUS:
          predecessor: BORING
          preference: 18
          strength: -10
          win_order: 0
      FACTIOUS:
        ABNORMAL:
          preference: 30
          strength: 13
          win_order: 1
        BORING:
          preference: 28
          strength: 10
          win_order: 1
        CHAOTIC:
          preference: 29
          strength: 12
          win_order: 1
        DYSFUNCTIONAL:
          predecessor: CHAOTIC
          preference: 29
          strength: 12
          win_order: 1
    result:
      name:
      - FACTIOUS
      type: winner
    win_flag:
      FACTIOUS: 1
  - candidates:
    - ABNORMAL
    - BORING
    - CHAOTIC
    - DYSFUNCTIONAL
    number: 3
    pair:
      ABNORMAL:
        BORING:
          predecessor: ABNORMAL
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 21
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 22
          strength: 1
          win_order: 1
      BORING:
        ABNORMAL:
          preference: 23
          strength: 0
          win_order: 0
        CHAOTIC:
          preference: 22
          strength: -2
          win_order: 0
        DYSFUNCTIONAL:
          preference: 26
          strength: 6
          win_order: 1
      CHAOTIC:
        ABNORMAL:
          preference: 23
          strength: 2
          win_order: 1
        BORING:
          preference: 24
          strength: 2
          win_order: 1
        DYSFUNCTIONAL:
          preference: 29
          strength: 15
          win_order: 1
      DYSFUNCTIONAL:
        ABNORMAL:
          preference: 21
          strength: -1
          win_order: 0
        BORING:
          predecessor: ABNORMAL
          preference: 20
          strength: -1
          win_order: 0
        CHAOTIC:
          predecessor: ABNORMAL
          preference: 14
          strength: -2
          win_order: 0
    result:
      name:
      - CHAOTIC
      type: winner
    win_flag:
      CHAOTIC: 1
  - candidates:
    - ABNORMAL
    - BORING
    - DYSFUNCTIONAL
    number: 4
    pair:
      ABNORMAL:
        BORING:
          forbidden:
          - ABNORMAL-BORING
          predecessor: ABNORMAL
          preference: 23
          strength: 20
          win_order: 0
        DYSFUNCTIONAL:
          preference: 22
          strength: 22
          win_order: 1
      BORING:
        ABNORMAL:
          forbidden:
          - ABNORMAL-BORING
          preference: 23
          strength: 21
          win_order: 1
        DYSFUNCTIONAL:
          preference: 26
          strength: 26
          win_order: 1
      DYSFUNCTIONAL:
        ABNORMAL:
          preference: 21
          strength: 21
          win_order: 0
        BORING:
          predecessor: ABNORMAL
          preference: 20
          strength: 20
          win_order: 0
    result:
      name:
      - BORING
      type: winner
    win_flag:
      BORING: 1
  - candidates:
    - ABNORMAL
    - DYSFUNCTIONAL
    number: 5
    pair:
      ABNORMAL:
        DYSFUNCTIONAL:
          preference: 22
          strength: 1
          win_order: 1
      DYSFUNCTIONAL:
        ABNORMAL:
          preference: 21
          strength: -1
          win_order: 0
    result:
      name:
      - ABNORMAL
      type: winner
    win_flag:
      ABNORMAL: 1
  - candidates:
    - DYSFUNCTIONAL
    number: 6
    pair: {}
    result:
      name:
      - DYSFUNCTIONAL
      type: winner
    win_flag:
      DYSFUNCTIONAL: 1
  - candidates: []
    number: 7
    pair: {}
    win_flag: {}
  seats: 1
  total_ballots: 50
  winners:
  - - EVIL
  - - FACTIOUS
  - - CHAOTIC
  - - BORING
  - - ABNORMAL
  - - DYSFUNCTIONAL";

# expected results from PrefVote::Core::Output::RawCapture
Readonly::Array my @result_expected => (
          {
            'name' => 'Test Vote',
            'seats' => 1,
            'total_ballots' => 50,
          },
          {
            'rows' => [
                        [
                          'Abbreviation',
                          'Name/description',
                          'Result'
                        ],
                        [
                          'EVIL',
                          'evil villain',
                          '1/selected'
                        ],
                        [
                          'FACTIOUS',
                          'factious/divisive',
                          '2/placed'
                        ],
                        [
                          'CHAOTIC',
                          'chaotic unpredictable',
                          '3/placed'
                        ],
                        [
                          'BORING',
                          'boring as anything',
                          '4/placed'
                        ],
                        [
                          'ABNORMAL',
                          'abnormal and antisocial',
                          '5/placed'
                        ],
                        [
                          'DYSFUNCTIONAL',
                          'dysfunctional incompetent',
                          '6/placed'
                        ]
                      ]
          },
          {
            'rows' => [
                        [
                          '',
                          'EVIL',
                          'FACTIOUS',
                          'CHAOTIC',
                          'BORING',
                          'ABNORMAL',
                          'DYSFUNCTIONAL'
                        ],
                        [
                          'EVIL',
                          "\x{1f6c7}",
                          "1 \x{2705}",
                          "12 \x{2705}",
                          "7 \x{2705}",
                          "17 \x{2705}",
                          "14 \x{2705}"
                        ],
                        [
                          'FACTIOUS',
                          "-1 \x{274c}",
                          "\x{1f6c7}",
                          "12 \x{2705}",
                          "10 \x{2705}",
                          "13 \x{2705}",
                          "11 \x{2705}"
                        ],
                        [
                          'CHAOTIC',
                          "-12 \x{274c}",
                          "-12 \x{274c}",
                          "\x{1f6c7}",
                          "2 \x{2705}",
                          "2 \x{2705}",
                          "15 \x{2705}"
                        ],
                        [
                          'BORING',
                          "-7 \x{274c}",
                          "-10 \x{274c}",
                          "-2 \x{274c}",
                          "\x{1f6c7}",
                          "0 \x{1f535}",
                          "6 \x{2705}"
                        ],
                        [
                          'ABNORMAL',
                          "-17 \x{274c}",
                          "-13 \x{274c}",
                          "-2 \x{274c}",
                          "0 \x{1f535}",
                          "\x{1f6c7}",
                          "1 \x{2705}"
                        ],
                        [
                          'DYSFUNCTIONAL',
                          "-14 \x{274c}",
                          "-11 \x{274c}",
                          "-15 \x{274c}",
                          "-6 \x{274c}",
                          "-1 \x{274c}",
                          "\x{1f6c7}"
                        ]
                      ],
            'title' => 'Margin-of-victory matrix'
          }
);

# test fail-as-expected on empty command linea (2 tests)
{
    local @ARGV = ();
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Schulze->instance(%core_params)}, "1: instantiate PrefVote::Schulze");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty command line");
}

# test fail-as-expected on empty stdin (2 tests)
{
    local @ARGV = qw(--format=RawCapture --method=schulze);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Schulze->instance(%core_params)}, "2: instantiate PrefVote::Schulze");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty stdin");
}

# test with mock-stdin data (100 tests)
{
    local @ARGV = qw(--format=RawCapture --method=schulze);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::Schulze->instance(%core_params)}, "2: instantiate PrefVote::Schulze");
    PrefVote::Core::Output::set_mock_stdin($mock_input);
    lives_ok(sub {PrefVote::Core::Output::main() }, "main processes YAML result");
    my $output = PrefVote::Core::Output::RawCapture::get_output();
    # expected result entry 0
    is(scalar keys %{$output->[0]}, scalar keys %{$result_expected[0]},
        "output record 0: ".(scalar keys %{$result_expected[0]})." items");
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
    #PrefVote::Schulze::Output->debug_print("output = ".Dumper($output));
}

