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

# METHODS

These methods are in addition to [those inherited from PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore#METHODS).

- make\_pair\_node

    This should not be called by external code.

    This method is called by add\_preference, set\_mov and set\_lock to initialize a pair node for a
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

- cand\_total\_mov

    This returns a candidate's total of their margins of victory.
    The parameter is the id of the candidate.

- tally\_preferences

    This should not be called by external code.
    This is called by the count() method.

    This tallies the ballots which were already stored by PrefVote::Core::submit\_ballot().
    This is where each entry in a ranked preference order is counted as a preference over all
    following lower-ranked candidates.
    Omitted candidates are counted as equals but less preferred than all other candidates for that ballot.
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
