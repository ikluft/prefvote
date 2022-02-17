# PrefVote::Schulze::Round
# ABSTRACT: internal voting-round structure used by PrefVote::Schulze
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# Schulze voting round class
#
package PrefVote::Schulze::Round;

use autodie;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Bool ArrayRef HashRef InstanceOf Map);
extends 'PrefVote::Core::Round';
use PrefVote::Core::Float qw(float_internal PVPositiveOrZeroNum);

# constants
Readonly::Hash my %blackbox_spec => (
    pair => [qw(hash hash PrefVote::Schulze::PairData)],
    win_flag => [qw(hash bool)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec,
    parent => 'PrefVote::Core::Round');

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is => 'rw',
    isa => HashRef[HashRef[InstanceOf['PrefVote::Schulze::PairData']]],
    default => sub { return {} },
);

# winner list
has win_flag => (
    is => 'rw',
    isa => HashRef[Bool],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        win_flag_count => 'count',
        win_flag_delete => 'delete',
        win_flag_empty => 'is_empty',
        win_flag_exists => 'exists',
        win_flag_get => 'get',
        win_flag_keys => 'keys',
        win_flag_set => 'set',
    },
);

# internal cache variables
my $minimum_link; # minimum link value, for use in tie-breaking algorithm

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

# set strength of strongest path from candidate i to j
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

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
sub tally_preferences
{
    my $self = shift;
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # If this is not the first round, get preference data from previous round
    if (not exists $self->{prev}) {
        # get preference data from previous round
        my $prev = $self->{prev};
        my @round_candidates = $self->candidates_all();
        foreach my $cand1 (@round_candidates) {
            next if not exists $prev->{pair}{$cand1};
            foreach my $cand2 (@round_candidates) {
                next if $cand1 eq $cand2;
                next if not exists $prev->{pair}{$cand1}{$cand2};
                if (exists $prev->{pair}{$cand1}{$cand2}{preference}) {
                    $self->add_preference($cand1, $cand2, $prev->{pair}{$cand1}{$cand2}{preference});
                }
            }
        }
        return;
    }

    # If this is not the first round, compute preferences from ballots.
    # loop through votes tallying preferences
    foreach my $combo ($schulze_ref->ballots_keys()) {
        # loop through choices on the ballot
        my $ballot = $schulze_ref->ballots_get($combo);
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
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # from Schulze algorithm definition 2.3.1:
    # Stage 2 calculation of the strengths of the strongest paths
    # (lack of comments in the pseudocode is as shown in the paper - see below where I added some in the code)
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
    my @choices = $schulze_ref->get_choices(); # list of ballot choices
    foreach my $i (@choices) {
        foreach my $j (@choices) {
            next if $i eq $j;
            foreach my $k (@choices) {
                next if $i eq $k or $j eq $k;

                # find the minimum strength link on the strongest path from j to i to k
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

# from Schulze algorithm definition 2.3.1:
# Stage 3: calculation of the binary relation 𝚶  and the set of potential winners
sub compute_potential_winners
{
    my $self = shift;
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # Schulze algorithm definition of Stage 3 calculation of the binary relation 𝚶 and the set of potential winners:
    # (lack of comments in the pseudocode is as shown in the paper - see below where I added some in the code)
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
    my @choices = $schulze_ref->get_choices(); # list of ballot choices
    foreach my $i (@choices) {
        my $unbeaten = 1; # assume each candidate is a winner until we find any candidate who beats them
        foreach my $j (@choices) {
            next if $i eq $j;

            # save minimum link value seen in the matrix for later use in tie detection and breaking
            {
                my $pref_ji = $self->get_preference($j, $i);
                if ((not defined $minimum_link) or $minimum_link > $pref_ji) {
                    $minimum_link = $pref_ji;
                }
            }

            # check if j beats i
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
            # i is a potential winner (and if it is the only one then it will be the winner)
            $self->win_flag_set($i, 1);
        }
    }
    return;
}

# read & write accessors for alt_path, used in tie-breaking ranking of links (TBRL)
# This wasn't broken out to its own class because it's only used as a temporary table in a loop in final_rank_links().
# It's a 2D table where we compute temporary new values for path strengths
sub get_alt_path
{
    # read the value
    my ($q_hash, $i, $j) = @_;
    return $q_hash->{$i}{$j} // 0;
}
sub set_alt_path
{
    my ($q_hash, $i, $j, $value) = @_;
    if (not exists $q_hash->{$i}) {
        $q_hash->{$i} = {};
    }
    $q_hash->{$i}{$j} = $value;
    return $value;
}

# read & write accessors for a hash used as the forbidden link table
# This wasn't broken out to its own class because it's only used as a temporary table in a loop in final_rank_links().
# It's a sparse 2D table where we only set values if true. Return 0 (false) if it doesn't exist.
sub get_forbidden
{
    # read the value if it exists, 0 if not
    my ($f_hash, $i, $j) = @_;
    return $f_hash->{$i}{$j} // 0;
}
sub set_forbidden
{
    # write the value to the 2D table if it's true
    # skip it if false since undefined will have the same result
    my ($f_hash, $i, $j, $value) = @_;
    if ($value) {
        if (not exists $f_hash->{$i}) {
            $f_hash->{$i} = {};
        }
        $f_hash->{$i}{$j} = 1;
    }
    return $value ? 1 : 0;
}

# Stage 4: tie-breaking ranking of links TBRL (from Schulze 5.1)
# we use the TBRL method because PrefVote system fully ranks results even for 1-seat races
# Note: this is initially implemented per the paper, but is inefficient ( O(n⁵) - srsly? ) and needs attention
# TODO: replace Schulze 5.1 with improved algorithm to follow paths directly to find ties in opposing common links
sub final_rank_links
{
    my $self = shift;
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # defintion of Stage 4 TBRL from Schulze 5.1
    # (lack of comments in the pseudocode is as shown in the paper - see below where I added some in the code)
    #   xy : = min σ { ij | i,j ∈ {1,...,C}, i ≠ j }
    #   for m : = 1 to C–1
    #       for n : = m+1 to C
    #           if ( Pσ [m,n] ≈σ Pσ[n,m] ) then
    #               Qσ [m,n] : = Pσ[m,n]
    #               for i : = 1 to C
    #                   for j : = 1 to C
    #                       if ( i ≠ j ) then
    #                           forbidden[i,j] : = false
    #               bool1 : = false
    #               while ( bool1 = false )
    #                   for i : = 1 to C
    #                       for j : = 1 to C
    #                           if ( i ≠ j ) then
    #                               if ( Qσ[m,n] ≈σ ij ) then
    #                                   forbidden[i,j] : = true
    #                   for i : = 1 to C
    #                       for j : = 1 to C
    #                           if ( i ≠ j ) then
    #                               if ( forbidden[i,j] = true ) then
    #                                   Qσ[i,j] : = xy
    #                               else
    #                                   Qσ[i,j] : = ij
    #                   for i : = 1 to C
    #                       for j : = 1 to C
    #                           if ( i ≠ j ) then
    #                               for k : = 1 to C
    #                                   if ( i ≠ k ) then
    #                                       if ( j ≠ k ) then
    #                                           if ( Qσ[j,k] <σ minσ { Qσ[j,i], Qσ[i,k] } ) then
    #                                               Qσ[j,k] : = minσ { Qσ[j,i], Qσ[i,k] }
    #                   if ( Qσ[m,n] >σ Qσ[n,m] ) then
    #                       𝚶final(σ) : = 𝚶final(σ) + {mn}
    #                       𝐒final(σ) : = 𝐒final(σ) \ {n}
    #                       bool1 : = true
    #                   else
    #                       if ( Qσ[m,n] <σ Qσ[n,m] ) then
    #                           𝚶final(σ) : = 𝚶final(σ) + {nm}
    #                           𝐒final(σ) : = 𝐒final(σ) \ {m}
    #                           bool1 : = true
    #                       else
    #                       if ( Qσ[m,n] = xy and Qσ [n,m] = xy ) then
    #                           bool1 : = true

    # note: lowest link value $minimum_link was computed for a baseline in compute_potential_winners() loop
    # and saved in a file-scoped variable
    # ($minimum_link is called "xy" in the paper's pseudocode)

    # nested loops m,n through candidates/choices looking for ties
    # attempt to break ties by marking cloned links in tied paths as forbidden and recomputing those strongest paths
    # (This uses numeric loop indices, different from the list of strings in compute_strongest_paths().  In the
    # complexity of the spec, numbers looked necessary. But after implementation that apparently wasn't the case.
    # It may get converted to loop through the list of string choices like compute_strongest_paths().)
    my @choices = $schulze_ref->get_choices(); # list of ballot choices
    my %alt_path; # alternate path strength routing around forbidden links (called "Qσ" in the paper's pseudocode)
    for (my $m_index=0; $m_index<(scalar @choices)-1; $m_index++) {
        for (my $n_index=$m_index+1; $n_index<scalar @choices; $n_index++) {
            my $path_mn = $self->get_strength($choices[$m_index], $choices[$n_index]);
            my $path_nm = $self->get_strength($choices[$n_index], $choices[$m_index]);
            if ($path_mn == $path_nm) {
                # we found a tie... these choices/candidates are probably so-called "clones", similar to each other

                # forbidden table keeps track of links forbidden for m-n and n-m paths in order to break the tie
                # it is a new empty hash, which allows us to skip initializing every element to zero
                # set_forbidden() only saves items set to true
                # get_forbidden() returns true if the entry exists, false if it doesn't exist
                my %forbidden;

                # set alternate path strength for m,n from actual m,n
                set_alt_path(\%alt_path, $choices[$m_index], $choices[$n_index], $path_mn);

                # set tie_broken flag to false and loop until it gets toggled or all links exhausted
                # ($tie_broken is called "bool1" in the paper's pseudocode)
                my $tie_broken = 0;
                while (not $tie_broken) {
                    # declare tied links as forbidden
                    for (my $i_index=0; $i_index<(scalar @choices); $i_index++) {
                        for (my $j_index=0; $j_index<scalar @choices; $j_index++) {
                            next if $i_index == $j_index;
                            if (get_alt_path(\%alt_path, $choices[$m_index], $choices[$n_index])
                                == $self->get_preference($choices[$i_index], $choices[$j_index]))
                            {
                                set_forbidden(\%forbidden, $choices[$i_index], $choices[$j_index], 1);
                            }
                        }
                    }

                    # calculate new strongest path without forbidden links
                    for (my $i_index=0; $i_index<(scalar @choices); $i_index++) {
                        for (my $j_index=0; $j_index<scalar @choices; $j_index++) {
                            next if $i_index == $j_index;
                            if (get_forbidden(\%forbidden, $choices[$i_index], $choices[$j_index])) {
                                set_alt_path(\%alt_path, $choices[$i_index], $choices[$j_index], $minimum_link);
                            } else {
                                set_alt_path(\%alt_path, $choices[$i_index], $choices[$j_index],
                                    $self->get_preference($choices[$i_index], $choices[$j_index]));
                            }
                        }
                    }
                    for (my $i_index=0; $i_index<(scalar @choices); $i_index++) {
                        for (my $j_index=0; $j_index<scalar @choices; $j_index++) {
                            next if $i_index == $j_index;
                            for (my $k_index=0; $k_index<scalar @choices; $k_index++) {
                                next if $i_index == $k_index or $j_index == $k_index;

                                # find the minimum strength non-forbidden link on the strongest path from j to i to k
                                my $strength_ik = get_alt_path(\%alt_path, $choices[$i_index], $choices[$k_index]);
                                my $strength_ji = get_alt_path(\%alt_path, $choices[$j_index], $choices[$i_index]);
                                my $strength_jk = get_alt_path(\%alt_path, $choices[$j_index], $choices[$k_index]);
                                my $min_strength_ji_ik = ($strength_ji < $strength_ik) ? $strength_ji : $strength_ik;
                                if ($strength_jk < $min_strength_ji_ik) {
                                    set_alt_path(\%alt_path, $choices[$j_index], $choices[$k_index],
                                        $min_strength_ji_ik);
                                }
                            }
                        }
                    }
                    
                    # check if the tie is resolved
                    my $q_path_mn = get_alt_path(\%alt_path, $choices[$m_index], $choices[$n_index]);
                    my $q_path_nm = get_alt_path(\%alt_path, $choices[$n_index], $choices[$m_index]);
                    if ($q_path_mn > $q_path_nm) {
                        # tie resolved in favor of m
                        $self->set_win_order($choices[$m_index], $choices[$n_index], 1);
                        $self->set_win_order($choices[$n_index], $choices[$m_index], 0);
                        $self->win_flag_set($choices[$m_index], 1);
                        $self->win_flag_delete($choices[$n_index], 1);
                        $tie_broken = 1;
                    } elsif ($q_path_nm > $q_path_mn) {
                        # tie resolved in favor of n
                        $self->set_win_order($choices[$n_index], $choices[$m_index], 1);
                        $self->set_win_order($choices[$m_index], $choices[$n_index], 0);
                        $self->win_flag_set($choices[$n_index], 1);
                        $self->win_flag_delete($choices[$m_index], 1);
                        $tie_broken = 1;
                    } elsif ($q_path_mn == $minimum_link and $q_path_nm == $minimum_link) {
                        # tie could not be resolved
                        $tie_broken = 1;
                    }
                }
            }
        }
    }
    return;
}

# perform computation for a round to find the nth-place ranked choice/candidate
sub do_computation
{
    my $self = shift;
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # preparation: convert ballot preferences to candidate-pair preference totals, or obtain them from previous round
    $self->tally_preferences();

    # Stage 1: initialization loop is replaced by lazy assignments upon read of undefined candidate-pair
    # matrix values in get_predecessor() and get_strength().

    # Stage 2: calculation of the strengths of the strongest paths (from Schulze 2.3.1)
    $self->compute_strongest_paths($schulze_ref);

    # Stage 3: calculation of the binary relation 𝚶 and the set of potential winners (from Schulze 2.3.1)
    $self->compute_potential_winners($schulze_ref);

    # Stage 4: tie-breaking ranking of links TBRL (from Schulze 5.1)
    # we use the TBRL method because PrefVote system fully ranks results even for 1-seat races
    $self->final_rank_links($schulze_ref);

    # TODO: set round winner

    return;    
}


1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Schulze::Round - internal voting-round structure used by PrefVote::Schulze

=head1 SYNOPSIS


=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

=head1 SEE ALSO

L<PrefVote::Schulze>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
