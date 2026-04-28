# PrefVote::KR2
# ABSTRACT: Kluft Rank-Rate (KR2) vote counting module for PrefVote
# Copyright (c) 2023-2026 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::KR2;

use utf8;
use autodie;
use builtin qw(true false);
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common         qw(Int IntRange Str ArrayRef HashRef InstanceOf PositiveOrZeroInt NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp);
use PrefVote::Core::Set   qw(Set);
use PrefVote::KR2::PairData;
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners    => [qw(list set string)],
    eliminated => [qw(list set string)],
    pair       => [qw(hash hash PrefVote::KR2::PairData)],
    copeland_score => [qw(hash int)],
    levels    => [qw(int)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);
__PACKAGE__->ballot_input_ties_policy(1);    # set flag for Core: this class allows input ballots to set A/B ties

# ratings: level and bound definitions
Readonly::Hash my %rating_def => (
    1 => {
        levels => [qw( all )],
        bounds => [],
        default => [qw( end )],
    },
    2 => {
        levels => [qw( support oppose )],
        bounds => [qw( _neutral )],
        elimination => "_neutral",
        default => [ equal => "_neutral" ],
    },
    3 => {
        levels => [qw( support neutral oppose )],
        bounds => [qw( _support _oppose )],
        elimination => "_oppose",
        default => [ above => "_oppose" ],
    },
    4 => {
        levels => [qw( support2 support1 oppose1 oppose2 )],
        bounds => [qw( _support2 _neutral _oppose2 )],
        elimination => "_neutral",
        default => [ equal => "_neutral" ],
    },
    5 => {
        levels => [qw( support2 support1 neutral oppose1 oppose2 )],
        bounds => [qw( _support2 _support1 _oppose1 _oppose2 )],
        elimination => "_oppose1",
        default => [ above => "_oppose1" ],
    },
);

# list of names of winners in order by place, ties shown by a set of the tied candidates
has winners => (
    is          => 'rw',
    isa         => ArrayRef [ Set [Str] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        winners_all   => 'all',
        winners_count => 'count',
        winners_push  => 'push',
    },
);

# list of names of eliminated candidates in order by occurrence, ties shown by a set of the tied candidates
has eliminated => (
    is          => 'rw',
    isa         => ArrayRef [ Set [Str] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        eliminated_all      => 'all',
        eliminated_count    => 'count',
        eliminated_unshift  => 'unshift',
    },
);

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate if preferred over a 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has pair => (
    is          => 'rw',
    isa         => HashRef [ HashRef [ InstanceOf ['PrefVote::KR2::PairData'] ] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        pair_accessor => 'accessor',
        pair_get      => 'get',
        pair_keys     => 'keys',
        pair_set      => 'set',
    },
);

# hash of Copeland scores (count of pairwise wins minus losses) per candidate, for result ordering
# the scores are computed by cand_copeland_score() and cached here to prevent redundant computation
has copeland_score => (
    is          => 'rw',
    isa         => HashRef [ Int ],
    default     => sub { return {} },
);

# number of rating levels used in the voting
# 1 = no ratings used (default), 2 = support/oppose, 3 = support/neutral/oppose,
# 4 = strong/weak support/oppose, 5 = strong support/weak support/neutral/weak oppose/strong oppose
# configurable from the YAML vote config file or CEF parameters
has levels => (
    is          => 'rw',
    isa         => IntRange[1, 5],
    default     => 1,
);

# class/subclass configuration on handling Rating Bound Markers (support/oppose thresholds) mixed with candidate list
# overrides PrefVote::Core::rating_bound_marker_policy() method to allow Rating Bound Markers in this subclass
sub rating_bound_marker_policy
{
    return true;
}

# allow unit tests to access the %rating_def read-only structure
sub get_rating_def
{
    return \%rating_def;
}

# PrefVote::Core::init_core calls subclass init_hook() if provided: add rating bound markers to list of ballot choices
sub init_subclass
{
    my $self = shift;

    # validate choices is a hash ref
    if ( ref $self->{choices} ne "HASH" ) {
        PrefVote::Core::Exception->throw( description => "KR2 init_subclass() found non-hash in choices" );
    }

    # append KR2 rating bound markers to choices
    foreach my $marker ( @{$rating_def{ $self->levels() }{bounds}} ) {
        $self->{choices}{$marker} = "[rating bound $marker]";
    }
    return;
}

# PrefVote::Core::submit_ballot() calls subclass validate_ballot() if provided
# this throws an exception to reject a ballot, otherwise returns to allow processing to continue
# KR2 validates ballots for rating bound markers all there in the right order
sub validate_ballot
{
    my ( $self, @ballot ) = @_;

    # extract rating bound markers from the ballot to make sure they're all there in the right order
    # after PrefVote::Core::filter_ballot(), each ballot entry is a Set::Tiny object with one or more entries
    my @markers;
    foreach my $item ( @ballot ) {
        # extract tie set for each ballot ranking
        my @rank_set = item2list( $item );
        my @rank_set_markers = grep { substr( $_, 0, 1 ) eq "_" } @rank_set;
        if ( scalar @rank_set_markers > 1 ) {
            PrefVote::Core::Exception->throw( description => "KR2 ballot failed validation: "
                . " rating bound markers cannot be equal rank" );
        }
        push @markers, @rank_set_markers;
    }

    # rating bound markers must match expected list: identical order, not missing any, not adding new ones
    my @marker_expected = @{ $rating_def{ $self->levels() }{bounds} };
    my $marker_fail = false;
    if ( scalar @markers != scalar @marker_expected ) {
        $marker_fail = true;
    } else {
        for ( my $i=0; $i < scalar @markers; $i++ ) {
            if ( $markers[$i] ne $marker_expected[$i] ) {
                $marker_fail = true;
                last;
            }
        }
    }
    if ( $marker_fail ) {
        PrefVote::Core::Exception->throw( description => "KR2 ballot failed validation: rating bound markers "
            . "found: " . join( "/", @markers )
            . "expected: " . join( "/", @marker_expected )
        );
    }

    return;
}

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ( $self, $cand_i, $cand_j ) = @_;
    if ( not exists $self->{pair}{$cand_i} ) {
        $self->{pair}{$cand_i} = {};
    }
    if ( not exists $self->{pair}{$cand_i}{$cand_j} ) {
        $self->{pair}{$cand_i}{$cand_j} = PrefVote::KR2::PairData->new();
    }
    return;
}

# record a candidate-pair preference
# This adds to a total of votes favoring candidate cand_i over cand_j. Note: cand_j over cand_i is a separate entry.
sub add_preference
{
    my ( $self, $cand_i, $cand_j, $quantity ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->add_preference($quantity);
}

# get preference in matrix entry
sub get_preference
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};               # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};      # use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->preference() // 0;   # return preference, or zero if the node didn't have it
}

# set a candidate-pair margin of victory (mov) in matrix entry
sub set_mov
{
    my ( $self, $cand_i, $cand_j, $mov ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->mov($mov);
}

# get candidate-pair margin of victory (mov) in matrix entry
sub get_mov
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};             # zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};    # zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->get_mov();
}

# get a choice/candidate's Copeland Score (total pairwise wins minus losses) for Condorcet result ordering
sub cand_copeland_score
{
    my ( $self, $cand ) = @_;

    # if already computed for this candidate, we're done
    if ( exists $self->{copeland}{$cand}) {
        return $self->{copeland}{$cand};
    }

    # compute Copeland Score for this candidate
    my $total = 0;
    foreach my $opponent ( keys %{ $self->pair_get($cand) } ) {
        # get margin of victory against a single opponent (negative for a loss to the opponent)
        my $mov = $self->get_mov( $cand, $opponent );

        # add 1 for a win, -1 for a loss
        $total++ if $mov > 0;
        $total-- if $mov < 0;
    }

    # save result and return
    $self->{copeland}{$cand} = $total;
    return $total;
}

# return a ballot item as a list, whether it was a single scalar or a tie-group set
# This code was borrowed from Schulze, which allows ties on input. The Ranked Pairs definition does not allow
# input ties. PrefVote can be configured to allow it for consistency across Condorcet methods.
sub item2list
{
    my $item = shift;
    if ( ref $item eq 'Set::Tiny' ) {
        return ( $item->elements() );
    }
    return ($item);
}

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
sub tally_preferences
{
    my $self = shift;

    # compute preferences from ballots: loop through votes tallying preferences
    my @choices = $self->choices_keys();    # list of candidates
    foreach my $combo ( $self->ballots_keys() ) {

        # loop through choices on the ballot
        my $ballot       = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();

        # enumerate which items are on this ballot
        # used to find what's missing and look up position of rating bound markers for implicit ranking insertion
        my %seen_on_ballot;
        {
            for ( my $pos = 0; $pos < scalar @ballot_items; $pos++ ) {
                foreach my $item ( item2list( $ballot_items[$pos] )) {
                    $seen_on_ballot{$item} = $pos; # save position where the item is on the ballot
                }
            }
        }

        # if implicit ranking is enabled, which it always should be in KR2, insert missing items at default position
        if ( $self->get_flag('implicit_ranking') ) {
            my @included = keys %seen_on_ballot;
            my @omitted  = grep { not exists $seen_on_ballot{$_} } @choices;
            my $default_pos = $rating_def{ $self->levels() }{default};
            my $marker_name = $default_pos->[1] // "";
            if ( $default_pos->[0] eq "end" ) {
                # append omitted items in a separate ranking position at the end
                push @ballot_items, Set::Tiny->new( @omitted );
            } elsif ( $default_pos->[0] eq "equal" ) {
                # insert omitted items into the ranking position at the default position
                if ( not ref $ballot_items[ $seen_on_ballot{ $marker_name } ] ) {
                    my $entry = $ballot_items[ $seen_on_ballot{ $marker_name } ];
                    $ballot_items[ $seen_on_ballot{ $marker_name } ] = Set::Tiny->new( ( $entry ) );
                }
                $ballot_items[ $seen_on_ballot{ $marker_name } ]->insert( @omitted );
            } elsif ( $default_pos->[0] eq "above" ) {
                # insert omitted items in a separate ranking position above/before the default position
                splice @ballot_items, $seen_on_ballot{ $marker_name }, 0, Set::Tiny->new( @omitted );
            }
        }

        # choices contained on the ballot have all pairwise preferences recorded
        for ( my $pos1 = 0 ; $pos1 < scalar @ballot_items - 1 ; $pos1++ ) {

            # mark all following items on the ballot as less-favored than the current item
            # This adds 2 levels of loops to support potential ties within each position.
            my @item1 = item2list( $ballot_items[$pos1] );
            foreach my $cand_i (@item1) {
                for ( my $pos2 = $pos1 + 1 ; $pos2 < scalar @ballot_items ; $pos2++ ) {
                    my @item2 = item2list( $ballot_items[$pos2] );
                    foreach my $cand_j (@item2) {
                        $self->add_preference( $cand_i, $cand_j, $ballot->{quantity} );
                    }
                }
            }
        }
    }
    return;
}

# compute margin of victory table for Condorcet pairwise comparisons
sub compute_condorcet
{
    my $self = shift;

    # loop through candidate pairs and compute margin of victory for each
    foreach my $cand_i ( $self->pair_keys() ) {
        foreach my $cand_j ( keys %{ $self->pair_accessor($cand_i) } ) {

            # skip if we've already computed this pair in the reverse candidate order
            next if exists $self->{pair}{$cand_i}{$cand_j}{mov};

            # set up margin of victory (mov) and tentative i-j candidate pair (may be reordered)
            my $pref_ij = $self->get_preference( $cand_i, $cand_j );
            my $pref_ji = $self->get_preference( $cand_j, $cand_i );
            $self->set_mov( $cand_i, $cand_j, $pref_ij - $pref_ji );
            $self->set_mov( $cand_j, $cand_i, $pref_ji - $pref_ij );
        }
    }

    return;
}

# comparison function for sorting results
sub cmp_choice
{
    my ( $self, $cand1, $cand2 ) = @_;

    # 1st comparison: Copeland Scores (pairwise wins minus losses) in descending order
    my $copeland1 = $self->cand_copeland_score($cand1);
    my $copeland2 = $self->cand_copeland_score($cand2);
    if ( $copeland1 != $copeland2 ) {
        return $copeland2 <=> $copeland1;  # order Copeland Scores from high to low
    }

    # 2nd comparison: choice/candidate's average choice rank ACR (ballot position) in ascending order
    # ACR is computed by PrefVote::Core for all voting methods
    my $place1 = $self->average_ranking($cand1);
    my $place2 = $self->average_ranking($cand2);
    if ( not fp_equal( $place1, $place2 ) ) {
        return fp_cmp( $place1, $place2 );
    }

    return 0;
}

# use Margin of Victory table to determine voting result order
# candidates are sorted by two factors:
# primary: Copeland Score (count of pairwise wins minus pairwise defeats, 0 for ties)
# secondary: PrefVote average choice rank ACR
sub mov_order
{
    my $self = shift;

    # sort list of candidates ordered by cmp_choice
    my @choices = sort { $self->cmp_choice( $a, $b ) } $self->choices_keys();

    # detect ties and build result rankings
    my $elimination_marker = $rating_def{ $self->levels() }{elimination};
    my $after_elimination_marker = false;
    while ( scalar @choices ) {
        my $leader    = shift @choices;

        # set flag if oppose rating bound marker found
        my $seen_elimination_marker = false;
        if ( $elimination_marker and ( substr $leader, 0, length( $elimination_marker )) eq $elimination_marker ) {
            $seen_elimination_marker = true;
        }

        # find any candidates tied with the current leader and add them to a set/group for this result position
        my $tie_group = set($leader);
        while ( ( scalar @choices > 0 ) and ( $self->cmp_choice( $leader, $choices[0] ) == 0 ) ) {
            my $tie_cand = shift @choices;
            $tie_group->insert( $tie_cand );
            if ( $tie_cand =~ / ^ _oppose . * /x ) {
                $seen_elimination_marker = true;
            }
        }

        # add the set/group to either eliminated or winning result list
        if ( $after_elimination_marker ) {
            # eliminated items add in reverse of ranking order because 1st elimination = last place (STV precedent)
            $self->eliminated_unshift($tie_group);
        } else {
            $self->winners_push($tie_group);
        }

        # if we encountered elimination marker, set after_elimination_marker so remaining candidates are eliminated
        if ( $seen_elimination_marker ) {
            $after_elimination_marker = true;
        }
    }

    return;
}

# count votes using Kluft Rank-Rate method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # tally preferences into one-way candidate-pair totals
    $self->tally_preferences();

    # compute Condorcet result ordering
    $self->compute_condorcet();

    # result ordering using Copeland Score (count of pairwise wins minus pairwise defeats, 0 for ties) & PrefVote ACR
    $self->mov_order();

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r( winners => $self->winners(), eliminated => $self->eliminated() );

    #$self->debug_print(__PACKAGE__." count(): ".Dumper($self));
    return;
}

# return short result list
sub results
{
    my $self = shift;
    return { ranked => $self->{winners}, eliminated => $self->{eliminated} };
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    use PrefVote::KR2;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::KR2::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...

=head1 DESCRIPTION

I<PrefVote::KR2> implements the Kluft Rank-Rate (KR2) preference voting algorithm for the I<PrefVote>
system.

KR2 is an experimental voting method under testing.

=head2 ALGORITHM

The Kluft Rank-Rate (KR2) voting method combines ranked choice ballots in multiple rating groups to incorporate approval or opposition information into a ranked choice poll or election. KR2 polls/elections can have single or multiple winners, depending on the number of seats configured for the poll.

=head3 Condorcet compliance

KR2 is a Condorcet-compliant system. That means the definition starts with using ranked preference ballot data to perform pairwise comparisons among all candidates. If one candidate beats all the others in pairwise comparisons, then that candidate wins.

It is possible for close elections to have two or more candidates either tie or make a cycle of beating each other which prevents having one pairwise winner. All Condorcet methods differ in how to handle these ties, also known as the Condorcet Paradox. KR2 orders the candidates by their Copeland Score, which is the number of pairwise wins minus the pairwise losses, with pairwise ties counting as zero. It acts like a round-robin tournament, where competing teams play against each other to make such a ranking order. Except the ranked preference ballots contain enough information to order the candidates by Copeland Score. A Condorcet Winner, if present, will always win this ranking.

=head3 Condorcet tie-breaking

Otherwise ties are broken by using the average choice rank (ACR) where 1st choice equals 1, 2nd choice is 2, etc. ACR is used as a secondary sorting criteria so that it won't break Condorcet ordering. ACR is mathematically equivalent to a Borda Count, except reversed to favor lower numbers instead of higher, because of the simplicity value of first place being 1. Thus far, the algorithm is like Black's Method, except that positional data (ACR in this case) is used to break ties, without throwing out the Condorcet ordering.

=head3 Rating levels

KR2 ballots can defined before the poll to use multiple rating groups. If no groups are configured, then the vote is a Condorcet-compliant ranked choice algorithm. Testing has so far shown it to be comparable to the Schulze 2004 or Tideman 1987 (Ranked Pairs) methods. If multiple rating groups are defined, then "rating bound markers" between the groups are inserted in each ballot by the vote entry system. By definition of the algorithm, these markers must all be present in the correct order. Otherwise a ballot missing any rating bound markers or using them out of order must be rejected.

The number of rating groups in a KR2 election are called levels. The definition of a poll/election must include a level number if one is desired. Otherwise Level 1 is the default setting.

Level 1 has only one group, and therefore no rating bound markers. This is equivalent to a regular Condorcet ranked-choice election. The ballot does not present rating options. Choices are not marked as eliminated in the results. (This is the least complicated level, but collects no rating information.)

Level 2 has two groups to rank choices: support and oppose. Each ballot contains a rating bound marker called "\_neutral". Choices which are omitted from any ballot are inserted as tied with each other and the "\_neutral" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_neutral" marker.

Level 3 has three groups to rank choices: support, neutral and oppose. Each ballot contains rating bound markers called "\_support" and "\_oppose". Choices which are omitted from any ballot are inserted as tied with each other just above the "\_oppose" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_oppose" marker. (This level is the recommended maximum for non-technical audiences.)

Level 4 has four groups to rank choices: strong support ("\_support2"), weak support ("\_support1"), weak oppose ("\_oppose1") and strong oppose ("\_oppose2"). Each ballot contains rating bound markers called "\_support2", "\_neutral" and "\_oppose2". Choices which are omitted from any ballot are inserted as tied with each other and the "\_neutral" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_neutral" marker.

Level 5 has five groups to rank choices: strong support ("\_support2"), weak support ("\_support1"), neutral, weak oppose ("\_oppose1") and strong oppose ("\_oppose2"). Each ballot contains rating bound markers called "\_support2", "\_support1", "\_oppose1" and "\_oppose2". Choices which are omitted from any ballot are inserted as tied with each other just above the "\_oppose1" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_oppose1" marker. (This is the most complicated level, but obtains the most data on voter intent.)

Candidates who are eliminated by KR2 for falling below the opposition threshold in the results cannot win, even if open seats are available. In cases of organizational elections, it is recommended to adopt a rule before the election on how vacancies are filled if not enough choices are selected. Candidates eliminated should be barred from filling any vacancy until the next election.

KR2 allows voters to submit tied rankings for choices. But rating bound markers must not be tied with each other - they have to appear in the correct order in separate positions on each ballot.

=head1 METHODS

These methods are in addition to L<those inherited from PrefVote::Core|PrefVote::Core/METHODS>.

=over 1

=item make_pair_node

This should not be called by external code.

This method is called by add_preference, set_mov and set_lock to initialize a pair node for a
specific pair of candidates if it didn't already exist.
The parameters are the ids of the two candidates of the pair in order of counting preferences
of the first over the second.
A separate pair node counts preferences in the opposite direction.

=item add_preference

This method records a counted candidate-pair preference.
The parameters are the ids of the two candidates for the pair, and the quantity of ballots by which to increment it.
The quantity is a function of how many ballots contained a specific permutation of candidates.

=item get_preference

This method returns the vote count for a specific candidate pair, indicating how many ballots had a preference for
the first candidate over the second.
If called before counting is complete, this yields the in-progress tally for that candidate pair.

=item set_mov

This should not be called by external code.

This sets the margin of victory for a candidate pair.
The parameters are the ids of the two candidates for the pair, and the margin of victory of votes counted.
This counts both wins, adding votes for the first candidate over the second, and losses,
subtracting votes for the second candidate over the first.
So the corresponding pair reversing the order of the two candidates must be the negative of the same value.

=item get_mov

This reads the margin of victory for a candidate pair.
The parameters are the ids of the two candidates for the pair.

=item cand_copeland_score

This returns a candidate's Copeland Score, the total wins minus losses, from the margin of victory table.
The parameter is the id of the candidate.

=item tally_preferences

This should not be called by external code.
This is called by the count() method.

This tallies the ballots which were already stored by PrefVote::Core::submit_ballot().
This is where each entry in a ranked preference order is counted as a preference over all
following lower-ranked candidates.
Omitted candidates are counted as equals but less preferred than all other candidates for that ballot.
This calls I<add_preference()> to register preferences from ballots into the candidate pair matrix.

=item compute_condorcet

This performs pairwise counting to generate Condorcet result ordering,
also using PrefVote's ACR (average choice rank) for tie-breaking.

=item count

This counts votes using the KR2 (Kluft Rank-Rate) method.
The count() method of L<PrefVote::Core> is overridden by I<PrefVote::KR2> in order to implement
the KR2 voting algorithm.

=back

=head1 SEE ALSO

L<PrefVote::Core>
L<https://github.com/ikluft/prefvote/doc/perl-dev.md>

The Kluft Rank-Rate (KR2) preference voting algorithm is experimental.
As documentation is written it will be posted at L<https://ikluft.github.io/prefvote/doc/kr2/>.

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
