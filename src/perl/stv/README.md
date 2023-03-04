# PrefVote::STV

# SYNOPSIS

    use PrefVote::STV;
    %vote_params = ( "name" => "value", ... );
    $vote = new PrefVote::STV \%vote_params;

# DESCRIPTION

# ATTRIBUTES

- winners
- eliminated
- rounds

# METHODS

- new\_round()
- current\_round()
- add\_winner(name, ...)
- add\_eliminated(name, ...)
- cand\_is\_winner(name)
- cand\_is\_eliminated(name)
- run\_tally()
- process\_winners()
- eliminate\_losers()
- count()
- results()

# SEE ALSO

[PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore)

Single Transferable Vote (STV) method on Wikipedia [https://en.wikipedia.org/wiki/Single\_transferable\_vote](https://en.wikipedia.org/wiki/Single_transferable_vote)

PrefVote on GitHub [https://github.com/ikluft/prefvote](https://github.com/ikluft/prefvote)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/prefvote/issues](https://github.com/ikluft/prefvote/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/prefvote/pulls](https://github.com/ikluft/prefvote/pulls)
