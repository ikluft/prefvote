# SYNOPSIS

    use PrefVote::RankedPairs;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::RankedPairs::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...

# DESCRIPTION

_PrefVote::RankedPairs_ implements the Ranked Pairs preference voting algorithm for the _PrefVote_
system.
The Ranked Pairs method was created in 1987 by Nicolaus Tideman.
Eash voter's ballot ranks available candidates in order of the voter's preference.
This method compares each pair of candidates by the numbers ofvoter preference,
and ranks the candidate pairs in order of strongest wins.
The algorithm builds a graph structure of the wins starting with the strongest,
locking in each win that does not create a cycle in the graph.

The effect of Ranked Pairs is a Condorcet-compliant voting result in which any candidate who beats
all other candidates in pairwise comparisons will be the winner.
The graph algorithm also has limited tie-breaking capability beyond the pure Condorcet definition.

All of the _PrefVote_ algorithms have an additional layer of tie-breaking from the Average Choice
Rank (ACR) data. Though an average ballot position is a rating which would not alone be approprtiate
for elections, when a tie occurs, all other things are equal and so the ACR becomes a useful
indicator of the intent of the voters in that scenario.

# ATTRIBUTES

These attributes are in addition to [those inherited from PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore#ATTRIBUTES).

- winners

    the list of winners of the voting in order from first to last.
    The format is a list of sets of strings.

    - list of places

        list of each place in the results from first to last

    - set of candidates

        a set of the candidates which tie for that place, or only one if there is no tie

    - candidate identifier string

        a string with the identifier for the candidate in this position in the result

- pair

    internal hash used for counting candidate pairs in the Ranked Pairs result, and particularly for computing
    how much candidates win or lose against others.

- majority

    internal list used to track ordering of majorities, winning paired contests among candidates

- graph

    internal graph structure for computing Ranked Pairs results from pair comparisons and the list of majorities.
    Candidate pair comparisons are only added to the result if they would not create a loop/conflict in the graph.

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

- set\_lock

    This should not be called by external code.

    The sets the lock status for a candidate pair in the direction of the first over the second.
    The parameters are the ids of the two candidates for the pair.
    This lock means the first candidate won over the second in pairwise comparisons.
    Once a win is locked for the first candidate over the second,
    this must not also be called to set a lock in the opposite direction,
    stating a win for the second candidate over the first.

- get\_lock

    Returns 1 if the candidate pair is locked, 0 if not.
    The parameters are the ids of the two candidates for the pair.

- graph\_add\_link

    This should not be called by external code.

    This sets a directed link in the Ranked Pairs algorithm graph.
    It's how Ranked Pairs computes winning candidate order.
    The parameters are the ids of the two candidates for the pair.

- cand\_total\_wins

    This returns the count of total wins for a candidate over other candidates.
    The parameter is the id of the candidate.

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

- sort\_pairs

    This should not be called by external code.
    This is called by the count() method.

    This generates a list of all possible pairs of candidates as [PrefVote::RankedPairs::Majority](https://metacpan.org/pod/PrefVote%3A%3ARankedPairs%3A%3AMajority)
    objects, computing a margin of victory for each pair.
    Then it sorts the list of pairs from greatest to least margin of victory.

- depth\_first\_search

    This should not be called by external code.

    This is called by is\_conflict().
    It performs a depth-first search of the Ranked Pairs graph from a specific node,
    looking for another candidate (the other candidate in a pair)
    to find out if there's a path between them.

- is\_conflict

    This checks the Ranked Pairs graph to determine if a given candidate pair conflicts with prior pairs,
    those with higher margins of victory.
    It returns true if there is a conflict, false otherwise.

    This is used to determine whether a candidate pair can be locked in the order.
    A pair with the first candidate winning over the second will be processed first and get locked.
    Later when the same pair in the opposite order is encountered, it will be considered in conflict with
    the earlier pair, and will not be locked.
    Also ties will not be locked in either direction.

- lock\_pairs

    This should not be called by external code.
    This is called by the count() method.

    This loops through the candidate pairs and locks pairs which do not conflict with earlier pairs.
    This is a key step of the Ranked Pairs alogorithm.
    It takes no parameters, using the previously assembled list of [PrefVote::RankedPairs::Majority](https://metacpan.org/pod/PrefVote%3A%3ARankedPairs%3A%3AMajority)
    objects representing all the candidate pairs.

- cmp\_choice

    This is a comparison function for sorting Ranked Pairs vote results.
    The parameters are the candidate identifiers for two candidates to be compared.
    Like the <=> operator, it returns -1 for less-than, 0 for equality and 1 for greater-than.

- graph\_to\_order

    This should not be called by external code.
    This is called by the count() method.

    This populates the winners list based on the contents of the Ranked Pairs graph.

- count

    This counts votes using the Ranked Pairs method.
    The count() method of [PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore) is overridden by _PrefVote::RankedPairs_ in order to implement
    the Ranked Pairs voting algorithm.

# FUNCTIONS

- item2list

    This returns a ballot item as a list, whether it was a single scalar or a tie-group set.
    The Ranked Pairs definition does not allow input ties.
    PrefVote can be configured to allow it for consistency across Condorcet methods.

    The parameter is an item from a [PrefVote::Core::Ballot](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3ABallot) object.

# SEE ALSO

[PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore)

Ranked Pairs voting method on Wikipedia [https://en.wikipedia.org/wiki/Ranked\_pairs](https://en.wikipedia.org/wiki/Ranked_pairs)

PrefVote on GitHub [https://github.com/ikluft/prefvote](https://github.com/ikluft/prefvote)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/prefvote/issues](https://github.com/ikluft/prefvote/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/prefvote/pulls](https://github.com/ikluft/prefvote/pulls)
