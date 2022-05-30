# PrefVote::Schulze::Round
# ABSTRACT: internal voting-round structure used by PrefVote::Schulze
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# Schulze voting round class
#
package PrefVote::Schulze::Round;

use autodie;
use Clone qw(clone);
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core;
use PrefVote::Schulze::PairData;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Bool ArrayRef HashRef InstanceOf Map);
extends 'PrefVote::Core::Round';
use PrefVote::Core::Float qw(fp_equal fp_cmp float_internal PVPositiveOrZeroNum);

# constants
Readonly::Hash my %blackbox_spec => (
    pair => [qw(hash hash PrefVote::Schulze::PairData)],
    win_flag => [qw(hash bool)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec,
    parent => 'PrefVote::Core::Round');

# 2-level hash of choice/candidate-pair preference totals
# This shows total votes where a 1st index choice/candidate is preferred over a 2nd index choice/candidate.
# Totals are unidirectional and must be combined with their corresponding opposite pair to determine which
# choice/candidate is actually more favored.
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
        win_flag_clear => 'clear',
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
    return 0 if not exists $self->{pair}{$cand_i}; # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # use zero if the node doesn't exist
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
    return 0 if not exists $self->{pair}{$cand_i}; # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # use zero if the node doesn't exist
    $self->make_pair_node($cand_i, $cand_j);
    return $self->{pair}{$cand_i}{$cand_j}->strength($value) // 0;
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
    return 0 if not exists $self->{pair}{$cand_i}; # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j}; # use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->win_order() // 0; # return win_order, or zero if the node didn't have it
}

# return a ballot item as a list, whether it was a single scalar or a tie-group set
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
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # If this is not the first round, get preference data from previous round
    if (exists $self->{prev}) {
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

    # If this is the first round, compute preferences from ballots.
    # loop through votes tallying preferences
    my @choices = $schulze_ref->choices_keys(); # list of candidates
    foreach my $combo ($schulze_ref->ballots_keys()) {
        # loop through choices on the ballot
        my $ballot = $schulze_ref->ballots_get($combo);
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

# compute path between two candidates if it exists
sub get_path
{
    my ($self, $src, $dest) = @_;
    $self->debug_print("get_path ($src → $dest) begin");

    # pseudocode for getting the path from Floyd–Warshall algorithm
    # procedure Path(src, dest)
    # if next[src][dest] = null then
    #     return []
    # path = [src]
    # while src ≠ dest
    #     src ← next[src][dest]
    #     path.append(src)
    # return path

    # this builds the path as a list of nodes in reverse order
    my $pred = $self->get_predecessor($src, $dest);
    if (not defined $pred) {
        return;
    }
    my @nodes = ($src);
    my %nodes_seen;
    while ($src ne $dest) {
        $src = $self->get_predecessor($src, $dest);
        push @nodes, $src;
        if (not defined $src) {
            return;
        }
        if (exists $nodes_seen{$src}) {
            # break what would be and infinite loop
            return;
        }
        $nodes_seen{$src} = 1;
        $self->debug_print("get_path ($src → $dest) node $src");
        push @nodes, $src;
    }
    $self->debug_print("get_path ($src → $dest) = ".join("-", @nodes));
    return @nodes;
}

# add a path to the history of a route between nodes
sub add_path
{
    my ($self, $src, $dest) = @_;
    $self->debug_print("add_path ($src → $dest) begin");

    $self->make_pair_node($src, $dest);
    my @path = $self->get_path($src, $dest);
    return if (not scalar @path);
    if (not exists $self->{pair}{$src}{$dest}{path_history}) {
        $self->{pair}{$src}{$dest}->path_history([]);
    }
    $self->debug_print("add_path ($src → $dest) ".join("-", @path));
    return $self->{pair}{$src}{$dest}->path_push(\@path);
}

# Schulze algorithm Stage 2: calculation of the strengths of the strongest paths
sub compute_strongest_paths
{
    my $self = shift;

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
    my @candidates = $self->candidates_all(); # list of candidates in this round
    foreach my $i (@candidates) {
        foreach my $j (@candidates) {
            next if $i eq $j;
            foreach my $k (@candidates) {
                next if $i eq $k or $j eq $k;

                # find the minimum strength link on the strongest path from j to i to k
                my $strength_ik = $self->get_strength($i, $k);
                my $strength_ji = $self->get_strength($j, $i);
                my $strength_jk = $self->get_strength($j, $k);
                my $min_strength_ji_ik = ($strength_ji < $strength_ik) ? $strength_ji : $strength_ik;
                if ($strength_jk < $min_strength_ji_ik) {
                    $self->set_strength($j, $k, $min_strength_ji_ik);
                    $self->set_predecessor($j, $k, $self->get_predecessor($i, $k));
                    $self->add_path($j, $k);
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
    $self->debug_print("compute_potential_winners: begin");

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
    my @candidates = $self->candidates_all(); # list of candidates in this round
    foreach my $i (@candidates) {
        my $unbeaten = 1; # assume each candidate is a winner until we find any candidate who beats them
        foreach my $j (@candidates) {
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
        $self->debug_print("compute_potential_winners: ".join(" ", $self->win_flag_keys()));
    }
    return;
}

# read & write accessors for a hash used as the forbidden link table
# This wasn't broken out to its own class because it's only used as a temporary table in a loop in final_rank_links().
# It's a sparse 2D table where we only set values if true. Return 0 (false) if it doesn't exist.
sub get_forbidden
{
    my ($self, $cand1, $cand2, $cand_m, $cand_n) = @_;
    # order names in index to recognize forbidden links either direction
    my $forbid_index = ($cand_m lt $cand_n) ? "$cand_m-$cand_n" : "$cand_n-$cand_m";
    return 0 if not exists $self->{pair}{$cand1}{$cand2}{forbidden}; # just use zero if the node doesn't exist
    return $self->{pair}{$cand1}{$cand2}->forbidden_contains($forbid_index); # true if link forbidden for this pair
}
sub set_forbidden
{
    my ($self, $cand1, $cand2, $cand_m, $cand_n) = @_;
    # order names in index to recognize forbidden links either direction
    my $forbid_index = ($cand_m lt $cand_n) ? "$cand_m-$cand_n" : "$cand_n-$cand_m";
    $self->make_pair_node($cand1, $cand2);
    if (not exists $self->{pair}{$cand1}{$cand2}{forbidden}) {
        $self->{pair}{$cand1}{$cand2}->forbidden(set());
    }
    $self->{pair}{$cand1}{$cand2}->forbidden_insert($forbid_index);
    return;
}

# break a tie - used within the TBRL algorithm loop (see final_rank_links() below)
# Silence Perl::Critic warnings about complexity since this implements the paper's algorithm.
## no critic(ProhibitExcessComplexity)
sub break_tie
{
    my ($self, $m, $n) = @_;

    # set tie_broken flag to false and loop until it gets toggled or all links exhausted
    # ($tie_broken is called "bool1" in the paper's pseudocode)
    my @candidates = $self->candidates_all(); # list of candidates in this round
    my $changes_made = 0;
    my $tie_broken = 0;
    my $counter = 0;
    while (not $tie_broken) {
        $self->debug_print("tie-breaking counter: ".$counter++);

        # declare tied links as forbidden
        foreach my $i (@candidates) {
            foreach my $j (@candidates) {
                next if $i eq $j;
                if ($self->get_strength($m, $n) == $self->get_preference($i, $j)) {
                    $self->set_forbidden($i, $j, $m, $n);
                    $self->debug_print("final_rank_links($m-$n): set_forbidden $i-$j");
                }
            }
        }

        # calculate new strongest path without forbidden links
        foreach my $i (@candidates) {
            foreach my $j (@candidates) {
                next if $i eq $j;
                if ($self->get_forbidden($i, $j, $m, $n)) {
                    my $value = $minimum_link;
                    $self->set_strength($i, $j, $value);
                    $self->debug_print("final_rank_links($m-$n): min-link $i-$j => $value");
                } else {
                    my $value = $self->get_preference($i, $j);
                    $self->set_strength($i, $j, $value);
                    $self->debug_print("final_rank_links($m-$n): pref $i-$j => $value");
                }
            }
        }
        foreach my $i (@candidates) {
            foreach my $j (@candidates) {
                next if $i eq $j;
                foreach my $k (@candidates) {
                    next if $i eq $k or $j eq $k;

                    # find the minimum strength non-forbidden link on the strongest path from j to i to k
                    my $strength_ik = $self->get_strength($i, $k);
                    my $strength_ji = $self->get_strength($j, $i);
                    my $strength_jk = $self->get_strength($j, $k);
                    my $min_strength_ji_ik = ($strength_ji < $strength_ik) ? $strength_ji : $strength_ik;
                    if ($strength_jk < $min_strength_ji_ik) {
                        $self->set_strength($j, $k, $min_strength_ji_ik);
                        $self->debug_print("final_rank_links($m-$n): min-strength $j-$k "
                                ."=> $min_strength_ji_ik");
                    }
                }
            }
        }

        # check if the tie is resolved
        my $q_path_mn = $self->get_strength($m, $n);
        my $q_path_nm = $self->get_strength($n, $m);
        if ($q_path_mn > $q_path_nm) {
            # tie resolved in favor of m
            $self->set_win_order($m, $n, 1);
            $self->set_win_order($n, $m, 0);
            $self->win_flag_set($m, 1);
            $self->win_flag_delete($n, 1);
            $tie_broken = 1;
            $changes_made = 1;
            $self->debug_print("final_rank_links: tie $m/$n broken in favor of $m");
        } elsif ($q_path_nm > $q_path_mn) {
            # tie resolved in favor of n
            $self->set_win_order($n, $m, 1);
            $self->set_win_order($m, $n, 0);
            $self->win_flag_set($n, 1);
            $self->win_flag_delete($m, 1);
            $tie_broken = 1;
            $changes_made = 1;
            $self->debug_print("final_rank_links: tie $m/$n broken in favor of $n");
        } elsif ($q_path_mn == $minimum_link and $q_path_nm == $minimum_link) {
            # tie could not be resolved
            $tie_broken = 1;
            $self->debug_print("final_rank_links: tie $m/$n unresolved");
        }
    }
    return $changes_made;
}
## use critic(ProhibitExcessComplexity)

# Stage 4: tie-breaking ranking of links TBRL (from Schulze 5.1)
# Schulze method can have resolvable ties when the same link is used both directions in a path between two choices.
#
# Note: this is implemented per the paper - it's a very brute-force algorithm. An alternative I tried didn't help.
sub final_rank_links
{
    my $self = shift;

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
    my @candidates = $self->candidates_all(); # list of candidates in this round
    my $changes_made = 0;
    for (my $m_index=0; $m_index<(scalar @candidates)-1; $m_index++) {
        my $m = $candidates[$m_index];
        for (my $n_index=$m_index+1; $n_index<scalar @candidates; $n_index++) {
            my $n = $candidates[$n_index];
            my $path_mn = $self->get_strength($m, $n);
            my $path_nm = $self->get_strength($n, $m);
            if ($path_mn == $path_nm) {
                # we found a tie... these choices/candidates are probably so-called "clones", similar to each other
                $self->debug_print("final_rank_links: tie found between $m and $n in round ".$self->number());
                $changes_made += $self->break_tie($m, $n);
            }
        }
    }

    # compute potential round winners again if any changes were made by tie-breaking
    if ($changes_made) {
        $self->win_flag_clear();
        $self->compute_potential_winners();
    }
    return;
}

# narrow down tied set of winning candidates by average ballot ranking placement
# not from Schulze definition: this uses PrefVote::Core::average_ranking() to break ties that TBRL couldn't
sub narrow_winners
{
    my $self = shift;
    my $schulze_ref = shift; # ref to PrefVote::Schulze object

    # skip step if configuration flag disables PrefVotes's tie-breaking by average rank to strictly follow algorithm
    my $tiebreak_disabled = $self->config("no-tiebreak") // 0; # config flag to disable tie-breaking by avg rank
    return if $tiebreak_disabled;

    # sort winners by average ballot placement order
    my @winning_group = sort {fp_cmp($schulze_ref->average_ranking($a), $schulze_ref->average_ranking($b))}
        $self->win_flag_keys();

    # clear win_flag hash pending re-computation
    $self->win_flag_clear();

    # set win_flag for leader from sorted @winning_group
    my $leader = shift @winning_group;
    $self->win_flag_set($leader, 1);

    # set win_flag for any choice in @winning_group equal to leader (using fp_equal comparison)
    foreach my $cand (@winning_group) {
        if (fp_equal($schulze_ref->average_ranking($leader), $schulze_ref->average_ranking($cand))) {
            $self->win_flag_set($cand, 1);
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
    # This needs the $schulze_ref in order to access ballot data in the first round.
    $self->debug_print("do_computation: tally");
    $self->tally_preferences($schulze_ref);

    # Stage 1: initialization loop is replaced by lazy assignments upon read of undefined candidate-pair
    # matrix values in get_predecessor() and get_strength().

    # Stage 2: calculation of the strengths of the strongest paths (from Schulze 2.3.1)
    $self->debug_print("do_computation: compute paths");
    $self->compute_strongest_paths();

    # Stage 3: calculation of the binary relation 𝚶 and the set of potential winners (from Schulze 2.3.1)
    $self->debug_print("do_computation: compute potential winners");
    $self->compute_potential_winners();

    # Stage 4: tie-breaking ranking of links TBRL (from Schulze 5.1)
    # we use the TBRL method because PrefVote system fully ranks results even for 1-seat races
    if (scalar $self->win_flag_keys() != 1) {
        $self->debug_print("do_computation: break ties");
        $self->final_rank_links();
    }

    # Stage 5: additional tie-breaking by average ballot placement (added by PrefVote, not in Schulze definition)
    if (scalar $self->win_flag_keys() != 1) {
        $self->debug_print("do_computation: supplemental tie-breaking");
        $self->narrow_winners($schulze_ref);
    }

    # set round winner(s) from candidate(s) with win_flag set - more than one indicates a tie for this place
    $self->debug_print("do_computation: set result ".join(" ", $self->win_flag_keys()));
    $self->set_result(type => "winner", name => [$self->win_flag_keys()]);

    return;
}


1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Schulze::Round - internal voting-round structure used by PrefVote::Schulze

=head1 SYNOPSIS

  # snippet from unit tests
  use PrefVote::Schulze::Round;
  my @candidate_names = qw(A B C D E F);
  my $schulze_round_ref = PrefVote::Schulze::Round->new(number => 1, candidates => \@candidate_names);
  schulze_round_ref->add_preference("A", "F", 1);
  my $pref_a_f = schulze_round_ref->get_preference("A", "F");

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

A PrefVote::Schulze::Round object contains data for one round of vote-counting in the Schulze Method.
It should only be called from L<PrefVote::Schulze>.

The Schulze Method counts votes in a Condorcet-style pairwise comparison of choices or candidates.
While all Condorcet methods are the same in making a choice/candidate the winner if it wins pairwise comparisons
against all other choices/candidates.
All the methods differ in how they do their computation and particularly in how they handle counts where there
isn't a clear Condorcet winner.
PrefVote::Schulze::Round is the core of the Schulze algorithm, which arranges choices into an ordering using
a graph structure of pairwise comparisons between choices/candidates.

=head1 ATTRIBUTES

=over 1

=item pair

This is a two-dimensional hash table of pairwise comparisons between choices/candidates.
Each index is a choice/candidate id code assigned by L<PrefVote::Core>.

Following the customary notation of Schulze's algorithm to call the first subscript i and the second one j,
each item is a comparison of i to j, and does not include data for the opposite direction comparison of j to i,
which exists in the pair table under those subscripts.

Each entry of the table, when they exist, contains a reference to a L<PrefVote::Schulze::PairData> object.
These initially only contain a count of votes for choice/candidate i over j.
As the Schulze algorithm progresses, data for each edge in the graph computation is stored here,
including strength of the strongest path from i to j,
a flag to indicate if i→j is the winning direction for the graph edge,
or a flag used by the Schulze Method for tie-breaking indicating the edge has been forbidden
to prevent ambiguous usage of the same edge in both directions of the pairwise comparisons for the choice/candidate.

This is a sparse table. So entries are optional. For example, there should not be any entries where i equals j
because a choice/candidate can only be pairwise-compared to other choices/candidates in a ranked choice ballot.

=item win_flag

This is a hash table indexed by L<PrefVote::Core> choice/candidate id code.
Each element contains a boolean flag, defaulting to false if non-existent,
indicating the choice/candidate is a winner of the round.

Ties are possible, which would be indicated by more than one choice/candidate with this flag set.

=back

=head1 METHODS

=over 1

=item make_pair_node( i, j)

If the node doesn't already exist, it creates a L<PrefVote::Schulze::PairData> object as the pair node i→j.

=item add_preference( i, j, quantity)

adds to the pair node i→j with quantity added to the number of votes favoring candidate i over j.

=item get_preference(i, j)

reads the pair node i→j and returns the value of the preference of i over j.

=item set_predecessor(i, j, value)

Used for graph analysis in the Schulze Method, this sets the predecessor value for i→j.
See the Schulze algorithm definition for details.

=item get_predecessor

returns the graph predecessor value for i→j.

=item set_strength

=item get_strength

=item set_win_order

=item get_win_order

=item tally_preferences

=item get_path

=item add_path

=item compute_strongest_paths

=item compute_potential_winners

=item get_forbidden

=item set_forbidden

=item break_tie

=item final_rank_links

=item narrow_winners

=item do_computation

=back

=head1 FUNCTIONS

=over 1

=item item2list

=back

=head1 SEE ALSO

L<PrefVote::Schulze>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
