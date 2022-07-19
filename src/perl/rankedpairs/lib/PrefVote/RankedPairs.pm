# PrefVote::RankedPairs
# ABSTRACT: Ranked Pairs vote counting module for PrefVote
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs;

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
    winners => [qw(list set string)],
    pair => [qw(hash hash PrefVote::RankedPairs::PairData)],
    majority => [qw(list PrefVote::RankedPairs::Majority)],
    graph => [qw(hash hash string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote::Core');

# list of names of winners in order by place, ties shown by an ArrayRef to the tied candidates
has winners => (
    is => 'rw',
    isa => ArrayRef[Set[Str]],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
        winners_all => 'all',
        winners_count => 'count',
        winners_push => 'push',
    },
);

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is => 'rw',
    isa => HashRef[HashRef[InstanceOf['PrefVote::RankedPairs::PairData']]],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        pair_accessor => 'accessor',
        pair_get => 'get',
        pair_keys => 'keys',
        pair_set => 'set',
    },
);

# majorities are win-lose (or tied) pairs
# the list is ordered from largest margin of victory down to zero for ties
has majority => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['PrefVote::RankedPairs::Majority']],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
        majority_all => 'all',
        majority_count => 'count',
        majority_get => 'get',
        majority_push => 'push',
        majority_sort => 'sort_in_place',
    },
);

# majority graph for determining ordering
has graph => (
    is => 'rw',
    isa => HashRef[HashRef[NonEmptySimpleStr]],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        graph_accessor => 'accessor',
        graph_exists => 'exists',
        graph_get => 'get',
        graph_keys => 'keys',
        graph_set => 'set',
    },
);

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ($self, $cand_i, $cand_j) = @_;
    if (not exists $self->{pair}{$cand_i}) {
        $self->{pair}{$cand_i} = {};
    }
    if (not exists $self->{pair}{$cand_i}{$cand_j}) {
        $self->{pair}{$cand_i}{$cand_j} = PrefVote::RankedPairs::PairData->new();
    }
    return;
}

# record a candidate-pair preference
# This adds to a total of votes favoring candidate cand1 over cand2. Note: cand2 over cand1 is a separate table entry.
sub add_preference
{
    my ($self, $cand_i, $cand_j, $quantity) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->add_preference($quantity);
}

# get preference in matrix entry
sub get_preference
{
    my ($self, $cand_i, $cand_j) = @_;
    return 0 if not exists $self->{pair}{$cand_i}; # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->preference() // 0; # return preference, or zero if the node didn't have it
}

# set a candidate-pair margin of victory (mov) in matrix entry
sub set_mov
{
    my ($self, $cand_i, $cand_j, $mov) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->mov($mov);
}

# get candidate-pair margin of victory (mov) in matrix entry
sub get_mov
{
    my ($self, $cand_i, $cand_j) = @_;
    return 0 if not exists $self->{pair}{$cand_i}; # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_mov();
}

# lock a candidate-pair
sub set_lock
{
    my ($self, $cand_i, $cand_j) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->set_lock();
}

# get lock status in matrix entry
sub get_lock
{
    my ($self, $cand_i, $cand_j) = @_;
    return 0 if not exists $self->{pair}{$cand_i}; # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_lock();
}

# add a directed link in the graph
sub graph_add_link
{
    my ($self, $cand_i, $cand_j) = @_;

    # tally links in graph
    if (not $self->graph_exists($cand_i)) {
        $self->graph_set($cand_i, {});
    }
    $self->{graph}{$cand_i}{$cand_j} = 1;
    return;
}

# get a choice/candidate's total locked wins
sub cand_total_wins
{
    my ($self, $cand) = @_;
    return 0 if not $self->graph_exists($cand);
    return scalar keys %{$self->graph_accessor($cand)};
}

# get a choice/candidate's total of all margins of victory
sub cand_total_mov
{
    my ($self, $cand) = @_;
    my $total = 0;
    foreach my $opponent (keys %{$self->pair_get($cand)}) {
        $total += $self->get_mov($cand, $opponent);
    }
    return $total;
}

# return a ballot item as a list, whether it was a single scalar or a tie-group set
# This code was borrowed from Schulze, which allows ties on input. Ranked Pairs should never receive ties from Core.
# To allow for experimentation, this code was preserved here anyway.
sub item2list
{
    my $item = shift;
    if (ref $item eq 'Set::Tiny') {
        return ($item->elements());
    }
    return ($item);
}

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
sub tally_preferences
{
    my $self = shift;

    # compute preferences from ballots: loop through votes tallying preferences
    my @choices = $self->choices_keys(); # list of candidates
    foreach my $combo ($self->ballots_keys()) {
        # loop through choices on the ballot
        my $ballot = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();

        # choices contained on the ballot have all pairwise preferences recorded
        my %seen_on_ballot;
        for (my $pos1=0; $pos1 < scalar @ballot_items - 1; $pos1++) {
            # mark all following items on the ballot as less-favored than the current item
            # This adds 2 levels of loops to support potential ties within each position.
            my @item1 = item2list($ballot_items[$pos1]);
            foreach my $cand_i (@item1) {
                $seen_on_ballot{$cand_i} = 1;
                for (my $pos2=$pos1+1; $pos2 < scalar @ballot_items; $pos2++) {
                    my @item2 = item2list($ballot_items[$pos2]);
                    foreach my $cand_j (@item2) {
                        $seen_on_ballot{$cand_j} = 1;
                        $self->add_preference($cand_i, $cand_j, $ballot->{quantity});
                    }
                }
            }
        }

        # all choices omitted from the ballot (unranked) count as less-preferred than all on the ballot
        # no comparison is made between unranked choices - the voter didn't provide data on that
        my @included = keys %seen_on_ballot;
        my @omitted = grep {not exists $seen_on_ballot{$_}} @choices;
        foreach my $in (@included) {
            foreach my $out (@omitted) {
                $self->add_preference($in, $out, $ballot->{quantity});
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
    foreach my $cand_i ($self->pair_keys()) {
        foreach my $cand_j (keys %{$self->pair_accessor($cand_i)}) {
            # skip if we've already computed this pair in the reverse candidate order
            next if exists $self->{pair}{$cand_i}{$cand_j}{mov};

            # set up margin of victory (mov) and tentative i-j candidate pair (may be reordered)
            my $pref_ij = $self->get_preference($cand_i, $cand_j);
            my $pref_ji = $self->get_preference($cand_j, $cand_i);
            $self->set_mov($cand_i, $cand_j, $pref_ij - $pref_ji);
            $self->set_mov($cand_j, $cand_i, $pref_ji - $pref_ij);
            my @cand = ($cand_i, $cand_j);

            # handle tied i = j link
            if ($pref_ij == $pref_ji) {
                # tied candidates ordered alphabetically for consistent results in testing
                $self->majority_push(PrefVote::RankedPairs::Majority->new(cand => [sort @cand]));
                next;
            }

            # handle i < j link
            if ($pref_ij < $pref_ji) {
                # candidates in reverse order for j > i
                $self->majority_push(PrefVote::RankedPairs::Majority->new(cand => [reverse @cand]));
                next;
            }

            # handle i > j link
            $self->majority_push(PrefVote::RankedPairs::Majority->new(cand => [@cand]));
        }
    }

    # sort candidate pairs list by margin of victory
    $self->majority_sort(\&PrefVote::RankedPairs::Majority::cmp_pair);
    return;
}

# depth first search looking for a specific node (to prevent a cycle)
sub depth_first_search
{
    my ($self, %opts) = @_;
    my $target = $opts{target};
    my $node = $opts{node};
    my $visited = $opts{visited};

    # skip if this node has already been visited
    if ($visited->{$node} // 0) {
        return 0;
    }

    # set this node as visited
    $visited->{$node} = 1;

    # skip if there are no adjacent nodes
    return 0 if not $self->graph_exists($node);

    # inspect adjacent nodes for the target, return true if found
    # otherwise traverse them
    foreach my $adj (keys %{$self->graph_get($node)}) {
        if ($adj eq $target) {
            return 1;
        }
        if ($self->depth_first_search(target => $target, node => $adj, visited => $visited)) {
            return 1;
        }
    }

    # nothing found, return false (not found)
    return 0;
}

# check if a candidate pair conflicts with previous pairs
sub is_conflict
{
    my ($self, $cand1, $cand2) = @_;

    # skip ties - either direction is in conflict against locking
    if ($self->get_mov($cand1, $cand2) == 0) {
        $self->debug_print("is_conflict($cand1, $cand2) -> true (tie)");
        return 1;
    }

    # it's a conflict if the opposite order/direction of the same pair is locked
    if ($self->get_lock($cand2, $cand1) != 0) {
        $self->debug_print("is_conflict($cand1, $cand2) -> true (reverse direction is locked)");
        return 1;
    }

    # do a depth-first search of the graph to detect a path from cand2 to cand1, which would cause a cycle
    if ($self->depth_first_search(target => $cand1, node => $cand2, visited => {})) {
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
    for (my $maj_index=0; $maj_index < $self->majority_count(); $maj_index++) {
        # find majority item (candidate pair) for this pass through the loop
        my $majority = $self->majority_get($maj_index);
        my @pair = $majority->cands();

        # skip conflicts
        if ($self->is_conflict(@pair)) {
            next;
        }

        # lock the listed candidate pair
        $self->set_lock(@pair);

        # tally links in graph
        $self->graph_add_link($pair[0], $pair[1]);
    }
    return;
}

# comparison function for sorting results
sub cmp_choice
{
    my ($self, $cand1, $cand2) = @_;

    # 1st comparison: Condorcet table wins in descending order
    my $total_wins1 = $self->cand_total_wins($cand1);
    my $total_wins2 = $self->cand_total_wins($cand2);
    if ($total_wins1 != $total_wins2) {
        return $total_wins2 <=> $total_wins1;
    }

    # 2nd comparison: choice/candidate's average ballot placement in ascending order
    my $tiebreak_disabled = $self->config("no-tiebreak") // 0; # config flag to disable tie-breaking by avg rank
    if (not $tiebreak_disabled) {
        my $place1 = $self->average_ranking($cand1);
        my $place2 = $self->average_ranking($cand2);
        if (not fp_equal($place1, $place2)) {
            return fp_cmp($place1, $place2);
        }
    }

    return 0;
}

# calculate result ordering from graph
sub graph_to_order
{
    my $self = shift;

    # sort list of choices to begin graph traversal
    my @choices = sort { $self->cmp_choice($a, $b) } $self->choices_keys(); # list of candidates ordered by cmp_choice

    # detect ties and build result rankings
    while (scalar @choices) {
        my $leader = shift @choices;
        my $tie_group = set($leader);
        while ((scalar @choices > 0) and ($self->cmp_choice($leader, $choices[0]) == 0)) {
            $tie_group->insert(shift @choices);
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
    $self->save_c2r(winners => $self->winners());

    #$self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

  use PrefVote::RankedPairs;
  %vote_params = ( "name" => "value", ... );
  $vote = new PrefVote::RankedPairs \%vote_params;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 1

=item winners

=item pair

=item majority

=item graph

=back

=head1 METHODS

=over 1

=item make_pair_node 

=item add_preference

=item get_preference

=item set_mov

=item get_mov

=item set_lock

=item get_lock

=item graph_add_link

=item cand_total_wins

=item cand_total_mov

=item tally_preferences

=item sort_pairs

=item depth_first_search

=item is_conflict

=item lock_pairs

=item cmp_choice

=item graph_to_order

=item count

=back

=head1 FUNCTIONS

=over 1

=item item2list

=back

=head1 SEE ALSO

L<PrefVote::Core>

Ranked Pairs voting method on Wikipedia L<https://en.wikipedia.org/wiki/Ranked_pairs>

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
