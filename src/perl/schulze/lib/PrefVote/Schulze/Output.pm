# PrefVote::Schulze::Output
# ABSTRACT: output formatting for PrefVote::Schulze
# derived from Vote::Schulze by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Schulze::Output;

use autodie;
use base qw(PrefVote);
use Readonly;
use PrefVote::Core::Output;
use PrefVote::Core::Float qw(float_external);

# generate counting results table
sub do_counting_table
{
    my ( $class, $format_class, $result_data ) = @_;

    # generate candidate names list
    my @candidates = PrefVote::Core::Output->candidates_list($result_data);

    # generate victory matrix
    my $round = $result_data->{rounds}[0];

    # start with heading row
    my @result_rows = [ "", @candidates ];

    # generate victory matrix rows
    foreach my $i (@candidates) {

        # candidate name starts the row
        my @row = ($i);

        foreach my $j (@candidates) {

            # generate victory matrix column items
            # add n/a symbol for a candidate compared against itself
            if ( $i eq $j ) {
                push @row, PrefVote::Core::Output::symbol("n/a");
                next;
            }

            # add blank entry if no comparison occurred between these candidates (rare corner case)
            if (    not exists $round->{pair}{$i}{$j}{preference}
                and not exists $round->{pair}{$j}{$i}{preference} )
            {
                push @row, "";
                next;
            }

            # add margin of victory and win/lose icon
            my $margin = ( $round->{pair}{$i}{$j}{preference} // 0 ) - ( $round->{pair}{$j}{$i}{preference} // 0 );
            my $icon =
                ( $margin == 0 ) ? PrefVote::Core::Output::symbol("tie")
                : (
                ( $margin > 0 ) ? PrefVote::Core::Output::symbol("win")
                : PrefVote::Core::Output::symbol("lose")
                );
            push @row, "$margin $icon";
        }
        push @result_rows, \@row;
    }
    $format_class->do_table( $result_data, \@result_rows, "Margin-of-victory matrix" );

    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

This should not be called externally - use L<PrefVote::Core::Output>

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Schulze::Output is used by L<PrefVote::Core::Output> to format output from Schulze votes.

=head1 EXAMPLE

An example from running PrefVote test suite data through PrefVote::Schulze and text output follows:

=over

 Results: Test Vote 006
 2 seats available | 100 ballots
 ┌───────────────┬───────────────────────────┬────────────┐
 │ Abbreviation  │ Name/description          │ Result     │
 ├───────────────┼───────────────────────────┼────────────┤
 │ DYSFUNCTIONAL │ dysfunctional incompetent │ 1/selected │
 │ BORING        │ boring as anything        │ 2/selected │
 │ FACTIOUS      │ factious/divisive         │ 3/placed   │
 │ EVIL          │ evil villain              │ 4/placed   │
 │ ABNORMAL      │ abnormal and antisocial   │ 5/placed   │
 │ CHAOTIC       │ chaotic unpredictable     │ 6/placed   │
 └───────────────┴───────────────────────────┴────────────┘
 Margin-of-victory matrix
 ┌───────────────┬───────────────┬────────┬──────────┬────────┬──────────┬─────────┐
 │               │ DYSFUNCTIONAL │ BORING │ FACTIOUS │ EVIL   │ ABNORMAL │ CHAOTIC │
 ├───────────────┼───────────────┼────────┼──────────┼────────┼──────────┼─────────┤
 │ DYSFUNCTIONAL │ 🛇             │ 2 ✅   │ 8 ✅     │ 6 ✅   │ 6 ✅     │ 16 ✅   │
 │ BORING        │ -2 ❌         │ 🛇      │ -2 ❌    │ 7 ✅   │ 2 ✅     │ 20 ✅   │
 │ FACTIOUS      │ -8 ❌         │ 2 ✅   │ 🛇        │ 14 ✅  │ -7 ❌    │ 18 ✅   │
 │ EVIL          │ -6 ❌         │ -7 ❌  │ -14 ❌   │ 🛇      │ 8 ✅     │ 15 ✅   │
 │ ABNORMAL      │ -6 ❌         │ -2 ❌  │ 7 ✅     │ -8 ❌  │ 🛇        │ 12 ✅   │
 │ CHAOTIC       │ -16 ❌        │ -20 ❌ │ -18 ❌   │ -15 ❌ │ -12 ❌   │ 🛇       │
 └───────────────┴───────────────┴────────┴──────────┴────────┴──────────┴─────────┘

=back

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

