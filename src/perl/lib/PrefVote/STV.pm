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
use base qw(PrefVote);
use autodie;

# subclass initialization - called by PrefVote::initialize()
sub subclass_init
{
	my $self = shift;
	$self->{winners} = [];
	$self->{rounds} = [];
	return;
}

# submit a ballot - just store it, do not count yet
sub submit_ballot
{
	my ($self, @ballot) = @_;
	my $result;

	# Note: ballots are anonymous once this function is called.
	# Protection against casting multiple votes must be done elsewhere
	# (preferably when the vote is accepted) because this module doesn't
	# retain any association between the ballot and the voter.
	if ( !( $result = $self->verify_ballot ( \@ballot ))) {
		$self->debug_print("accepting ", join(" ", @ballot), "\n");
		push ( @{$self->{ballots}}, \@ballot );
	}

	# result will be undef for OK, or multiline string with error messages
	return $result;
}

# verify that a ballot is valid
sub verify_ballot
{
	my $self = shift;
	my $ballot_ref = shift;
	my @result;

	foreach ( @$ballot_ref ) {
		if ( ! defined $self->{choices}{$_}) {
			push ( @result, "$_ is not a valid choice" );
		}
	}
	if ( $#result == -1 ) {
		# ballot is OK
		return;
	} else {
		# we found errors
		return join ( "\n", @result )."\n";
	}
}

# count using STV
sub count_stv
{
	my $self = shift;
	my ( %candidate, @result, $quota );

	# initialize candidates
	foreach ( keys %{$self->{choices}} ) {
		$candidate{$_} = {};
	}
	$self->debug_print("candidate (init) = ".join(" ",keys %candidate)."\n");

	# stop now if there were no votes
	if ( $#{@{$self->{ballots}}} == -1 ) {
		return;
	}

	# loop forever until a valid result is established
	for ( ;; ) {
		$self->debug_print("new round\n");

		# clear candidate tallies
		foreach ( keys %candidate ) {
			$candidate{$_}{tally} = 0;
		}
		$self->debug_print("candidate (reset) = ".join(" ",keys %candidate)."\n");

		# loop through votes
		my $ballot_num = 0;
		foreach my $ballot ( @{$self->{ballots}} ) {
			# loop through choices
			my $selection = undef;
			my $fraction = 1;
			foreach my $choice ( @$ballot ) {
				if ( debug() and ref($choice) ne "" ) {
					print STDERR "choice is ref "
						.ref($choice)
						." in #$ballot_num: "
						.join(" ",@$ballot)."\n";
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
				if (( defined $candidate{$choice}{winner}) and
					( defined $candidate{$choice}{winner}{transfer}))
				{
					$fraction *= $candidate{$choice}{winner}{transfer};
					next;
				}

				# not available if eliminated this round
				( defined $candidate{$choice}{eliminated})
					and $candidate{$choice}{eliminated}
					and next;

				$selection = $choice;
				last;
			}

			if ( defined $selection ) {
				$candidate{$selection}{tally} += $fraction;
				#$ballot_num++;
				$ballot_num += $fraction;
			}
		}
		$self->debug_print("candidate (tally) = ".join(" ",keys %candidate)."\n");

		# if we didn't find any votes left, it's over
		if ( $ballot_num < 0.001 ) {
			$self->debug_print("no votes processed in this round - done\n");
			return @result;
		}

		# look for meeting the quota ("majority" if two candidates)
		# assemble and sort this round's candidate names by vote count
		my @curr_candidate;
		foreach ( keys %candidate ) {
			# not available if won previous round
			( defined $candidate{$_}{winner})
				and $candidate{$_}{winner} and next;

			# not available if eliminated this round
			( defined $candidate{$_}{eliminated})
				and $candidate{$_}{eliminated} and next;

			$self->debug_print("push $_ on curr_candidate\n");
			push ( @curr_candidate, $_ );
		}

		# sort in descending order
		@curr_candidate = sort {$candidate{$b}{tally} <=> $candidate{$a}{tally}}
			@curr_candidate;
		$self->debug_print("curr_candidate = ".join(" ",@curr_candidate)."\n");
		if ( $#curr_candidate == -1 ) {
			$self->debug_print("no candidates remaining in new round\n");
			return @result;
		}

		# Do we have a quota?
		# In a 1-seat race, a quota is a simple 50%+1 majority.
		# If N seats are up for election and V votes were cast,
		# a quota is V/(N+1)
		$quota = $ballot_num / ($self->{seats}+1);
		push @{$self->{rounds}}, {
			"quota" => $quota,
			"ballots" => $ballot_num,
		};
		if ( $quota > 0.001 and
			$candidate{$curr_candidate[0]}{tally} > $quota + .00001 )
		{
			# we have a winner!
			my $result = [];
			my $winners = [];
			foreach ( @curr_candidate ) {
				if ( $candidate{$_}{tally}
					== $candidate{$curr_candidate[0]}{tally} )
				{
					my $c_tally = $candidate{$_}{tally};
					my $c_surplus = $c_tally - $quota;
					my $pc_to_elect = sprintf ( "%6.3f",
						$quota / $c_tally * 100.0 );
					my $pc_transfer = sprintf ( "%6.3f",
						$c_surplus / $c_tally * 100.0 );
					push ( @$result,
						[ $_, $candidate{$_}{tally},
						"winner for Choice #".
						((scalar @{$self->{winners}})+1)
						." ($pc_to_elect% of each vote used, $pc_transfer% transfers)" ]);

					# mark this candidate a winner
					push @$winners, $_;
					$candidate{$_}{winner} = {};
					$candidate{$_}{winner}{place} = $#result+1;
					$candidate{$_}{winner}{quota} = $quota;
					$candidate{$_}{winner}{tally} = $c_tally;
					$candidate{$_}{winner}{surplus} = $c_surplus;
					$candidate{$_}{winner}{transfer} =
						$candidate{$_}{winner}{surplus} /
						$candidate{$_}{winner}{tally};
				} else {
					push ( @$result,
						[ $_, $candidate{$_}{tally}]);
				}
			}
			push ( @result, $result );

			$self->debug_print( "winner: ".(join( " ", @$winners ))."\n");
			if ( scalar @$winners == 1 ) {
				push ( @{$self->{winners}}, $winners->[0]);
			} else {
				push ( @{$self->{winners}}, $winners );
			}

			# did we just exhaust the pool of candidates?
			#if ( $#curr_candidate == 0 ) {
			#	$self->debug_print("no candidates remaining after win\n");
			#	return @result;
			#}

			# start a new round
			# remove elimination flags from remaining candidates
			foreach ( keys %candidate ) {
				$candidate{$_}{eliminated} = 0;
			}
		} elsif ( $quota > 0.001 and $#curr_candidate >= 1
			and $candidate{$curr_candidate[0]}{tally}
			== $candidate{$curr_candidate[-1]}{tally}
			and $candidate{$curr_candidate[0]}{tally} > $quota + .00001 )
		{
			# candidates in this round have all tied
			my $result = [];
			my $i;
			$self->debug_print("tie: ".join("/",@curr_candidate)."\n");
			for ( $i=0; $i <= $#curr_candidate; $i++ ) {
				my $c_tally = $candidate{$curr_candidate[$i]}{tally};
				my $c_surplus = $c_tally - $quota;
				my $pc_to_elect = sprintf ( "%6.3f",
					$quota / $c_tally * 100.0 );
				my $pc_transfer = sprintf ( "%6.3f",
					$c_surplus / $c_tally * 100.0 );
				push ( @$result, [ $curr_candidate[$i],
					$candidate{$curr_candidate[$i]}{tally},
					"tie for Choice #".
					((scalar @{$self->{winners}})+1)
					." ($pc_to_elect% of each vote used, $pc_transfer% transfers)" ]);

				# mark the candidates as winners
				$candidate{$curr_candidate[$i]}{winner}{place} =
					$#result+1;
				$candidate{$curr_candidate[$i]}{winner}{quota} = $quota;
				$candidate{$curr_candidate[$i]}{winner}{tally} = $c_tally;
				$candidate{$curr_candidate[$i]}{winner}{surplus} = $c_surplus;
				$candidate{$curr_candidate[$i]}{winner}{transfer} =
					$candidate{$curr_candidate[$i]}{winner}{surplus}
					/ $candidate{$curr_candidate[$i]}{winner}{tally};
			}
			push ( @result, $result );
			push ( @{$self->{winners}}, [ @curr_candidate ]);

			# start a new round
			# remove elimination flags from remaining candidates
			foreach ( keys %candidate ) {
				$candidate{$_}{eliminated} = 0;
			}
		} else {
			# no quota, not an all-way tie
			# eliminate last-place candidate(s) and count again
			my $i;

			$candidate{$curr_candidate[-1]}{eliminated}=1;
			for ( $i = $#curr_candidate - 1; $i >= 0; $i-- ) {
				if ( $candidate{$curr_candidate[-1]}{tally}
					== $candidate{$curr_candidate[$i]}{tally})
				{
					$candidate{$curr_candidate[$i]}{eliminated}=1;
					$self->debug_print("eliminated: ".$curr_candidate[$i]."\n");
				}
			}

			my $result = [];
			foreach ( @curr_candidate ) {
				if (( defined $candidate{$_}{eliminated})
					and $candidate{$_}{eliminated})
				{
					push ( @$result,
						[ $_, $candidate{$_}{tally},
						"eliminated"] );
				} else {
					push ( @$result,
						[ $_, $candidate{$_}{tally}]);
				}
			}
			push ( @result, $result );

			# if we just eliminated everyone, we're done
			if ( $candidate{$curr_candidate[0]}{eliminated} ) {
				$self->debug_print("no candidates remaining after elimination\n");
				return @result;
			}
		}
	}
	return;
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
