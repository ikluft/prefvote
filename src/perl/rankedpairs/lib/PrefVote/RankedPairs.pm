# PrefVote::RankedPairs
# ABSTRACT: Ranked Pairs vote counting module for PrefVote
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::RankedPairs::PairData;
use PrefVote::RankedPairs::Majority;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp);
use PrefVote::Core::Set qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners  => [qw(list set string)],
    pair     => [qw(hash hash PrefVote::RankedPairs::PairData)],
    majority => [qw(list PrefVote::RankedPairs::Majority)],
    graph    => [qw(hash hash string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);

# list of names of winners in order by place, ties shown by an ArrayRef to the tied candidates
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
    isa         => HashRef [ HashRef [ InstanceOf ['PrefVote::RankedPairs::PairData'] ] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        pair_accessor => 'accessor',
        pair_get      => 'get',
        pair_keys     => 'keys',
        pair_set      => 'set',
    },
);

# majorities are win-lose (or tied) pairs
# the list is ordered from largest margin of victory down to zero for ties
has majority => (
    is          => 'rw',
    isa         => ArrayRef [ InstanceOf ['PrefVote::RankedPairs::Majority'] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        majority_all   => 'all',
        majority_count => 'count',
        majority_get   => 'get',
        majority_push  => 'push',
        majority_sort  => 'sort_in_place',
    },
);

# majority graph for determining ordering
has graph => (
    is          => 'rw',
    isa         => HashRef [ HashRef [NonEmptySimpleStr] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        graph_accessor => 'accessor',
        graph_exists   => 'exists',
        graph_get      => 'get',
        graph_keys     => 'keys',
        graph_set      => 'set',
    },
);

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ( $self, $cand_i, $cand_j ) = @_;
    if ( not exists $self->{pair}{$cand_i} ) {
        $self->{pair}{$cand_i} = {};
    }
    if ( not exists $self->{pair}{$cand_i}{$cand_j} ) {
        $self->{pair}{$cand_i}{$cand_j} = PrefVote::RankedPairs::PairData->new();
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

# lock a candidate-pair
sub set_lock
{
    my ( $self, $cand_i, $cand_j ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->set_lock();
}

# get lock status in matrix entry
sub get_lock
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};             # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};    # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_lock();
}

# add a directed link in the graph
sub graph_add_link
{
    my ( $self, $cand_i, $cand_j ) = @_;

    # tally links in graph
    if ( not $self->graph_exists($cand_i) ) {
        $self->graph_set( $cand_i, {} );
    }
    $self->{graph}{$cand_i}{$cand_j} = 1;
    return;
}

# get a choice/candidate's total locked wins
sub cand_total_wins
{
    my ( $self, $cand ) = @_;
    return 0 if not $self->graph_exists($cand);
    return scalar keys %{ $self->graph_accessor($cand) };
}

# get a choice/candidate's total of all margins of victory
sub cand_total_mov
{
    my ( $self, $cand ) = @_;
    my $total = 0;
    foreach my $opponent ( keys %{ $self->pair_get($cand) } ) {
        $total += $self->get_mov( $cand, $opponent );
    }
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
        my @included = keys %seen_on_ballot;
        my @omitted  = grep { not exists $seen_on_ballot{$_} } @choices;
        foreach my $in (@included) {
            foreach my $out (@omitted) {
                $self->add_preference( $in, $out, $ballot->{quantity} );
            }
        }
    }
    return;
}

# sort candidtate pairs by margin of victory
sub sort_pairs
{
    my $self = shift;

    # create list of candidate pairs and compute margin of victory for each
    foreach my $cand_i ( $self->pair_keys() ) {
        foreach my $cand_j ( keys %{ $self->pair_accessor($cand_i) } ) {

            # skip if we've already computed this pair in the reverse candidate order
            next if exists $self->{pair}{$cand_i}{$cand_j}{mov};

            # set up margin of victory (mov) and tentative i-j candidate pair (may be reordered)
            my $pref_ij = $self->get_preference( $cand_i, $cand_j );
            my $pref_ji = $self->get_preference( $cand_j, $cand_i );
            $self->set_mov( $cand_i, $cand_j, $pref_ij - $pref_ji );
            $self->set_mov( $cand_j, $cand_i, $pref_ji - $pref_ij );
            my @cand = ( $cand_i, $cand_j );

            # handle tied i = j link
            if ( $pref_ij == $pref_ji ) {

                # tied candidates ordered alphabetically for consistent results in testing
                $self->majority_push( PrefVote::RankedPairs::Majority->new( cand => [ sort @cand ] ) );
                next;
            }

            # handle i < j link
            if ( $pref_ij < $pref_ji ) {

                # candidates in reverse order for j > i
                $self->majority_push( PrefVote::RankedPairs::Majority->new( cand => [ reverse @cand ] ) );
                next;
            }

            # handle i > j link
            $self->majority_push( PrefVote::RankedPairs::Majority->new( cand => [@cand] ) );
        }
    }

    # sort candidate pairs list by margin of victory
    $self->majority_sort( \&PrefVote::RankedPairs::Majority::cmp_pair );
    return;
}

# depth first search looking for a specific node (to prevent a cycle)
sub depth_first_search
{
    my ( $self, %opts ) = @_;
    my $target  = $opts{target};
    my $node    = $opts{node};
    my $visited = $opts{visited};

    # skip if this node has already been visited
    if ( $visited->{$node} // 0 ) {
        return 0;
    }

    # set this node as visited
    $visited->{$node} = 1;

    # skip if there are no adjacent nodes
    return 0 if not $self->graph_exists($node);

    # inspect adjacent nodes for the target, return true if found
    # otherwise traverse them
    foreach my $adj ( keys %{ $self->graph_get($node) } ) {
        if ( $adj eq $target ) {
            return 1;
        }
        if ( $self->depth_first_search( target => $target, node => $adj, visited => $visited ) ) {
            return 1;
        }
    }

    # nothing found, return false (not found)
    return 0;
}

# check if a candidate pair conflicts with previous pairs
sub is_conflict
{
    my ( $self, $cand1, $cand2 ) = @_;

    # skip ties - either direction is in conflict against locking
    if ( $self->get_mov( $cand1, $cand2 ) == 0 ) {
        $self->debug_print("is_conflict($cand1, $cand2) -> true (tie)");
        return 1;
    }

    # it's a conflict if the opposite order/direction of the same pair is locked
    if ( $self->get_lock( $cand2, $cand1 ) != 0 ) {
        $self->debug_print("is_conflict($cand1, $cand2) -> true (reverse direction is locked)");
        return 1;
    }

    # do a depth-first search of the graph to detect a path from cand2 to cand1, which would cause a cycle
    if ( $self->depth_first_search( target => $cand1, node => $cand2, visited => {} ) ) {
        $self->debug_print("is_conflict($cand1, $cand2) -> true (cycle detected)");
        return 1;
    }

    # no conflict found
    $self->debug_print("is_conflict($cand1, $cand2) -> false (no conflict)");
    return 0;
}

# lock candidtate pairs which don't conflict with earlier pairs
sub lock_pairs
{
    my $self = shift;

    # loop through sorted majority-pair list:
    # lock pairs which don't conflict with earlier ones
    for ( my $maj_index = 0 ; $maj_index < $self->majority_count() ; $maj_index++ ) {

        # find majority item (candidate pair) for this pass through the loop
        my $majority = $self->majority_get($maj_index);
        my @pair     = $majority->cands();

        # skip conflicts
        if ( $self->is_conflict(@pair) ) {
            next;
        }

        # lock the listed candidate pair
        $self->set_lock(@pair);

        # tally links in graph
        $self->graph_add_link( $pair[0], $pair[1] );
    }
    return;
}

# comparison function for sorting results
sub cmp_choice
{
    my ( $self, $cand1, $cand2 ) = @_;

    # 1st comparison: Condorcet table wins in descending order
    my $total_wins1 = $self->cand_total_wins($cand1);
    my $total_wins2 = $self->cand_total_wins($cand2);
    if ( $total_wins1 != $total_wins2 ) {
        return $total_wins2 <=> $total_wins1;
    }

    # 2nd comparison: choice/candidate's average ballot placement in ascending order
    my $tiebreak_disabled = $self->config("no-tiebreak") // 0;    # config flag to disable tie-breaking by avg rank
    if ( not $tiebreak_disabled ) {
        my $place1 = $self->average_ranking($cand1);
        my $place2 = $self->average_ranking($cand2);
        if ( not fp_equal( $place1, $place2 ) ) {
            return fp_cmp( $place1, $place2 );
        }
    }

    return 0;
}

# calculate result ordering from graph
sub graph_to_order
{
    my $self = shift;

    # sort list of choices to begin graph traversal
    my @choices = sort { $self->cmp_choice( $a, $b ) } $self->choices_keys(); # list of candidates ordered by cmp_choice

    # detect ties and build result rankings
    while ( scalar @choices ) {
        my $leader    = shift @choices;
        my $tie_group = set($leader);
        while ( ( scalar @choices > 0 ) and ( $self->cmp_choice( $leader, $choices[0] ) == 0 ) ) {
            $tie_group->insert( shift @choices );
        }
        $self->winners_push($tie_group);
    }
    return;
}

# count votes using Ranked Pairs method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # tally preferences into one-way candidate-pair totals
    $self->tally_preferences();

    # sort candidate pairs by margin of victory
    $self->sort_pairs();

    # lock candidate pairs which don't conflict with earlier pairs
    $self->lock_pairs();

    # calculate result ordering from graph
    $self->graph_to_order();

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r( winners => $self->winners() );

    #$self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

  use PrefVote::RankedPairs;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::RankedPairs::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...


=head1 DESCRIPTION

I<PrefVote::RankedPairs> implements the Ranked Pairs preference voting algorithm for the I<PrefVote>
system.
The Ranked Pairs method was created in 1987 by Nicolaus Tideman.
Eash voter's ballot ranks available candidates in order of the voter's preference.
This method compares each pair of candidates by the numbers ofvoter preference,
and ranks the candidate pairs in order of strongest wins.
The algorithm builds a graph structure of the wins starting with the strongest,
locking in each win that does not create a cycle in the graph.

The effect of Ranked Pairs is a Condorcet-compliant voting result in which any candidate who beats
all other candidates in pairwise comparisons will be the winner.
The graph algorithm also has limited tie-breaking capability beyond the pure Condorcet definition.

All of the I<PrefVote> algorithms have an additional layer of tie-breaking from the Average Choice
Rank (ACR) data. Though an average ballot position is a rating which would not alone be approprtiate
for elections, when a tie occurs, all other things are equal and so the ACR becomes a useful
indicator of the intent of the voters in that scenario.

=head1 ATTRIBUTES

These attributes are in addition to L<those inherited from PrefVote::Core|PrefVote::Core/ATTRIBUTES>.

=over 1

=item winners

the list of winners of the voting in order from first to last.
The format is a list of sets of strings.

=over 1

=item list of places

list of each place in the results from first to last

=item set of candidates

a set of the candidates which tie for that place, or only one if there is no tie

=item candidate identifier string

a string with the identifier for the candidate in this position in the result

=back

=item pair

internal hash used for counting candidate pairs in the Ranked Pairs result, and particularly for computing
how much candidates win or lose against others.

=item majority

internal list used to track ordering of majorities, winning paired contests among candidates

=item graph

internal graph structure for computing Ranked Pairs results from pair comparisons and the list of majorities.
Candidate pair comparisons are only added to the result if they would not create a loop/conflict in the graph.

=back

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

=item set_lock

This should not be called by external code.

The sets the lock status for a candidate pair in the direction of the first over the second.
The parameters are the ids of the two candidates for the pair.
This lock means the first candidate won over the second in pairwise comparisons.
Once a win is locked for the first candidate over the second,
this must not also be called to set a lock in the opposite direction,
stating a win for the second candidate over the first.

=item get_lock

Returns 1 if the candidate pair is locked, 0 if not.
The parameters are the ids of the two candidates for the pair.

=item graph_add_link

This should not be called by external code.

This sets a directed link in the Ranked Pairs algorithm graph.
It's how Ranked Pairs computes winning candidate order.
The parameters are the ids of the two candidates for the pair.

=item cand_total_wins

This returns the count of total wins for a candidate over other candidates.
The parameter is the id of the candidate.

=item cand_total_mov

This returns a candidate's total of their margins of victory.
The parameter is the id of the candidate.

=item tally_preferences

This should not be called by external code.
This is called by the count() method.

This tallies the ballots which were already stored by PrefVote::Core::submit_ballot().
This is where each entry in a ranked preference order is counted as a preference over all
following lower-ranked candidates.
Omitted candidates are counted as equals but less preferred than all other candidates for that ballot.
This calls I<add_preference()> to register preferences from ballots into the candidate pair matrix.

=item sort_pairs

This should not be called by external code.
This is called by the count() method.

This generates a list of all possible pairs of candidates as L<PrefVote::RankedPairs::Majority>
objects, computing a margin of victory for each pair.
Then it sorts the list of pairs from greatest to least margin of victory.

=item depth_first_search

This should not be called by external code.

This is called by is_conflict().
It performs a depth-first search of the Ranked Pairs graph from a specific node,
looking for another candidate (the other candidate in a pair)
to find out if there's a path between them.

=item is_conflict

This checks the Ranked Pairs graph to determine if a given candidate pair conflicts with prior pairs,
those with higher margins of victory.
It returns true if there is a conflict, false otherwise.

This is used to determine whether a candidate pair can be locked in the order.
A pair with the first candidate winning over the second will be processed first and get locked.
Later when the same pair in the opposite order is encountered, it will be considered in conflict with
the earlier pair, and will not be locked.
Also ties will not be locked in either direction.

=item lock_pairs

This should not be called by external code.
This is called by the count() method.

This loops through the candidate pairs and locks pairs which do not conflict with earlier pairs.
This is a key step of the Ranked Pairs alogorithm.
It takes no parameters, using the previously assembled list of L<PrefVote::RankedPairs::Majority>
objects representing all the candidate pairs.

=item cmp_choice

This is a comparison function for sorting Ranked Pairs vote results.
The parameters are the candidate identifiers for two candidates to be compared.
Like the <=> operator, it returns -1 for less-than, 0 for equality and 1 for greater-than.

=item graph_to_order

This should not be called by external code.
This is called by the count() method.

This populates the winners list based on the contents of the Ranked Pairs graph.

=item count

This counts votes using the Ranked Pairs method.
The count() method of L<PrefVote::Core> is overridden by I<PrefVote::RankedPairs> in order to implement
the Ranked Pairs voting algorithm.

=back

=head1 FUNCTIONS

=over 1

=item item2list

This returns a ballot item as a list, whether it was a single scalar or a tie-group set.
The Ranked Pairs definition does not allow input ties.
PrefVote can be configured to allow it for consistency across Condorcet methods.

The parameter is an item from a L<PrefVote::Core::Ballot> object.

=back

=head1 SEE ALSO

L<PrefVote::Core>

Ranked Pairs voting method on Wikipedia L<https://en.wikipedia.org/wiki/Ranked_pairs>

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
