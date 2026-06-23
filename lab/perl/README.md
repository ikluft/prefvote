PrefVote implementation in Perl
=====
Module subdirectories for voting methods:

  * [PrefVote::Core](prefvote)
  * [PrefVote::STV](stv)
  * [PrefVote::Schulze](schulze)
  * [PrefVote::RankedPairs](rankedpairs)
  * [PrefVote::KR2](kr2)

PrefVote::Core is not a complete (preferential) voting method. It is only a cardinal voting method used as a tie-breaker in all the other algorithms. All the other voting method modules inherit from PrefVote::Core.

Module subdirectories for tools and examples:

  * [PrefVote::WebUI](webui)

These are separate from the core to avoid adding unnecessary dependencies for optional use cases.
