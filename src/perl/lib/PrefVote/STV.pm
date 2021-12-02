# PrefVote::STV
# ABSTRACT: single-transferable vote counting module for PrefVote
# Single Transferable Vote (STV) voting and counting module
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

## no critic (Modules::RequireExplicitPackage)
## use critic (Modules::RequireExplicitPackage)
package PrefVote::STV;
use Modern::Perl qw(2015); # require 5.20.0
## use critic (Modules::RequireExplicitPackage)

use base qw(PrefVote);

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
		debug() and print STDERR "accepting ".join(" ",@ballot)."\n";
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
	my ( %cands, @result, $quota );

	# initialize candidates
	$self->{winners} = [];
	$self->{rounds} = [];
	foreach ( keys %{$self->{choices}} ) {
		$cands{$_} = {};
	}
	debug() and print STDERR "cands (init) = ".join(" ",keys %cands)."\n";

	# stop now if there were no votes
	if ( $#{@{$self->{ballots}}} == -1 ) {
		return;
	}

	# loop forever until a valid result is established
	for ( ;; ) {
		debug() and print STDERR "new round\n";

		# clear candidate tallies
		foreach ( keys %cands ) {
			$cands{$_}{tally} = 0;
		}
		debug() and print STDERR "cands (reset) = "
			.join(" ",keys %cands)."\n";

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
				if (( defined $cands{$choice}{winner}) and
					( defined $cands{$choice}{winner}{transfer}))
				{
					$fraction *= $cands{$choice}{winner}{transfer};
					next;
				}

				# not available if eliminated this round
				( defined $cands{$choice}{eliminated})
					and $cands{$choice}{eliminated}
					and next;

				$selection = $choice;
				last;
			}

			if ( defined $selection ) {
				$cands{$selection}{tally} += $fraction;
				#$ballot_num++;
				$ballot_num += $fraction;
			}
		}
		debug() and print STDERR "cands (tally) = "
			.join(" ",keys %cands)."\n";

		# if we didn't find any votes left, it's over
		if ( $ballot_num < 0.001 ) {
			debug() and print STDERR "no votes "
				."processed in this round - done\n";
			return @result;
		}

		# look for meeting the quota ("majority" if two candidates)
		# assemble and sort this round's candidate names by vote count
		my @curr_cands;
		foreach ( keys %cands ) {
			# not available if won previous round
			( defined $cands{$_}{winner})
				and $cands{$_}{winner} and next;

			# not available if eliminated this round
			( defined $cands{$_}{eliminated})
				and $cands{$_}{eliminated} and next;

			debug() and print STDERR "push $_ on curr_cands\n";
			push ( @curr_cands, $_ );
		}

		# sort in descending order
		@curr_cands = sort {$cands{$b}{tally} <=> $cands{$a}{tally}}
			@curr_cands;
		debug() and print STDERR "curr_cands = ".join(" ",@curr_cands)
			."\n";
		if ( $#curr_cands == -1 ) {
			debug() and print STDERR "no candidates "
				."remaining in new round\n";
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
			$cands{$curr_cands[0]}{tally} > $quota + .00001 )
		{

			# we have a winner!
			my $result = [];
			my $winners = [];
			foreach ( @curr_cands ) {
				if ( $cands{$_}{tally}
					== $cands{$curr_cands[0]}{tally} )
				{
					my $c_tally = $cands{$_}{tally};
					my $c_surplus = $c_tally - $quota;
					my $pc_to_elect = sprintf ( "%6.3f",
						$quota / $c_tally * 100.0 );
					my $pc_transfer = sprintf ( "%6.3f",
						$c_surplus / $c_tally * 100.0 );
					push ( @$result,
						[ $_, $cands{$_}{tally},
						"winner for Choice #".
						((scalar @{$self->{winners}})+1)
						." ($pc_to_elect% of each vote used, $pc_transfer% transfers)" ]);

					# mark this candidate a winner
					push @$winners, $_;
					$cands{$_}{winner} = {};
					$cands{$_}{winner}{place} = $#result+1;
					$cands{$_}{winner}{quota} = $quota;
					$cands{$_}{winner}{tally} = $c_tally;
					$cands{$_}{winner}{surplus} = $c_surplus;
					$cands{$_}{winner}{transfer} =
						$cands{$_}{winner}{surplus} /
						$cands{$_}{winner}{tally};
				} else {
					push ( @$result,
						[ $_, $cands{$_}{tally}]);
				}
			}
			push ( @result, $result );

			debug() and print STDERR "winner: "
				.(join( " ", @$winners ))."\n";
			if ( scalar @$winners == 1 ) {
				push ( @{$self->{winners}}, $winners->[0]);
			} else {
				push ( @{$self->{winners}}, $winners );
			}

			# did we just exhaust the pool of candidates?
			#if ( $#curr_cands == 0 ) {
			#	debug() and print STDERR "no candidates "
			#		."remaining after win\n";
			#	return @result;
			#}

			# start a new round
			# remove elimination flags from remaining candidates
			foreach ( keys %cands ) {
				$cands{$_}{eliminated} = 0;
			}
		} elsif ( $quota > 0.001 and $#curr_cands >= 1
			and $cands{$curr_cands[0]}{tally}
			== $cands{$curr_cands[-1]}{tally}
			and $cands{$curr_cands[0]}{tally} > $quota + .00001 )
		{
			# candidates in this round have all tied
			my $result = [];
			my $i;
			debug() and print STDERR "tie: ".
				join("/",@curr_cands)."\n";
			for ( $i=0; $i <= $#curr_cands; $i++ ) {
				my $c_tally = $cands{$curr_cands[$i]}{tally};
				my $c_surplus = $c_tally - $quota;
				my $pc_to_elect = sprintf ( "%6.3f",
					$quota / $c_tally * 100.0 );
				my $pc_transfer = sprintf ( "%6.3f",
					$c_surplus / $c_tally * 100.0 );
				push ( @$result, [ $curr_cands[$i],
					$cands{$curr_cands[$i]}{tally},
					"tie for Choice #".
					((scalar @{$self->{winners}})+1)
					." ($pc_to_elect% of each vote used, $pc_transfer% transfers)" ]);

				# mark the candidates as winners
				$cands{$curr_cands[$i]}{winner}{place} =
					$#result+1;
				$cands{$curr_cands[$i]}{winner}{quota} = $quota;
				$cands{$curr_cands[$i]}{winner}{tally} = $c_tally;
				$cands{$curr_cands[$i]}{winner}{surplus} = $c_surplus;
				$cands{$curr_cands[$i]}{winner}{transfer} =
					$cands{$curr_cands[$i]}{winner}{surplus}
					/ $cands{$curr_cands[$i]}{winner}{tally};
			}
			push ( @result, $result );
			push ( @{$self->{winners}}, [ @curr_cands ]);

			# start a new round
			# remove elimination flags from remaining candidates
			foreach ( keys %cands ) {
				$cands{$_}{eliminated} = 0;
			}
		} else {
			# no quota, not an all-way tie
			# eliminate last-place candidate(s) and count again
			my $i;

			$cands{$curr_cands[-1]}{eliminated}=1;
			for ( $i = $#curr_cands - 1; $i >= 0; $i-- ) {
				if ( $cands{$curr_cands[-1]}{tally}
					== $cands{$curr_cands[$i]}{tally})
				{
					$cands{$curr_cands[$i]}{eliminated}=1;
					debug() and print STDERR "eliminated: "
						.$curr_cands[$i]."\n";
				}
			}

			my $result = [];
			foreach ( @curr_cands ) {
				if (( defined $cands{$_}{eliminated})
					and $cands{$_}{eliminated})
				{
					push ( @$result,
						[ $_, $cands{$_}{tally},
						"eliminated"] );
				} else {
					push ( @$result,
						[ $_, $cands{$_}{tally}]);
				}
			}
			push ( @result, $result );

			# if we just eliminated everyone, we're done
			if ( $cands{$curr_cands[0]}{eliminated} ) {
				debug() and print STDERR "no candidates "
					."remaining after elimination\n";
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
