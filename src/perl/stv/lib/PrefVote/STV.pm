# PrefVote::STV
# ABSTRACT: single-transferable vote counting module for PrefVote
# Single Transferable Vote (STV) voting and counting module
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
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
use PrefVote::STV::Round;
use PrefVote::STV::Tally;
use YAML::XS;
use Clone qw(clone);
use Data::Dumper;

# class definitions
use Moo;
use MooX::HandlesVia;
use Type::Tiny;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
extends 'PrefVote::Core';

# list of names of winners in order by place, ties shown by an ArrayRef to the tied candidates
has winners => (
    is => 'rw',
    isa => ArrayRef[ArrayRef[Str]],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
        winners_count => 'count',
        winners_push => 'push',
    },
);

# list of names of eliminated candidates in order by occurrence, ties shown by an ArrayRef to the tied candidates
has eliminated => (
    is => 'rw',
    isa => ArrayRef[ArrayRef[Str]],
    default => sub { return [] },
    handles_via => 'Array',
    handles => {
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
    $self->winners_push(\@win_list);
    my $round = $self->current_round();
    $round->set_result(
        name => clone(\@win_list),
        type => "winner",
    );
    return;
}

# add eliminated candidate
sub add_eliminated
{
    my ($self, @elim_list) = @_;
    $self->eliminated_push(\@elim_list);
    my $round = $self->current_round();
    $round->set_result(
        name => clone(\@elim_list),
        type => "eliminated",
    );
    return;
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
        foreach my $choice ($ballot->items_all()) {
            if ( $self->debug() and ref($choice) ne "" ) {
                print STDERR "choice is ref "
                    .ref($choice)
                    ." in #".$round->votes_used().": "
                    .$ballot->as_string()
                    ." (x".$ballot->quantity().")\n";
            }

            $round->tally_exists($choice) or next;
            my $cand_tally = $round->tally_get($choice);
            $self->debug_print("run_tally: candidate $choice tally: ".Dumper($cand_tally));

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
            if ( $cand_tally->winner() and defined $cand_tally->transfer())
            {
                $fraction *= $cand_tally->transfer();
                next;
            }

            # vote transfer not available to eliminated candidates
            if (not $cand_tally->eliminated()) {
                $selection = $choice;
                last;
            }
        }

        if ( defined $selection ) {
            my $sel_ref = $round->tally_get($selection);
            my $votes = $sel_ref->votes();
            my $vote_increment = $fraction * $ballot->{quantity};
            $sel_ref->votes($votes + $vote_increment);
            $round->add_votes_used($vote_increment);
        }
    }
    $self->debug_print("candidate (tally) = ".join(" ", $round->tally_keys())."\n");
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
            my $pc_to_elect = sprintf ( "%6.3f",
                $round->quota() / $c_votes * 100.0 );
            my $pc_transfer = sprintf ( "%6.3f",
                $c_surplus / $c_votes * 100.0 );
            push @round_winner, $curr_key;

            # mark this candidate a winner
            $round->tally_get($curr_key)->mark_as_winner(place => $place, votes => $c_votes, surplus => $c_surplus,
                transfer => $round->tally_get($curr_key)->surplus() / $round->tally_get($curr_key)->votes());
            $self->debug_print( "winner: $curr_key\n");
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
    }
    return;
}

# return short result list
sub results
{
    my $self = shift;
    return {winners => $self->{winners}, eliminated => $self->{eliminated}};
}

# collect result in YAML
sub result_yaml
{
    my $self = shift;

    # copy relevant round/result records into YAML result structure
    my $result_out = {
        winners => $self->winners(),
        eliminated => $self->eliminated(),
        rounds => [],
    };
    for (my $round_index=0; $round_index < $self->rounds_count(); $round_index++) {
        my $round_ref = $self->rounds_get($round_index);
        my $round_yaml = {
            round => $round_index+1,
            total_votes => $round_ref->votes_used(),
            quota => $round_ref->quota(),
            candidates => [],
        };

        # if the round had a result (win or elimination) then record it
        if (exists $round_ref->{result}) {
            my $result_ref = $round_ref->{result};
            my $type = $result_ref->type();
            if ($type eq "winner") {
                $round_yaml->{winner} = $result_ref->name();
            } elsif ($type eq "eliminated") {
                $round_yaml->{eliminated} = $result_ref->name();
            } else {
                # unrecognized type should not happen unless enum is changed in PrefVote::STV::Result
                PrefVote::Core::InternalDataException->throw(
                    classname => __PACKAGE__,
                    attribute => 'type',
                    description => "unrecognized result type $type",
                );
            }
        }

        # list candidate tallies for the round in order of descending result
        foreach my $cand_name ($round_ref->candidates_all()) {
            my $tally_ref = $round_ref->tally_get($cand_name);
            my $tally_yaml = {
                name => $cand_name,
                votes => $tally_ref->{votes},
            };
            if ($tally_ref->winner()) {
                $tally_yaml->{winner} = 1;
                $tally_yaml->{place} = $tally_ref->{place};
                $tally_yaml->{surplus} = $tally_ref->{surplus};
                $tally_yaml->{transfer} = $tally_ref->{transfer};
            } elsif ($tally_ref->eliminated()) {
                $tally_yaml->{eliminated} = 1;
            }
            push @{$round_yaml->{candidates}}, $tally_yaml;
        }
        push @{$result_out->{rounds}}, $round_yaml;
    }

    return $result_out;
}

#
# perform STV-specific black-box tests from external file against this object's data
#

# generate test results from comparing winner/eliminated lists
sub blackbox_we_list_cmp
{
    my ($path, $list, $values) = @-;
    my @tests;

    # catch scalar values and return a single test for it
    if (not ref $list or not ref $values) {
            push @tests, ["is", $list, $values, join("-", @$path)." match"];
    }
    
    # generate tests for list comparison
    my $cl_count = scalar @$list;
    my $value_count = scalar @$values;
    my $count_cmp = $cl_count <=> $value_count;
    if ($cl_count==1) {
        push @tests, blackbox_we_list_cmp( [ @$path, 0 ], $list->[0], $values->[0]);
    }
    for (my $i=0; $i<$cl_count-1; $i++) {
        push @tests, blackbox_we_list_cmp( [ @$path, $i ], $list->[$i], $values->[$i]);
    }
    if ($count_cmp == 0) {
        push @tests, blackbox_we_list_cmp( [ @$path, -1 ], $list->[-1], $values->[-1]);
    } else {
        # if the lists are different length, replace the last test with a failure on list length
        push @tests, ["is", $cl_count, $value_count, join("-", @$path)." list length match"];

        # if there was a list at the last item, insert failed tests
        if (ref $list->[-1] eq "ARRAY") {
            my $len = (scalar @{$list->[-1]})-1;
            for (my $j=0; $j<$len; $j++) {
                push @tests, ["fail", join("-", @$path, $j)." placeholder"];
            }
        }
    }
    return @tests;
}

# top-level tree traversal for blackbox tests
sub blackbox_check
{
    my ($self, $checklist) = @_;
    my (@tests, @path);
    foreach my $key (sort keys %$checklist) {
        push @path, $key;
        if ($key eq "winners" or $key eq "eliminated" or $key eq "rounds") {
            push @tests, blackbox_we_list_cmp( \@path, $checklist->{$key}, $self->{$key});
        } else {
            croak "unrecognized test key $key";
        }
    }
    return @tests;
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
