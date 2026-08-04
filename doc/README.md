PrefVote documentation
======================

The ranked choice voting algorithms in PrefVote can serve purposes for elections and polls. The larger end of the use cases are for elections of public positions or private organizations where one or more winners are chosen from the top of the election ranking. Among the smaller-scale cases, they can be used by teams or groups to combine individual preference rankings into a group ranking. Ranked choice polling can also be used for multiple-choice decisions in meetings or electronic polls.

## File formats

* [PrefVote_YAML_input.md](PrefVote_YAML_input.md) - YAML input format for PrefVote
* [PrefVote_CEF_input.md](PrefVote_CEF_input.md) - PrefVote implementation of the proposed Condorcet Election Format (CEF)

## Voting method research

* [KR2 (Kluft Rank-Rate)](kr2/) voting algorithm documentation

## Code libraries

### Legacy Algorithm Base ("LAB")

* [Core](../lab/perl/prefvote) (Perl 🧅)
* [KR2 (Kluft Rank-Rate)](../lab/perl/kr2/) algorithm development (Perl 🧅)

algorithm code maintained for comparison to KR2

* [Single Transferable Vote (STV)](../lab/perl/stv) (Perl 🧅)
* [Schulze](../lab/perl/schulze) (Perl 🧅)
* [Ranked Pairs](../lab/perl/rankedpairs) (Perl 🧅)
