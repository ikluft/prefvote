PrefVote implementation in Perl
=====
Module subdirectories for voting methods:

  * [PrefVote::Core](prefvote)
  * [PrefVote::STV](stv)
  * [PrefVote::Schulze](schulze)
  * [PrefVote::RankedPairs](rankedpairs)
  * [PrefVote::KR2](kr2)

PrefVote::Core is not a complete (preferential) voting method. It is only a cardinal voting method used as a tie-breaker in all the other algorithms. All the other voting method modules inherit from PrefVote::Core.

Extra modules for tools and examples help keep optional dependencies separate from the core modules.

  * [PrefVote::Core::Output::Template](output-template) - dependencies: [Template Toolkit](https://metacpan.org/pod/Template)
  * [PrefVote::WebUI](webui) - dependencies: [Mojolicious](https://metacpan.org/pod/Mojolicious)
