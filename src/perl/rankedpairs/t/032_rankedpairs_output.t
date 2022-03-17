#!/usr/bin/perl
# 032_rankedpairs_output.t - tests for PrefVote::RankedPairs::Output
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use open ":std", ":encoding(UTF-8)";
use Test::More tests => 104;
use Test::Exception;
use Readonly;
use Data::Dumper;
use PrefVote::RankedPairs;
use PrefVote::RankedPairs::Output;
use PrefVote::Core::Output::RawCapture; # mock-output class for testing

# constants for test fixtures

# PrefVote::RankedPairs instantiation parameters
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
RankedPairs:
  ballots:
    '012543':
      hex_id: '012543'
      items:
      - - ABNORMAL
      - - BORING
      - - CHAOTIC
      - - FACTIOUS
      - - EVIL
      - - DYSFUNCTIONAL
      quantity: 1
    '023':
      hex_id: '023'
      items:
      - - ABNORMAL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      quantity: 1
    '051243':
      hex_id: '051243'
      items:
      - - ABNORMAL
      - - FACTIOUS
      - - BORING
      - - CHAOTIC
      - - EVIL
      - - DYSFUNCTIONAL
      quantity: 1
    '10':
      hex_id: '10'
      items:
      - - BORING
      - - ABNORMAL
      quantity: 1
    '104235':
      hex_id: '104235'
      items:
      - - BORING
      - - ABNORMAL
      - - EVIL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - FACTIOUS
      quantity: 1
    '1203':
      hex_id: '1203'
      items:
      - - BORING
      - - CHAOTIC
      - - ABNORMAL
      - - DYSFUNCTIONAL
      quantity: 1
    '123045':
      hex_id: '123045'
      items:
      - - BORING
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - EVIL
      - - FACTIOUS
      quantity: 1
    '13540':
      hex_id: '13540'
      items:
      - - BORING
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - EVIL
      - - ABNORMAL
      quantity: 1
    '143502':
      hex_id: '143502'
      items:
      - - BORING
      - - EVIL
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - ABNORMAL
      - - CHAOTIC
      quantity: 1
    '1450':
      hex_id: '1450'
      items:
      - - BORING
      - - EVIL
      - - FACTIOUS
      - - ABNORMAL
      quantity: 1
    '15':
      hex_id: '15'
      items:
      - - BORING
      - - FACTIOUS
      quantity: 1
    '15240':
      hex_id: '15240'
      items:
      - - BORING
      - - FACTIOUS
      - - CHAOTIC
      - - EVIL
      - - ABNORMAL
      quantity: 1
    '15403':
      hex_id: '15403'
      items:
      - - BORING
      - - FACTIOUS
      - - EVIL
      - - ABNORMAL
      - - DYSFUNCTIONAL
      quantity: 1
    '20351':
      hex_id: '20351'
      items:
      - - CHAOTIC
      - - ABNORMAL
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - BORING
      quantity: 1
    '204153':
      hex_id: '204153'
      items:
      - - CHAOTIC
      - - ABNORMAL
      - - EVIL
      - - BORING
      - - FACTIOUS
      - - DYSFUNCTIONAL
      quantity: 1
    '2134':
      hex_id: '2134'
      items:
      - - CHAOTIC
      - - BORING
      - - DYSFUNCTIONAL
      - - EVIL
      quantity: 1
    '215430':
      hex_id: '215430'
      items:
      - - CHAOTIC
      - - BORING
      - - FACTIOUS
      - - EVIL
      - - DYSFUNCTIONAL
      - - ABNORMAL
      quantity: 1
    '23015':
      hex_id: '23015'
      items:
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - BORING
      - - FACTIOUS
      quantity: 1
    '231045':
      hex_id: '231045'
      items:
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - BORING
      - - ABNORMAL
      - - EVIL
      - - FACTIOUS
      quantity: 1
    '234501':
      hex_id: '234501'
      items:
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - EVIL
      - - FACTIOUS
      - - ABNORMAL
      - - BORING
      quantity: 1
    '24350':
      hex_id: '24350'
      items:
      - - CHAOTIC
      - - EVIL
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - ABNORMAL
      quantity: 1
    '305421':
      hex_id: '305421'
      items:
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - FACTIOUS
      - - EVIL
      - - CHAOTIC
      - - BORING
      quantity: 1
    '321405':
      hex_id: '321405'
      items:
      - - DYSFUNCTIONAL
      - - CHAOTIC
      - - BORING
      - - EVIL
      - - ABNORMAL
      - - FACTIOUS
      quantity: 1
    '340':
      hex_id: '340'
      items:
      - - DYSFUNCTIONAL
      - - EVIL
      - - ABNORMAL
      quantity: 1
    '401352':
      hex_id: '401352'
      items:
      - - EVIL
      - - ABNORMAL
      - - BORING
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - CHAOTIC
      quantity: 1
    '40253':
      hex_id: '40253'
      items:
      - - EVIL
      - - ABNORMAL
      - - CHAOTIC
      - - FACTIOUS
      - - DYSFUNCTIONAL
      quantity: 1
    '403512':
      hex_id: '403512'
      items:
      - - EVIL
      - - ABNORMAL
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - BORING
      - - CHAOTIC
      quantity: 1
    '42350':
      hex_id: '42350'
      items:
      - - EVIL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - FACTIOUS
      - - ABNORMAL
      quantity: 1
    '4251':
      hex_id: '4251'
      items:
      - - EVIL
      - - CHAOTIC
      - - FACTIOUS
      - - BORING
      quantity: 1
    '450213':
      hex_id: '450213'
      items:
      - - EVIL
      - - FACTIOUS
      - - ABNORMAL
      - - CHAOTIC
      - - BORING
      - - DYSFUNCTIONAL
      quantity: 1
    '451':
      hex_id: '451'
      items:
      - - EVIL
      - - FACTIOUS
      - - BORING
      quantity: 1
    '451230':
      hex_id: '451230'
      items:
      - - EVIL
      - - FACTIOUS
      - - BORING
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - ABNORMAL
      quantity: 1
    '452':
      hex_id: '452'
      items:
      - - EVIL
      - - FACTIOUS
      - - CHAOTIC
      quantity: 1
    '452013':
      hex_id: '452013'
      items:
      - - EVIL
      - - FACTIOUS
      - - CHAOTIC
      - - ABNORMAL
      - - BORING
      - - DYSFUNCTIONAL
      quantity: 1
    '453012':
      hex_id: '453012'
      items:
      - - EVIL
      - - FACTIOUS
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - BORING
      - - CHAOTIC
      quantity: 1
    '453021':
      hex_id: '453021'
      items:
      - - EVIL
      - - FACTIOUS
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - CHAOTIC
      - - BORING
      quantity: 1
    '5':
      hex_id: '5'
      items:
      - - FACTIOUS
      quantity: 2
    '50342':
      hex_id: '50342'
      items:
      - - FACTIOUS
      - - ABNORMAL
      - - DYSFUNCTIONAL
      - - EVIL
      - - CHAOTIC
      quantity: 1
    '50412':
      hex_id: '50412'
      items:
      - - FACTIOUS
      - - ABNORMAL
      - - EVIL
      - - BORING
      - - CHAOTIC
      quantity: 1
    '512304':
      hex_id: '512304'
      items:
      - - FACTIOUS
      - - BORING
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - EVIL
      quantity: 1
    '5314':
      hex_id: '5314'
      items:
      - - FACTIOUS
      - - DYSFUNCTIONAL
      - - BORING
      - - EVIL
      quantity: 1
    '532401':
      hex_id: '532401'
      items:
      - - FACTIOUS
      - - DYSFUNCTIONAL
      - - CHAOTIC
      - - EVIL
      - - ABNORMAL
      - - BORING
      quantity: 1
    '54':
      hex_id: '54'
      items:
      - - FACTIOUS
      - - EVIL
      quantity: 1
    '540312':
      hex_id: '540312'
      items:
      - - FACTIOUS
      - - EVIL
      - - ABNORMAL
      - - DYSFUNCTIONAL
      - - BORING
      - - CHAOTIC
      quantity: 1
    '541023':
      hex_id: '541023'
      items:
      - - FACTIOUS
      - - EVIL
      - - BORING
      - - ABNORMAL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      quantity: 1
    '54210':
      hex_id: '54210'
      items:
      - - FACTIOUS
      - - EVIL
      - - CHAOTIC
      - - BORING
      - - ABNORMAL
      quantity: 2
    '542301':
      hex_id: '542301'
      items:
      - - FACTIOUS
      - - EVIL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - ABNORMAL
      - - BORING
      quantity: 1
    '542310':
      hex_id: '542310'
      items:
      - - FACTIOUS
      - - EVIL
      - - CHAOTIC
      - - DYSFUNCTIONAL
      - - BORING
      - - ABNORMAL
      quantity: 1
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
  graph:
    ABNORMAL:
      DYSFUNCTIONAL: 1
    BORING:
      DYSFUNCTIONAL: 1
    CHAOTIC:
      ABNORMAL: 1
      BORING: 1
      DYSFUNCTIONAL: 1
    EVIL:
      ABNORMAL: 1
      BORING: 1
      CHAOTIC: 1
      DYSFUNCTIONAL: 1
      FACTIOUS: 1
    FACTIOUS:
      ABNORMAL: 1
      BORING: 1
      CHAOTIC: 1
      DYSFUNCTIONAL: 1
  index_to_choice:
    '0': ABNORMAL
    '1': BORING
    '2': CHAOTIC
    '3': DYSFUNCTIONAL
    '4': EVIL
    '5': FACTIOUS
  majority:
  - cand:
    - EVIL
    - ABNORMAL
  - cand:
    - CHAOTIC
    - DYSFUNCTIONAL
  - cand:
    - EVIL
    - DYSFUNCTIONAL
  - cand:
    - FACTIOUS
    - ABNORMAL
  - cand:
    - EVIL
    - CHAOTIC
  - cand:
    - FACTIOUS
    - CHAOTIC
  - cand:
    - FACTIOUS
    - DYSFUNCTIONAL
  - cand:
    - FACTIOUS
    - BORING
  - cand:
    - EVIL
    - BORING
  - cand:
    - BORING
    - DYSFUNCTIONAL
  - cand:
    - CHAOTIC
    - ABNORMAL
  - cand:
    - CHAOTIC
    - BORING
  - cand:
    - ABNORMAL
    - DYSFUNCTIONAL
  - cand:
    - EVIL
    - FACTIOUS
  - cand:
    - ABNORMAL
    - BORING
  name: Test Vote
  pair:
    ABNORMAL:
      BORING:
        mov: 0
        preference: 23
      CHAOTIC:
        mov: -2
        preference: 21
      DYSFUNCTIONAL:
        lock: 1
        mov: 1
        preference: 22
      EVIL:
        mov: -17
        preference: 15
      FACTIOUS:
        mov: -13
        preference: 17
    BORING:
      ABNORMAL:
        mov: 0
        preference: 23
      CHAOTIC:
        mov: -2
        preference: 22
      DYSFUNCTIONAL:
        lock: 1
        mov: 6
        preference: 26
      EVIL:
        mov: -7
        preference: 20
      FACTIOUS:
        mov: -10
        preference: 18
    CHAOTIC:
      ABNORMAL:
        lock: 1
        mov: 2
        preference: 23
      BORING:
        lock: 1
        mov: 2
        preference: 24
      DYSFUNCTIONAL:
        lock: 1
        mov: 15
        preference: 29
      EVIL:
        mov: -12
        preference: 17
      FACTIOUS:
        mov: -12
        preference: 17
    DYSFUNCTIONAL:
      ABNORMAL:
        mov: -1
        preference: 21
      BORING:
        mov: -6
        preference: 20
      CHAOTIC:
        mov: -15
        preference: 14
      EVIL:
        mov: -14
        preference: 16
      FACTIOUS:
        mov: -11
        preference: 18
    EVIL:
      ABNORMAL:
        lock: 1
        mov: 17
        preference: 32
      BORING:
        lock: 1
        mov: 7
        preference: 27
      CHAOTIC:
        lock: 1
        mov: 12
        preference: 29
      DYSFUNCTIONAL:
        lock: 1
        mov: 14
        preference: 30
      FACTIOUS:
        lock: 1
        mov: 1
        preference: 23
    FACTIOUS:
      ABNORMAL:
        lock: 1
        mov: 13
        preference: 30
      BORING:
        lock: 1
        mov: 10
        preference: 28
      CHAOTIC:
        lock: 1
        mov: 12
        preference: 29
      DYSFUNCTIONAL:
        lock: 1
        mov: 11
        preference: 29
      EVIL:
        mov: -1
        preference: 22
  seats: 1
  timestamp: Sat Mar 12 19:57:09 2022
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
    'seats' => 1,
    'name' => 'Test Vote',
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
                  "1 \x{2705}\x{1f512}",
                  "12 \x{2705}\x{1f512}",
                  "7 \x{2705}\x{1f512}",
                  "17 \x{2705}\x{1f512}",
                  "14 \x{2705}\x{1f512}"
                ],
                [
                  'FACTIOUS',
                  "-1 \x{274c}",
                  "\x{1f6c7}",
                  "12 \x{2705}\x{1f512}",
                  "10 \x{2705}\x{1f512}",
                  "13 \x{2705}\x{1f512}",
                  "11 \x{2705}\x{1f512}"
                ],
                [
                  'CHAOTIC',
                  "-12 \x{274c}",
                  "-12 \x{274c}",
                  "\x{1f6c7}",
                  "2 \x{2705}\x{1f512}",
                  "2 \x{2705}\x{1f512}",
                  "15 \x{2705}\x{1f512}"
                ],
                [
                  'BORING',
                  "-7 \x{274c}",
                  "-10 \x{274c}",
                  "-2 \x{274c}",
                  "\x{1f6c7}",
                  "0 \x{1f535}",
                  "6 \x{2705}\x{1f512}"
                ],
                [
                  'ABNORMAL',
                  "-17 \x{274c}",
                  "-13 \x{274c}",
                  "-2 \x{274c}",
                  "0 \x{1f535}",
                  "\x{1f6c7}",
                  "1 \x{2705}\x{1f512}"
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
    },
);

# test fail-as-expected on empty command linea (2 tests)
{
    local @ARGV = ();
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::RankedPairs->instance(%core_params)}, "1: instantiate PrefVote::RankedPairs");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty command line");
}

# test fail-as-expected on empty stdin (2 tests)
{
    local @ARGV = qw(--format=rawcapture --method=rankedpairs);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::RankedPairs->instance(%core_params)}, "2: instantiate PrefVote::RankedPairs");
    PrefVote::Core::Output::set_mock_stdin("");
    dies_ok(sub {PrefVote::Core::Output::main() }, "dies as expected on empty stdin");
}

# test with mock-stdin data (100 tests)
{
    local @ARGV = qw(--format=rawcapture --method=rankedpairs);
    my $vote_obj;
    lives_ok(sub {$vote_obj = PrefVote::RankedPairs->instance(%core_params)}, "2: instantiate PrefVote::RankedPairs");
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
    #PrefVote::RankedPairs::Output->debug_print("output = ".Dumper($output));
}

