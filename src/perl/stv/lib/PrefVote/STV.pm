# PrefVote::STV
# ABSTRACT: single-transferable vote counting module for PrefVote
# Single Transferable Vote (STV) voting and counting module
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::STV;

use autodie;
use Carp qw(croak);
use Clone qw(clone);
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::STV::Round;
use PrefVote::STV::Tally;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
use PrefVote::Core::Set qw(Set);
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners => [qw(list set string)],
    eliminated => [qw(list set string)],
    rounds => [qw(list PrefVote::STV::Round)],
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

# list of names of eliminated candidates in order by occurrence, ties shown by an ArrayRef to the tied candidates
has eliminated => (
    is => 'rw',
    isa => ArrayRef[Set[Str]],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
        eliminated_all => 'all',
        eliminated_count => 'count',
        eliminated_push => 'push',
    },
);

# list of rounds of STV counting
has rounds => (
    is => 'rw',
    isa => ArrayRef[InstanceOf["PrefVote::STV::Round"]],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
        rounds_count => 'count',
        rounds_get => 'get',
        rounds_push => 'push',
    },
);

#
# processing
#
my %result_cache;

# start a new round
sub new_round
{
    my $self = shift;
    my $number = $self->rounds_count()+1;
    
    # pick arguments for first or later rounds
    my @args;
    if ($number == 1) {
        @args = (candidates => [$self->get_choices()]);
    } else {
        @args = (prev => $self->rounds_get(-1));
    }

    # instantiate and save new round
    my $round = PrefVote::STV::Round->new(number => $number, @args);
    $round->init_candidate_tally();
    $self->rounds_push($round);

    return $round;
}

# get ref to current round
sub current_round
{
    my $self = shift;
    return $self->rounds_get(-1);
}

# add winning candidate
sub add_winner
{
    my ($self, @win_list) = @_;

    # save winners in order
    $self->winners_push(set(@win_list));

    # add winners to round result
    my $round = $self->current_round();
    $round->set_result(
        name => clone(\@win_list),
        type => "winner",
    );

    # cache win result for each candidate for handling following rounds
    my $tally = $self->current_round()->tally();
    foreach my $name (@win_list) {
        $result_cache{$name} = {winner => 1, transfer => $tally->{$name}{transfer}};
    }
    return;
}

# add eliminated candidate
sub add_eliminated
{
    my ($self, @elim_list) = @_;

    # save eliminations in order
    $self->eliminated_push(set(@elim_list));

    # add eliminations to round result
    my $round = $self->current_round();
    $round->set_result(
        name => clone(\@elim_list),
        type => "eliminated",
    );

    # cache elimination result for each candidate for handling following rounds
    foreach my $name (@elim_list) {
        $result_cache{$name} = {eliminated => 1};
    }
    return;
}

# check if a candidate won a previous round
# return boolean
sub cand_is_winner
{
    my $self = shift;
    my $cand_name = shift;
    return exists $result_cache{$cand_name}{winner};
}

# check if a candidate was eliminated in a previous round
# return boolean
sub cand_is_eliminated
{
    my $self = shift;
    my $cand_name = shift;
    return exists $result_cache{$cand_name}{eliminated};
}

# get a candidate's transfer ratio from a previous round
# return floating point number, or undef if not a winner
sub cand_transfer_ratio
{
    my $self = shift;
    my $cand_name = shift;
    if (not exists $result_cache{$cand_name}{transfer}) {
        return;
    }
    return $result_cache{$cand_name}{transfer};
}

# initial tally with vote transfers
sub run_tally
{
    my $self = shift;
    my $round = $self->current_round();

    # loop through votes tallying with transfers
    foreach my $combo ($self->ballots_keys()) {
        # loop through choices
        my $ballot = $self->ballots_get($combo);
        my $selection = undef;
        my $fraction = 1;
        my @ballot_items = $ballot->items_all();
        foreach my $choice (@ballot_items) {
            # STV can assume it received only single-item sets in each ballot item
            if ( $self->debug() and ref($choice) ne "" ) {
                print STDERR "choice is ref "
                    .ref($choice)
                    ." in #".$round->votes_used().": "
                    .$ballot->as_string()
                    ." (x".$ballot->quantity().")\n";
            }

            # Handle vote transfers - this is a key point
            # in the STV system.  Note that fractions are
            # used on the transfers to prevent a single
            # vote from effectively counting more than
            # once...
            #
            # If a higher choice won a previous round,
            # apply the fraction of the candidate's votes
            # which were above the quota to the next
            # highest available candidate.  That means
            # this vote is cut into a fraction before
            # transferring it to the next candidate.
            # Note that if more than one choice wins
            # (as will happen after several rounds in
            # this loop to find each candidate's place
            # in the results) then individual ballots
            # may be cut in fractions more than once.
            if ($self->cand_is_winner($choice))
            {
                my $transfer_ratio = $self->cand_transfer_ratio($choice);
                $fraction *= $transfer_ratio;
                next;
            }

            # Candidates in this round are eligible to receive vote transfers.
            # Check for candidates not previously eliminated because previous winners were already filtered out above.
            if (not $self->cand_is_eliminated($choice)) {
                $selection = $choice;
                last;
            }
        }

        if ( defined $selection ) {
            my $sel_ref = $round->tally_get($selection);
            my $votes = $sel_ref->votes();
            my $vote_increment = $fraction * $ballot->{quantity};
            $sel_ref->add_votes($vote_increment);
            $round->add_votes_used($vote_increment);
            #$self->debug_print("run_tally: $selection +$vote_increment (frac=$fraction) ".join("-",@ballot_items));
        }
    }
    return;
}

# process candidates over quota as winners
sub process_winners
{
    my $self = shift;
    my $round = $self->current_round();
    my @round_candidate = $round->candidates_all();

    # quota exceeded - we have a winner!
    my @round_winner;
    my $place = $self->winners_count()+1;
    foreach my $curr_key ( @round_candidate ) {
        # mark all the candidates over quota who are tied for first place as winners
        if ( $round->tally_get($curr_key)->votes() == $round->tally_get($round_candidate[0])->votes() ) {
            my $c_votes = $round->tally_get($curr_key)->votes();
            my $c_surplus = $c_votes - $round->quota();
            my $transfer_ratio = $c_surplus / $c_votes;
            push @round_winner, $curr_key;

            # mark this candidate a winner
            $round->tally_get($curr_key)->mark_as_winner(place => $place, votes => $c_votes, surplus => $c_surplus,
                transfer => $transfer_ratio);
            $self->debug_print( "winner: $curr_key with transfer ratio $transfer_ratio");
        } else {
            last;
        }
    }

    # save result
    $self->add_winner(@round_winner);
    return;
}

# in round with no winner, eliminate last-place candidates
sub eliminate_losers
{
    my $self = shift;
    my $round = $self->current_round();
    my @round_candidate = $round->candidates_all(); # list of candidate names

    # no candidate met quota: eliminate last-place candidate(s) and count again on next round
    my $i;
    my $last_cand = $round_candidate[-1];

    # mark candidates tied for last as eliminated
    my @round_eliminated;
    for ( $i = (scalar @round_candidate)-1; $i > 0; $i-- ) {
        my $indexed_cand = $round_candidate[$i];
        if ( $round->tally_get($last_cand)->votes() == $round->tally_get($indexed_cand)->votes())
        {
            $round->tally_get($indexed_cand)->mark_as_eliminated();
            $self->debug_print("eliminated: ".$indexed_cand."\n");
            push @round_eliminated, $indexed_cand;
        }
    }

    # save result
    $self->add_eliminated(@round_eliminated);
    return;
}

# save per-candidate final results in PrefVote::Core's choice_to_result map
sub save_c2r
{
    my $self = shift;
    my $seats = $self->seats();
    my $place = 0;

    # initialize the result map
    if (not exists $self->{choice_to_result}) {
        $self->{choice_to_result} = {};
    }

    # scan winners to assign places and determine elected seats
    for (my $win_l1=0; $win_l1 < $self->winners_count(); $win_l1++) {
        # candidates in this list are tied if there's more than one
        my @group = $self->{winners}[$win_l1]->members();
        my $disposition;
        if ($place + scalar @group <= $seats) {
            $disposition = "selected";
        } elsif ($place < $seats and $place + scalar @group > $seats) {
            $disposition = "tied";
        } else {
            $disposition = "placed";
        }
        foreach my $cand_key (@group) {
            $self->c2r_set($cand_key, [$place+1, $disposition]);
        }
        $place += scalar @group;
    }

    # mark results for eliminated candidates
    for (my $elim_l1=$self->eliminated_count()-1; $elim_l1 >= 0; $elim_l1--) {
        my @group = $self->{eliminated}[$elim_l1]->members();
        foreach my $cand_key (@group) {
            $self->c2r_set($cand_key, [$place+1, "eliminated"]);
        }
        $place += scalar @group;
    }
    
    return;
}

# count using STV
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # loop forever until a valid result is established
    for ( ;; ) {
        # start new round
        $self->debug_print("new round\n");
        my $round = $self->new_round();

        # loop through votes tallying with transfers
        $self->run_tally();

        # if we didn't find any votes left, it's over
        if ( $round->votes_used() < 0.001 ) {
            $self->debug_print("no votes processed in this round - done\n");
            last;
        }

        # look for candidates meeting the quota ("majority" if two candidates)

        # done if we've exhausted the candidates
        $self->debug_print("round->candidates -> ".Dumper($round->{candidates}));
        if ($round->candidates_empty()) {
            $self->debug_print("no candidates remaining in new round\n");
            last;
        }

        # sort in descending order
        my @round_candidate = $round->sort_candidates();

        # Do we have a quota?
        # In a 1-seat race, a quota is a simple 50%+1 majority.
        # If N seats are up for election and V votes were cast,
        # a quota is V/(N+1)
        $round->quota($round->votes_used() / ($self->seats()+1));
        if ( $round->quota() <= 0.0001 ) {
            last;
        }
        if ($round->tally_get($round_candidate[0])->votes() > $round->quota() + .00001 ) {
            # quota exceeded - we have a winner!
            $self->process_winners();
        } else {
            # no quota: eliminate last-place candidate(s) and count again on next round
            $self->eliminate_losers();
        }
        #$self->debug_print("round ".($round->number())." result_cache = ".Dumper(\%result_cache));
    }

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r();

    return;
}

# return short result list
sub results
{
    my $self = shift;
    return {winners => $self->{winners}, eliminated => $self->{eliminated}};
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV - Single Transferable Vote (STV) counting

=head1 SYNOPSIS

  use PrefVote::STV;
  %vote_params = ( "name" => "value", ... );
  $vote = new PrefVote::STV \%vote_params;

=head1 DESCRIPTION


=head1 SEE ALSO


=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
