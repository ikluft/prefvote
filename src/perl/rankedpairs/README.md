# PrefVote::RankedPairs

# SYNOPSIS

    use PrefVote::RankedPairs;
    %vote_params = ( "name" => "value", ... );
    $vote = new PrefVote::RankedPairs \%vote_params;

# DESCRIPTION

# ATTRIBUTES

- winners
- pair
- majority
- graph

# METHODS

- make\_pair\_node 
- add\_preference
- get\_preference
- set\_mov
- get\_mov
- set\_lock
- get\_lock
- graph\_add\_link
- cand\_total\_wins
- cand\_total\_mov
- tally\_preferences
- sort\_pairs
- depth\_first\_search
- is\_conflict
- lock\_pairs
- cmp\_choice
- graph\_to\_order
- count

# FUNCTIONS

- item2list

# SEE ALSO

[PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore)

Ranked Pairs voting method on Wikipedia [https://en.wikipedia.org/wiki/Ranked\_pairs](https://en.wikipedia.org/wiki/Ranked_pairs)

PrefVote on GitHub [https://github.com/ikluft/prefvote](https://github.com/ikluft/prefvote)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/prefvote/issues](https://github.com/ikluft/prefvote/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/prefvote/pulls](https://github.com/ikluft/prefvote/pulls)
