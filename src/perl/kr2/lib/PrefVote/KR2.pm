# PrefVote::KR2
# ABSTRACT: Kluft Rank-Rate (KR2) vote counting module for PrefVote
# Copyright (c) 2023-2026 by Ian Kluft
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
use builtin qw(true false);
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common         qw(Int Str ArrayRef HashRef InstanceOf PositiveOrZeroInt NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp);
use PrefVote::Core::Set   qw(Set);
use PrefVote::KR2::PairData;
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners    => [qw(list set string)],
    eliminated => [qw(list set string)],
    pair       => [qw(hash hash PrefVote::KR2::PairData)],
    copeland_score => [qw(hash int)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);
__PACKAGE__->ballot_input_ties_policy(1);    # set flag for Core: this class allows input ballots to set A/B ties

# rating levels
Readonly::Hash my %rating_levels => (
    1 => [qw(neutral)],
    3 => [qw(favor neutral oppose)],
    5 => [qw(favor2 favor1 neutral oppose1 oppose2)],
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

# list of names of eliminated candidates in order by occurrence, ties shown by a set of the tied candidates
has eliminated => (
    is          => 'rw',
    isa         => ArrayRef [ Set [Str] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        eliminated_all      => 'all',
        eliminated_count    => 'count',
        eliminated_push     => 'push',
        eliminated_unshift  => 'unshift',
    },
);

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is          => 'rw',
    isa         => HashRef [ HashRef [ InstanceOf ['PrefVote::KR2::PairData'] ] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        pair_accessor => 'accessor',
        pair_get      => 'get',
        pair_keys     => 'keys',
        pair_set      => 'set',
    },
);

# hash of Copeland scores (count of pairwise wins minus losses) per candidate, for result ordering
# the scores are computed by cand_copeland_score() and cached here to prevent redundant computation
has copeland_score => (
    is          => 'rw',
    isa         => HashRef [ Int ],
    default     => sub { return {} },
);

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ( $self, $cand_i, $cand_j ) = @_;
    if ( not exists $self->{pair}{$cand_i} ) {
        $self->{pair}{$cand_i} = {};
    }
    if ( not exists $self->{pair}{$cand_i}{$cand_j} ) {
        $self->{pair}{$cand_i}{$cand_j} = PrefVote::KR2::PairData->new();
    }
    return;
}

# record a candidate-pair preference
# This adds to a total of votes favoring candidate cand1 over cand2. Note: cand2 over cand1 is a separate table entry.
sub add_preference
{
    my ( $self, $cand_i, $cand_j, $quantity ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->add_preference($quantity);
}

# get preference in matrix entry
sub get_preference
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};               # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};      # use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->preference() // 0;   # return preference, or zero if the node didn't have it
}

# set a candidate-pair margin of victory (mov) in matrix entry
sub set_mov
{
    my ( $self, $cand_i, $cand_j, $mov ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->mov($mov);
}

# get candidate-pair margin of victory (mov) in matrix entry
sub get_mov
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};             # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};    # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_mov();
}

# get a choice/candidate's Copeland Score (total pairwise wins minus losses) for Condorcet result ordering
sub cand_copeland_score
{
    my ( $self, $cand ) = @_;

    # if already computed for this candidate, we're done
    if ( exists $self->{copeland}{$cand}) {
        return $self->{copeland}{$cand};
    }

    # compute Copeland Score for this candidate
    my $total = 0;
    foreach my $opponent ( keys %{ $self->pair_get($cand) } ) {
        # get margin of victory against a single opponent (negative for a loss to the opponent)
        my $mov = $self->get_mov( $cand, $opponent );

        # add 1 for a win, -1 for a loss
        $total++ if $mov > 0;
        $total-- if $mov < 0;
    }

    # save result and return
    $self->{copeland}{$cand} = $total;
    return $total;
}

# return a ballot item as a list, whether it was a single scalar or a tie-group set
# This code was borrowed from Schulze, which allows ties on input. The Ranked Pairs definition does not allow
# input ties. PrefVote can be configured to allow it for consistency across Condorcet methods.
sub item2list
{
    my $item = shift;
    if ( ref $item eq 'Set::Tiny' ) {
        return ( $item->elements() );
    }
    return ($item);
}

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

# compute margin of victory table for Condorcet pairwise comparisons
sub compute_condorcet
{
    my $self = shift;

    # loop through candidate pairs and compute margin of victory for each
    foreach my $cand_i ( $self->pair_keys() ) {
        foreach my $cand_j ( keys %{ $self->pair_accessor($cand_i) } ) {

            # skip if we've already computed this pair in the reverse candidate order
            next if exists $self->{pair}{$cand_i}{$cand_j}{mov};

            # set up margin of victory (mov) and tentative i-j candidate pair (may be reordered)
            my $pref_ij = $self->get_preference( $cand_i, $cand_j );
            my $pref_ji = $self->get_preference( $cand_j, $cand_i );
            $self->set_mov( $cand_i, $cand_j, $pref_ij - $pref_ji );
            $self->set_mov( $cand_j, $cand_i, $pref_ji - $pref_ij );
        }
    }

    return;
}

# comparison function for sorting results
sub cmp_choice
{
    my ( $self, $cand1, $cand2 ) = @_;

    # 1st comparison: Copeland Scores (pairwise wins minus losses) in descending order
    my $copeland1 = $self->cand_copeland_score($cand1);
    my $copeland2 = $self->cand_copeland_score($cand2);
    if ( $copeland1 != $copeland2 ) {
        return $copeland2 <=> $copeland1;  # order Copeland Scores from high to low
    }

    # 2nd comparison: choice/candidate's average choice rank ACR (ballot position) in ascending order
    # ACR is computed by PrefVote::Core for all voting methods
    my $place1 = $self->average_ranking($cand1);
    my $place2 = $self->average_ranking($cand2);
    if ( not fp_equal( $place1, $place2 ) ) {
        return fp_cmp( $place1, $place2 );
    }

    return 0;
}

# use Margin of Victory table to determine voting result order
# candidates are sorted by two factors:
# primary: Copeland Score (count of pairwise wins minus pairwise defeats, 0 for ties)
# secondary: PrefVote average choice rank ACR
sub mov_order
{
    my $self = shift;

    # sort list of candidates ordered by cmp_choice
    my @choices = sort { $self->cmp_choice( $a, $b ) } $self->choices_keys();

    # detect ties and build result rankings
    my $after_oppose_marker = false;
    while ( scalar @choices ) {
        my $leader    = shift @choices;

        # set flag if oppose rating bound marker found
        my $seen_oppose_marker = false;
        if ( $leader =~ / ^ _oppose . * /x ) {
            $seen_oppose_marker = true;
        }

        # find any candidates tied with the current leader and add them to a set/group for this result position
        my $tie_group = set($leader);
        while ( ( scalar @choices > 0 ) and ( $self->cmp_choice( $leader, $choices[0] ) == 0 ) ) {
            my $tie_cand = shift @choices;
            $tie_group->insert( $tie_cand );
            if ( $tie_cand =~ / ^ _oppose . * /x ) {
                $seen_oppose_marker = true;
            }
        }

        # add the set/group to either eliminated or winning result list
        if ( $after_oppose_marker ) {
            # eliminated items added in reverse of ranking order because in other methods, 1st elimination = last place
            $self->eliminated_unshift($tie_group);
        } else {
            $self->winners_push($tie_group);
        }

        # if we encountered the oppose marker, set the after_oppose_marker so remaining candidates are eliminated
        if ( $seen_oppose_marker ) {
            $after_oppose_marker = true;
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

    # compute Condorcet result ordering
    $self->compute_condorcet();

    # result ordering using Copeland Score (count of pairwise wins minus pairwise defeats, 0 for ties) & PrefVote ACR
    $self->mov_order();

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r( winners => $self->winners(), eliminated => $self->eliminated() );

    #$self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    return;
}

# return short result list
sub results
{
    my $self = shift;
    return { ranked => $self->{winners}, eliminated => $self->{eliminated} };
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

=head1 METHODS

These methods are in addition to L<those inherited from PrefVote::Core|PrefVote::Core/METHODS>.

=over 1

=item make_pair_node

This should not be called by external code.

This method is called by add_preference, set_mov and set_lock to initialize a pair node for a
specific pair of candidates if it didn't already exist.
The parameters are the ids of the two candidates of the pair in order of counting preferences
of the first over the second.
A separate pair node counts preferences in the opposite direction.

=item add_preference

This method records a counted candidate-pair preference.
The parameters are the ids of the two candidates for the pair, and the quantity of ballots by which to increment it.
The quantity is a function of how many ballots contained a specific permutation of candidates.

=item get_preference

This method returns the vote count for a specific candidate pair, indicating how many ballots had a preference for
the first candidate over the second.
If called before counting is complete, this yields the in-progress tally for that candidate pair.

=item set_mov

This should not be called by external code.

This sets the margin of victory for a candidate pair.
The parameters are the ids of the two candidates for the pair, and the margin of victory of votes counted.
This counts both wins, adding votes for the first candidate over the second, and losses,
subtracting votes for the second candidate over the first.
So the corresponding pair reversing the order of the two candidates must be the negative of the same value.

=item get_mov

This reads the margin of victory for a candidate pair.
The parameters are the ids of the two candidates for the pair.

=item cand_copeland_score

This returns a candidate's Copeland Score, the total wins minus losses, from the margin of victory table.
The parameter is the id of the candidate.

=item tally_preferences

This should not be called by external code.
This is called by the count() method.

This tallies the ballots which were already stored by PrefVote::Core::submit_ballot().
This is where each entry in a ranked preference order is counted as a preference over all
following lower-ranked candidates.
Omitted candidates are counted as equals but less preferred than all other candidates for that ballot.
This calls I<add_preference()> to register preferences from ballots into the candidate pair matrix.

=item compute_condorcet

This performs pairwise counting to generate Condorcet result ordering,
also using PrefVote's ACR (average choice rank) for tie-breaking.

=item count

This counts votes using the KR2 (Kluft Rank-Rate) method.
The count() method of L<PrefVote::Core> is overridden by I<PrefVote::KR2> in order to implement
the KR2 voting algorithm.

=back

=head1 SEE ALSO

L<PrefVote::Core>
L<https://github.com/ikluft/prefvote/doc/perl-dev.md>

The Kluft Rank-Rate (KR2) preference voting algorithm is experimental.
As documentation is written it will be posted at L<https://ikluft.github.io/prefvote/doc/kr2/>.

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
