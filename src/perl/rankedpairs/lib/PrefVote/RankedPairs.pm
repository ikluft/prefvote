# PrefVote::RankedPairs
# ABSTRACT: Ranked Pairs vote counting module for PrefVote
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
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
use PrefVote::Core::Set qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners => [qw(list set string)],
    pair => [qw(hash hash PrefVote::RankedPairs::PairData)],
    majority => [qw(array PrefVote::RankedPairs::Majority)],
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
        pair_keys => 'keys',
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

# direct-lock a candidate-pair
sub set_direct_lock
{
    my ($self, $cand_i, $cand_j) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->set_direct_lock();
}

# indirect-lock a candidate-pair
sub set_indirect_lock
{
    my ($self, $cand_i, $cand_j) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->set_indirect_lock();
}

# get lock status in matrix entry
sub get_lock
{
    my ($self, $cand_i, $cand_j) = @_;
    return 0 if not exists $self->{pair}{$cand_i}; # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_lock();
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

    # create list of candidate pairs
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
    $self->majority_sort(\&PrefVote::RankedPairs::Majority::pair_cmp);
    return;
}

# check if a candidate pair conflicts with previous pairs
sub is_conflict
{
    my ($self, $cand1, $cand2) = @_;

    # skip ties - either direction is in conflict against locking
    if ($self->get_mov($cand1, $cand2) == 0) {
        return 1;
    }

    # it's a conflict if the opposite order/direction of the same pair is locked
    return $self->get_lock($cand2, $cand1) != 0;
}

# set indirect locks on downstream links
sub graph_locks
{
    my ($self, $start, @seen_nodes) = @_;
    $self->debug_print("graph_locks($start -> ".join(" ", @seen_nodes)."}");

    # skip nodes already seen
    foreach my $seen (@seen_nodes) {
        return if $start eq $seen;
    }

    # traverse graph
    foreach my $subnode (keys %{$self->graph_get($start)}) {
        # set indirect locks for each node seen on this path
        foreach my $seen_node (@seen_nodes) {
            $self->set_indirect_lock($seen_node, $subnode);
        }

        # traverse the graph recursively from this node
        $self->graph_locks($subnode, @seen_nodes, $subnode)
    }
    return;
}

# lock candidtate pairs which don't conflict with earlier pairs
sub lock_pairs
{
    my $self = shift;

    # loop through sorted majority-pair list:
    # lock pairs which don't conflict with earlier ones
    #   direct lock for pairs as listed
    #   indirect lock for pairs implied by earlier locks (if A>B and B>C then A>C)
    for (my $maj_index=0; $maj_index < $self->majority_count(); $maj_index++) {
        # find majority item (candidate pair) for this pass through the loop
        my $majority = $self->majority_get($maj_index);
        my @pair = $majority->cands();

        # skip conflicts
        if ($self->is_conflict(@pair)) {
            next;
        }

        # direct-lock the listed candidate pair
        $self->set_direct_lock(@pair);

        # tally links in a graph
        if (not $self->graph_exists($pair[0])) {
            $self->graph_set($pair[0], {});
        }
        $self->{graph}{$pair[0]}{$pair[1]} = 1;

        # set indirect locks on downstream pairs implied by existing pairs
        $self->graph_locks($pair[0]);
    }
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

    $self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    # TODO
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::RankedPairs - Ranked Pairs Method vote counting module for PrefVote

=head1 SYNOPSIS

  use PrefVote::RankedPairs;
  %vote_params = ( "name" => "value", ... );
  $vote = new PrefVote::RankedPairs \%vote_params;

=head1 DESCRIPTION


=head1 SEE ALSO

L<PrefVote::Core>

Ranked Pairs voting method on Wikipedia L<https://en.wikipedia.org/wiki/Ranked_pairs>

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
