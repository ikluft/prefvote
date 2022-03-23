# PrefVote::STV::Output
# ABSTRACT: output formatting for PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::STV::Output;

use autodie;
use base qw(PrefVote);
use Data::Dumper;
use PrefVote::Core::Output;
use PrefVote::Core::Float qw(float_external);

# look up column/candidate result
sub get_col_result
{
    my ($result_data, $round, $cand) = @_;
    if (ref $result_data ne "HASH") {
        say STDERR "expected HASH ref, got ".Dumper($result_data);
        exit 1;
    }
    my $round_data = $result_data->{rounds}[$round];
    my $votes = $round_data->{tally}{$cand}{votes};
    my $result = {};
        $result->{display} = float_external($votes);
    foreach my $action (qw(eliminated winner)) {
        if ($round_data->{tally}{$cand}{$action} // 0) {
            $result->{display} .= " ".PrefVote::Core::Output::symbol($action);
            $result->{save} = $action;
        }
    }
    return $result;
}

# generate counting results table
sub do_counting_table
{
    my ($class, $format_class, $result_data) = @_;

    # set symbol aliases in PrefVote::Core::Output so it accepts STV's "winner" and "eliminated" names
    PrefVote::Core::Output::set_symbol_alias("winner" => "win");
    PrefVote::Core::Output::set_symbol_alias("eliminated" => "lose");

    # generate candidate names list
    my @candidates = PrefVote::Core::Output->candidates_list($result_data);

    # generate output table
    my @result_rows;
    my $rounds = $result_data->{rounds};
    my %col_status;
    push @result_rows, ['Round #', 'Quota', @candidates];
    for (my $round=0; $round < scalar @$rounds; $round++) {
        my $quota = $result_data->{rounds}[$round]{quota};
        last if $quota <= 0;
        my @result_row = ($round+1, float_external($quota));
        foreach my $col_name (@candidates) {
            if (exists $col_status{$col_name}) {
               push @result_row, PrefVote::Core::Output::symbol($col_status{$col_name});
               next;
            }
            my $status = get_col_result($result_data, $round, $col_name);
            push @result_row, $status->{display};
            if (exists $status->{save}) {
                $col_status{$col_name} = $status->{save};
            }
        }
        push @result_rows, \@result_row;
    }
    $format_class->do_table($result_data, \@result_rows);

    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::STV::Output - output formatting for PrefVote::STV

=head1 SYNOPSIS

This should not be called externally - use L<PrefVote::Core::Output>

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::STV::Output is used by L<PrefVote::Core::Output> to format output from STV votes.

=head1 EXAMPLE

An example from running PrefVote test suite data through PrefVote::STV and text output follows:

=over

 Results: Test Vote 006
 2 seats available | 100 ballots
 ┌───────────────┬───────────────────────────┬──────────────┐
 │ Abbreviation  │ Name/description          │ Result       │
 ├───────────────┼───────────────────────────┼──────────────┤
 │ DYSFUNCTIONAL │ dysfunctional incompetent │ 1/selected   │
 │ BORING        │ boring as anything        │ 2/selected   │
 │ EVIL          │ evil villain              │ 3/placed     │
 │ ABNORMAL      │ abnormal and antisocial   │ 4/eliminated │
 │ FACTIOUS      │ factious/divisive         │ 5/eliminated │
 │ CHAOTIC       │ chaotic unpredictable     │ 6/eliminated │
 └───────────────┴───────────────────────────┴──────────────┘
 ┌─────────┬──────────┬───────────────┬────────────┬─────────────┬──────────┬──────────┬─────────┐
 │ Round # │ Quota    │ DYSFUNCTIONAL │ BORING     │ EVIL        │ ABNORMAL │ FACTIOUS │ CHAOTIC │
 ├─────────┼──────────┼───────────────┼────────────┼─────────────┼──────────┼──────────┼─────────┤
 │ 1       │ 33.33333 │ 24            │ 14         │ 17          │ 18       │ 14       │ 13 ❌   │
 │ 2       │ 31.66667 │ 25            │ 17         │ 18          │ 19       │ 16 ❌    │ ❌      │
 │ 3       │ 31.33333 │ 28            │ 23         │ 22          │ 21 ❌    │ ❌       │ ❌      │
 │ 4       │ 31       │ 33 ✅         │ 31         │ 29          │ ❌       │ ❌       │ ❌      │
 │ 5       │ 20.58586 │ ✅            │ 32.0303 ✅ │ 29.72727    │ ❌       │ ❌       │ ❌      │
 │ 6       │ 11.47544 │ ✅            │ ✅         │ 34.42632 ✅ │ ❌       │ ❌       │ ❌      │
 └─────────┴──────────┴───────────────┴────────────┴─────────────┴──────────┴──────────┴─────────┘

=back

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

