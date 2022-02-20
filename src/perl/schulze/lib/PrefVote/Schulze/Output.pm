# PrefVote::Schulze::Output
# ABSTRACT: Gbase class for output formatting in PrefVote::Schulze
# derived from Vote::Schulze by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
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
    my ($class, $format_class, $result_data) = @_;

    # generate candidate names list
    my @candidates = $class->candidates_list($result_data);

    # generate per-round result tables
    my $c2r = $result_data->{choice_to_result};
    my $rounds = $result_data->{rounds};
    for (my $round=0; $round < scalar @$rounds; $round++) {
        my @round_candidates = sort {$c2r->{$a}[0] <=> $c2r->{$b}[0]} @{$rounds->[$round]{candidates}};
        
        # generate per-round victory matrix rows
        my @result_rows;
        foreach my $i (@round_candidates) {
            # generate victory matrix column items
            my @row;
            foreach my $j (@round_candidates) {
                # add n/a symbol for a candidate compared against itself
                if ($i eq $j) {
                    push @row, PrefVote::Core::Output::symbol("n/a");
                    next;
                }

                # add blank entry if no comparison occurred between these candidates (rare corner case)
                if (not exists $round->{pair}{$i}{$j}{preference} and not exists $round->{pair}{$j}{$i}{preference}) {
                    push @row, "";
                    next;
                }

                # add margin of victory and win/lose icon
                my $margin = ($round->{pair}{$i}{$j}{preference} // 0) - ($round->{pair}{$j}{$i}{preference} // 0);
                my $icon = ($margin == 0) ? PrefVote::Core::Output::symbol("tie")
                    : (($margin > 0) ? PrefVote::Core::Output::symbol("win") : PrefVote::Core::Output::symbol("lose"));
                push @row, "$margin $icon";
            }
            push @result_rows, @row;
        }
        $format_class->do_table($result_data, \@result_rows, "Round $round");
    }

    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Schulze::Output - base class for output formatting in PrefVote::Schulze

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

