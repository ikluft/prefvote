# SYNOPSIS

    use PrefVote::KR2;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::KR2::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...

# DESCRIPTION

_PrefVote::KR2_ implements the Kluft Rank-Rate (KR2) preference voting algorithm for the _PrefVote_
system.

KR2 is an experimental voting method under testing.

## ALGORITHM

The Kluft Rank-Rate (KR2) voting method combines ranked choice ballots in multiple rating groups to incorporate approval or opposition information into a ranked choice poll or election. KR2 polls/elections can have single or multiple winners, depending on the number of seats configured for the poll.

### Condorcet compliance

KR2 is a Condorcet-compliant system. That means the definition starts with using ranked preference ballot data to perform pairwise comparisons among all candidates. If one candidate beats all the others in pairwise comparisons, then that candidate wins.

It is possible for close elections to have two or more candidates either tie or make a cycle of beating each other which prevents having one pairwise winner. All Condorcet methods differ in how to handle these ties, also known as the Condorcet Paradox. KR2 orders the candidates by their Copeland Score, which is the number of pairwise wins minus the pairwise losses, with pairwise ties counting as zero. It acts like a round-robin tournament, where competing teams play against each other to make such a ranking order. Except the ranked preference ballots contain enough information to order the candidates by Copeland Score. A Condorcet Winner, if present, will always win this ranking.

### Condorcet tie-breaking

Otherwise ties are broken by using the average choice rank (ACR) where 1st choice equals 1, 2nd choice is 2, etc. ACR is used as a secondary sorting criteria so that it won't break Condorcet ordering. ACR is mathematically equivalent to a Borda Count, except reversed to favor lower numbers instead of higher, because of the simplicity value of first place being 1. Thus far, the algorithm is like Black's Method, except that positional data (ACR in this case) is used to break ties, without throwing out the Condorcet ordering.

### Rating levels

KR2 ballots can defined before the poll to use multiple rating groups. If no groups are configured, then the vote is a Condorcet-compliant ranked choice algorithm. Testing has so far shown it to be comparable to the Schulze 2004 or Tideman 1987 (Ranked Pairs) methods. If multiple rating groups are defined, then "rating bound markers" between the groups are inserted in each ballot by the vote entry system. By definition of the algorithm, these markers must all be present in the correct order. Otherwise a ballot missing any rating bound markers or using them out of order must be rejected.

The number of rating groups in a KR2 election are called levels. The definition of a poll/election must include a level number if one is desired. Otherwise Level 1 is the default setting.

Level 1 has only one group, and therefore no rating bound markers. This is equivalent to a regular Condorcet ranked-choice election. The ballot does not present rating options. Choices are not marked as eliminated in the results. (This is the least complicated level, but collects no rating information.)

Level 2 has two groups to rank choices: support and oppose. Each ballot contains a rating bound marker called "\_neutral". Choices which are omitted from any ballot are inserted as tied with each other and the "\_neutral" marker. Choices are not marked as eliminated in the results, but can be seen whether they are above or below the "\_neutral" marker.

Level 3 has three groups to rank choices: support, neutral and oppose. Each ballot contains rating bound markers called "\_support" and "\_oppose". Choices which are omitted from any ballot are inserted as tied with each other just above the "\_oppose" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_oppose" marker. (This level is the recommended maximum for non-technical audiences.)

Level 4 has four groups to rank choices: strong support ("\_support2"), weak support ("\_support1"), weak oppose ("_oppose1") and strong oppose ("\_oppose2"). Each ballot contains rating bound markers called "\_support2", "\_neutral" and "\_oppose2". Choices which are omitted from any ballot are inserted as tied with each other and the "\_neutral" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_neutral" marker.

Level 5 has five groups to rank choices: strong support ("\_support2"), weak support ("\_support1"), neutral, weak oppose ("_oppose1") and strong oppose ("\_oppose2"). Each ballot contains rating bound markers called "\_support2", "\_support1", "\_oppose1" and "\_oppose2". Choices which are omitted from any ballot are inserted as tied with each other just above the "\_oppose1" marker. Choices are marked as eliminated and cannot win if the results place them below the "\_oppose1" marker. (This is the most complicated level, but obtains the most data on voter intent.)

# METHODS

These methods are in addition to [those inherited from PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore#METHODS).

- make\_pair\_node

    This should not be called by external code.

    This method is called by add\_preference and set\_mov to initialize a pair node for a
    specific pair of candidates if it didn't already exist.
    The parameters are the ids of the two candidates of the pair in order of counting preferences
    of the first over the second.
    A separate pair node counts preferences in the opposite direction.

- add\_preference

    This method records a counted candidate-pair preference.
    The parameters are the ids of the two candidates for the pair, and the quantity of ballots by which to increment it.
    The quantity is a function of how many ballots contained a specific permutation of candidates.

- get\_preference

    This method returns the vote count for a specific candidate pair, indicating how many ballots had a preference for
    the first candidate over the second.
    If called before counting is complete, this yields the in-progress tally for that candidate pair.

- set\_mov

    This should not be called by external code.

    This sets the margin of victory for a candidate pair.
    The parameters are the ids of the two candidates for the pair, and the margin of victory of votes counted.
    This counts both wins, adding votes for the first candidate over the second, and losses,
    subtracting votes for the second candidate over the first.
    So the corresponding pair reversing the order of the two candidates must be the negative of the same value.

- get\_mov

    This reads the margin of victory for a candidate pair.
    The parameters are the ids of the two candidates for the pair.

- cand\_copeland\_score

    This returns a candidate's Copeland Score, which is the number of wins minus the number of losses from the victory table.
    The parameter is the id of the candidate.

- tally\_preferences

    This should not be called by external code.
    This is called by the count() method.

    This tallies the ballots which were already stored by PrefVote::Core::submit\_ballot().
    This is where each entry in a ranked preference order is counted as a preference over all
    following lower-ranked candidates.
    Omitted candidates are counted as equal to each other, inserted at a neutral point for the level number. (See algorithm definition avove.)
    This calls _add\_preference()_ to register preferences from ballots into the candidate pair matrix.

- compute\_condorcet

    This performs pairwise counting to generate Condorcet result ordering,
    also using PrefVote's ACR (average choice rank) for tie-breaking.

- count

    This counts votes using the KR2 (Kluft Rank-Rate) method.
    The count() method of [PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore) is overridden by _PrefVote::KR2_ in order to implement
    the KR2 voting algorithm.

# SEE ALSO

[PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore)

The Kluft Rank-Rate (KR2) preference voting algorithm is experimental.
As documentation is written it will be posted at [https://ikluft.github.io/prefvote/doc/kr2/](https://ikluft.github.io/prefvote/doc/kr2/).

PrefVote on GitHub [https://github.com/ikluft/prefvote](https://github.com/ikluft/prefvote)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/prefvote/issues](https://github.com/ikluft/prefvote/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/prefvote/pulls](https://github.com/ikluft/prefvote/pulls)
