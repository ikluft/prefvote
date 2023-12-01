# PrefVote::KR2
# ABSTRACT: Kluft Rank-Rate (KR2) vote counting module for PrefVote
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::KR2;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common         qw(Str ArrayRef HashRef InstanceOf PositiveOrZeroInt NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp);
use PrefVote::Core::Set   qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners  => [qw(list set string)],
    pair     => [qw(hash hash PrefVote::Core::PairData)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);
__PACKAGE__->ballot_input_ties_policy(1);    # set flag for Core: this class allows input ballots to set A/B ties

# rating levels
Readonly::Hash my %rating_levels => (
    1 => [ qw(neutral) ],
    3 => [ qw(favor neutral oppose) ],
    5 => [ qw(favor2 favor1 neutral oppose1 oppose2) ],
);

# list of names of winners in order by place, ties shown by a set of the tied candidates
has winners => (
    is          => 'rw',
    isa         => ArrayRef [ Set [Str] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        winners_all   => 'all',
        winners_count => 'count',
        winners_push  => 'push',
    },
);

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is          => 'rw',
    isa         => HashRef [ HashRef [ InstanceOf ['PrefVote::Core::PairData'] ] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        pair_accessor => 'accessor',
        pair_get      => 'get',
        pair_keys     => 'keys',
        pair_set      => 'set',
    },
);

# TODO to be continued...

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
sub tally_preferences
{
    my $self = shift;

    # compute preferences from ballots: loop through votes tallying preferences
    my @choices = $self->choices_keys();    # list of candidates
    foreach my $combo ( $self->ballots_keys() ) {

        # loop through choices on the ballot
        my $ballot       = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();

        # choices contained on the ballot have all pairwise preferences recorded
        my %seen_on_ballot;
        for ( my $pos1 = 0 ; $pos1 < scalar @ballot_items - 1 ; $pos1++ ) {

            # mark all following items on the ballot as less-favored than the current item
            # This adds 2 levels of loops to support potential ties within each position.
            my @item1 = item2list( $ballot_items[$pos1] );
            foreach my $cand_i (@item1) {
                $seen_on_ballot{$cand_i} = 1;
                for ( my $pos2 = $pos1 + 1 ; $pos2 < scalar @ballot_items ; $pos2++ ) {
                    my @item2 = item2list( $ballot_items[$pos2] );
                    foreach my $cand_j (@item2) {
                        $seen_on_ballot{$cand_j} = 1;
                        $self->add_preference( $cand_i, $cand_j, $ballot->{quantity} );
                    }
                }
            }
        }

        # all choices omitted from the ballot (unranked) count as less-preferred than all on the ballot
        # no comparison is made between unranked choices - the voter didn't provide data on that
        if ( $self->get_flag('implicit_ranking') ) {
            my @included = keys %seen_on_ballot;
            my @omitted  = grep { not exists $seen_on_ballot{$_} } @choices;
            foreach my $in (@included) {
                foreach my $out (@omitted) {
                    $self->add_preference( $in, $out, $ballot->{quantity} );
                }
            }
        }
    }
    return;
}

# count votes using Kluft Rank-Rate method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # tally preferences into one-way candidate-pair totals
    $self->tally_preferences();

    # TODO

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r( winners => $self->winners() );

    #$self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    return;
}

# return short result list
sub results
{
    my $self = shift;
    return { ranked => $self->{winners} };
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    use PrefVote::KR2;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::KR2::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...

=head1 DESCRIPTION

I<PrefVote::KR2> implements the Kluft Rank-Rate (KR2) preference voting algorithm for the I<PrefVote>
system.
KR2 is an experimental voting method under testing.

=head1 SEE ALSO

L<PrefVote::Core>

The Kluft Rank-Rate (KR2) preference voting algorithm is experimental.
As documentation is written it will be posted at L<https://ikluft.github.io/prefvote/doc/kr2/>.

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
