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
use PrefVote::STV::Round;
use PrefVote::STV::Candidate;
use PrefVote::STV::Result;

# class definitions
use Moo;
use Type::Tiny;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
extends 'PrefVote::Core';

has winners => (
    is => 'rw',
    isa => ArrayRef[Str],
    default => sub { return [] },
);

has eliminated => (
    is => 'rw',
    isa => ArrayRef[Str],
    default => sub { return [] },
);

has rounds => (
    is => 'rw',
    isa => ArrayRef[InstanceOf["PrefVote::STV::Round"]],
    default => sub { return [] },
);

has candidates => (
	is => 'rw',
	isa => HashRef[InstanceOf["PrefVote::STV::Candidate"]],
	default => sub { return {} },
);

has results => (
	is => 'rw',
	isa => ArrayRef[InstanceOf["PrefVote::STV::Result"]],
	default => sub { return [] },
);

#
# processing
#

# initialize candidate count data
sub init_candidates
{
    my $self = shift;

	# initialize candidates
	my $candidates_ref = $self->candidates();
    foreach my $choice ($self->get_choices()) {
		$candidates_ref->{$choice} = PrefVote::STV::Candidate->new(name => $choice);
    }
    $self->debug_print("candidate (init) = ".join(" ",keys %$candidates_ref)."\n");
	return;
}

# clear candidate tallies - called once each STV counting round to reset counts
sub clear_candidate_tallies
{
    my $self = shift;
	
	# clear tallies
	my $candidates_ref = $self->candidates();
	foreach my $cand_ref ( keys %$candidates_ref ) {
		$cand_ref->tally(0);
	}
	$self->debug_print("candidate (reset) = ".join(" ",keys %$candidates_ref)."\n");
	return;
}

# start a new round
sub new_round
{
    my $self = shift;
	my $rounds_ref = $self->rounds();
	my $round = PrefVote::STV::Round->new();
	push @$rounds_ref, $round;

	# clear candidate tallies
	$self->clear_candidate_tallies();

	return $round;
}

# get ref to current round
sub current_round
{
    my $self = shift;
	my $rounds_ref = $self->rounds();
	return $rounds_ref->[-1];
}

# select current round's candidates
sub candidates_in_round
{
    my $self = shift;
	my $round = $self->current_round();

	# assemble and sort this round's candidate names by vote count
	my $cands_ref = $self->candidates();
	foreach my $cand_key ( keys %$cands_ref ) {
		# candidate is not available for current list if they won or were eliminated
		if (not $cands_ref->{$cand_key}->winner() and not $cands_ref->{$cand_key}->eliminated()) {
			$self->debug_print("add $cand_key to candidate list\n");
			$round->add_candidate($cand_key);
		}
	}
	return;
}

# add result record
sub add_result
{
    my ($self, @opts) = @_;
	my $results_ref = $self->results();
	push @$results_ref, PrefVote::STV::Result->new(@opts);
	return;
}

# add winning candidate
sub add_winner
{
    my ($self, $cand_key) = @_;
	my $winners_ref = $self->winners();
	push @$winners_ref, $cand_key;
	return;
}

# add eliminated candidate
sub add_eliminated
{
    my ($self, $cand_key) = @_;
	my $eliminated_ref = $self->eliminated();
	push @$eliminated_ref, $cand_key;
	return;
}

# initial tally with vote transfers
sub run_tally
{
    my $self = shift;
	my $round = $self->current_round();

	# loop through votes tallying with transfers
	foreach my $ballot ( @{$self->ballots()} ) {
		# loop through choices
		my $selection = undef;
		my $fraction = 1;
		foreach my $choice ( @$ballot ) {
			if ( debug() and ref($choice) ne "" ) {
				print STDERR "choice is ref "
					.ref($choice)
					." in #".$round->votes_used().": "
					.join(" ",@$ballot)."\n";
			}

			my $cand_ref = $self->candidates()->{$choice};

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
			if ( $cand_ref->winner() and defined $cand_ref->transfer())
			{
				$fraction *= $cand_ref->transfer();
				next;
			}

			# vote transfer not available to eliminated candidates
			if (not $cand_ref->eliminated()) {
				$selection = $choice;
				last;
			}
		}

		if ( defined $selection ) {
			my $sel_ref = $self->candidates()->{$selection};
			my $tally = $sel_ref->tally();
			$sel_ref->tally($tally + $fraction);
			$round->add_votes_used($fraction);
		}
	}
	$self->debug_print("candidate (tally) = ".join(" ", keys %{$self->candidates()})."\n");
	return;
}

# process candidates over quota as winners
sub process_winners
{
    my $self = shift;
	my $round = $self->current_round();
	my $cands_ref = $self->candidates();
	my @round_candidate = @{$round->candidates()};

	# quota exceeded - we have a winner!
	foreach my $curr_key ( @round_candidate ) {
		# mark all the candidates over quota who are tied at the top as winners
		if ( $cands_ref->{$curr_key}->tally() == $cands_ref->{$round_candidate[0]}->tally() ) {
			my $c_tally = $cands_ref->{$curr_key}->tally();
			my $c_surplus = $c_tally - $round->quota();
			my $pc_to_elect = sprintf ( "%6.3f",
				$round->quota() / $c_tally * 100.0 );
			my $pc_transfer = sprintf ( "%6.3f",
				$c_surplus / $c_tally * 100.0 );
			my $place = scalar @{$self->winners()}+1;
			$self->add_result({
				name => $curr_key,
				tally => $cands_ref->{$curr_key}->tally(),
				desc => "winner for Choice #$place ($pc_to_elect% of each vote used, $pc_transfer% transfers)"
			});

			# mark this candidate a winner
			$self->add_winner($curr_key);
			$cands_ref->{$curr_key}->mark_as_winner(place => $place, tally => $c_tally, surplus => $c_surplus,
				transfer => $cands_ref->{$curr_key}->surplus() / $cands_ref->{$curr_key}->tally());
			$self->debug_print( "winner: $curr_key\n");
		} else {
			last;
		}
	}

	return;
}

# in round with no winner, eliminate last-place candidates
sub eliminate_losers
{
    my $self = shift;
	my $round = $self->current_round();
	my $cands_ref = $self->candidates();
	my @round_candidate = @{$round->candidates()};

	# no quota: eliminate last-place candidate(s) and count again on next round
	my $i;
	my $last_cand = $round_candidate[-1];

	# mark candidates tied for last as eliminated
	$cands_ref->{$last_cand}->mark_as_eliminated();
	for ( $i = scalar @round_candidate; $i > 0; $i-- ) {
		my $indexed_cand = $round_candidate[$i];
		if ( $cands_ref->{$last_cand}->tally() == $cands_ref->{$indexed_cand}->tally())
		{
			$cands_ref->{$indexed_cand}->mark_as_eliminated();
			$self->debug_print("eliminated: ".$indexed_cand."\n");
		}
	}

	# save result
	foreach my $cand_key ( @round_candidate ) {
		if ( $cands_ref->{$cand_key}->eliminated())
		{
			$self->add_result({ name => $cand_key,
				tally => $cands_ref->{$cand_key}->tally(),
				desc => "eliminated"
			});
		} else {
			$self->add_result({ name => $cand_key,
				tally => $cands_ref->{$cand_key}->tally()
			});
		}
	}
	return;
}

# count using STV
sub count
{
    my $self = shift;

	# initialize candidates
	$self->init_candidates();

    # stop now if there are no votes
    return if $self->count_ballots() == 0;

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
            return;
        }

		# look for candidates meeting the quota ("majority" if two candidates)

		# select this round's candidates from those who haven't won or been eliminated
		$self->candidates_in_round();

		# done if we've exhausted the candidates
        if (not @{$round->candidates()} ) {
            $self->debug_print("no candidates remaining in new round\n");
            return;
        }

        # sort in descending order
		my @round_candidate = $round->sort_candidates();

        # Do we have a quota?
        # In a 1-seat race, a quota is a simple 50%+1 majority.
        # If N seats are up for election and V votes were cast,
        # a quota is V/(N+1)
		$round->quota($round->votes_used() / ($self->seats()+1));
		my $cands_ref = $self->candidates();
        if ( $round->quota() <= 0.001 ) {
			last;
		}
		if ($cands_ref->{$round_candidate[0]}->tally() > $round->quota() + .00001 ) {
            # quota exceeded - we have a winner!
			$self->process_winners();
        } else {
            # no quota: eliminate last-place candidate(s) and count again on next round
			$self->eliminate_losers();
        }
    }
    return;
}

## no critic (Modules::ProhibitMultiplePackages)

#
# exception classes
#
package PrefVote::STV::InvalidInternalData;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Exception';
has attribute => (is => 'ro', isa =>Str);

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
