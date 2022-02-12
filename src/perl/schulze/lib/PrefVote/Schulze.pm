# PrefVote::Schulze
# ABSTRACT: Schulze Method vote counting module for PrefVote
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Schulze;

use autodie;
use Data::Dumper;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Bool Str ArrayRef HashRef InstanceOf);
use PrefVote::Core::Set qw(Set);
use PrefVote::Schulze::PairData;
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    pair => [qw(hash hash PrefVote::Schulze::PairData)],
    winner => [qw(hash bool)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote::Core');

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is => 'rw',
    isa => HashRef[HashRef[InstanceOf['PrefVote::Schulze::PairData']]],
    default => sub { return {} },
);

# winner list
has winner => (
    is => 'rw',
    isa => HashRef[Bool],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        winner_count => 'count',
        winner_empty => 'is_empty',
        winner_exists => 'exists',
        winner_get => 'get',
        winner_keys => 'keys',
        winner_set => 'set',
    },
);

# return a ballot item as a list, whether it was a single scalar or a tie-group set 
sub item2list
{
    my $item = shift;
    if (ref $item eq 'Set::Tiny') {
        return ($item->elements());
    }
    return ($item);
}

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ($self, $cand_i, $cand_j) = @_;
    if (not exists $self->{pair}{$cand_i}) {
        $self->{pair}{$cand_i} = {};
    }
    if (not exists $self->{pair}{$cand_i}{$cand_j}) {
        $self->{pair}{$cand_i}{$cand_j} = PrefVote::Schulze::PairData->new();
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
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # just use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->preference() // 0; # return preference, or zero if the node didn't have it
}

# set predecessor in matrix entry
sub set_predecessor
{
    my ($self, $cand_i, $cand_j, $value) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->predecessor($value);
}

# get predecessor in matrix entry
sub get_predecessor
{
    my ($self, $cand_i, $cand_j) = @_;

    # make sure the node exists even on read because we'll assign default (i) if needed
    $self->make_pair_node($cand_i, $cand_j);

    # get the pred value
    my $pred = $self->{pair}{$cand_i}{$cand_j}->predecessor();

    # if it wasn't defined, assign the default value candidate i
    if (not defined $pred) {
        $self->{pair}{$cand_i}{$cand_j}->predecessor($cand_i);
        $pred = $cand_i;
    }
    return $pred;
}

# set path strength in matrix entry
sub set_strength
{
    my ($self, $cand_i, $cand_j, $value) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->strength($value);
}

# get strength in matrix entry
sub get_strength
{
    my ($self, $cand_i, $cand_j) = @_;

    # make sure the node exists even on read because we'll assign default (preference[i,j]-preference[j,i]) if needed
    $self->make_pair_node($cand_i, $cand_j);

    # get the strength value
    my $strength = $self->{pair}{$cand_i}{$cand_j}->strength();

    # if it wasn't defined, assign the default value preference[i,j]-preference[j,i]
    if (not defined $strength) {
        $strength = $self->get_preference($cand_i, $cand_j) - $self->get_preference($cand_j, $cand_i);
        $self->{pair}{$cand_i}{$cand_j}->strength($strength);
    }
    return $strength;
}

# set a candidate pair (in the given i,j order) as the winning direction
sub set_win_order
{
    my ($self, $cand_i, $cand_j, $value) = @_;
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->win_order($value);
}

# get win_order flag for a candidate pair (in the given i,j order)
sub get_win_order
{
    my ($self, $cand_i, $cand_j) = @_;
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # just use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->win_order() // 0; # return win_order, or zero if the node didn't have it
}

# set strength of strongest path from candidate i to j

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
sub tally_preferences
{
    my $self = shift;

    # loop through votes tallying preferences
    foreach my $combo ($self->ballots_keys()) {
        # loop through choices on the ballot
        my $ballot = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();
        for (my $pos1=0; $pos1 < scalar @ballot_items - 1; $pos1++) {
            # mark all following items on the ballot as less-favored than the current item
            # This adds 2 levels of loops to support potential ties within each position.
            my @item1 = item2list($ballot_items[$pos1]);
            for (my $pos2=$pos1+1; $pos2 < scalar @ballot_items; $pos2++) {
                my @item2 = item2list($ballot_items[$pos2]);
                foreach my $cand_i (@item1) {
                    foreach my $cand_j (@item2) {
                        $self->add_preference($cand_i, $cand_j, $ballot->{quantity});
                    }
                }
            }
        }
    }
    return;
}

# Schulze algorithm Stage 2: calculation of the strengths of the strongest paths
sub compute_strongest_paths
{
    my $self = shift;

    # Schulze algorithm definition of Stage 2 calculation of the strengths of the strongest paths:
    # for i : = 1 to C
    #   for j : = 1 to C
    #       if ( i ≠ j ) then
    #           for k : = 1 to C
    #               if ( i ≠ k ) then
    #                   if ( j ≠ k ) then
    #                       if ( PD[j,k] <D minD { PD[j,i], PD[i,k] } ) then
    #                           PD[j,k] : = minD { PD[j,i], PD[i,k] }
    #                           pred[j,k] : = pred[i,k]

    # nested loops i,j,k through candidates/choices to check if P[j,k] has a lower minimum than P[j,i] & P[i,k]
    my @choices = $self->get_choices();
    foreach my $i (@choices) {
        foreach my $j (@choices) {
            next if $i eq $j;
            foreach my $k (@choices) {
                next if $i eq $k or $j eq $k;
                my $strength_ik = $self->get_strength($i, $k);
                my $strength_ji = $self->get_strength($j, $i);
                my $strength_jk = $self->get_strength($j, $k);
                my $min_strength_ji_ik = ($strength_ji < $strength_ik) ? $strength_ji : $strength_ik;
                if ($strength_jk < $min_strength_ji_ik) {
                    $self->set_strength($j, $k, $min_strength_ji_ik);
                    $self->set_predecessor($j, $k, $self->get_predecessor($i, $k));
                }
            }
        }
    }
    return;
}

# Schulze algorithm Stage 3: calculation of the binary relation  and the set of potential winners
sub compute_potential_winners
{
    my $self = shift;

    # Schulze algorithm definition of Stage 3 calculation of the binary relation 𝚶 and the set of potential winners:
    #   for i : = 1 to C
    #       winner[i] : = true
    #       for j : = 1 to C
    #           if ( i ≠ j ) then
    #               if ( PD[j,i] >D P D[i,j] ) then
    #                   ji ∈ 𝚶
    #                   winner[i] : = false
    #               else
    #                   ji ∉ 𝚶

    # nested loops i,j through candidates/choices eliminating candidates from potential winners if beaten by anyone
    my @choices = $self->get_choices();
    foreach my $i (@choices) {
        my $unbeaten = 1; # assume each candidate is a winner until we find another candidate who beats them
        foreach my $j (@choices) {
            next if $i eq $j;
            if ($self->get_strength($j, $i) > $self->get_strength($i, $j)) {
                # i was beaten - turn off unbeaten flag
                $unbeaten = 0;

                # j-i direction is a winner
                $self->set_win_order($j, $i, 1);
            } else {
                # j-i direction is not a winner
                $self->set_win_order($j, $i, 0);
            }
        }
        if ($unbeaten) {
            # i is a winner
            $self->winner_set($i, 1);
        }
    }
    return;
}

# count votes using Schulze method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # preparation: convert ballot preferences to candidate-pair preference totals
    $self->tally_preferences();

    # Stage 1: initialization loop is replaced by lazy assignments upon read of undefined candidate-pair
    # matrix values in get_predecessor() and get_strength().

    # Stage 2: calculation of the strengths of the strongest paths
    $self->compute_strongest_paths();

    # Stage 3: calculation of the binary relation 𝚶 and the set of potential winners
    $self->compute_potential_winners();

    # TODO
    # work in progress: dump object up to this point
    $self->debug_print("count: ".Dumper($self));

    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Schulze - Schulze Method vote counting module for PrefVote

=head1 SYNOPSIS

  use PrefVote::Schulze;
  %vote_params = ( "name" => "value", ... );
  $vote = new PrefVote::Schulze \%vote_params;

=head1 DESCRIPTION


=head1 SEE ALSO

Schulze Method on Wikipedia L<https://en.wikipedia.org/wiki/Schulze_method>

Schulze Method paper L<https://arxiv.org/abs/1804.02973>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
