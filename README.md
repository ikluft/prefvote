# PrefVote: Preference Voting library

PrefVote is a project to promote preference voting.

Implementations of several ranked-choice voting methods and algorithms are included in the ["LAB" (Legacy Algorithm Base)](lab/) directory. The Single Transferable Vote (STV) implementation is descended from the Vote::STV software written by Ian Kluft in Perl in 1999, with periodic maintenance over the years. Implemenation and experimentation with Condorcet-based algorithms Schulze and Ranked Pairs showed the flaws of STV, and why it has fallen out of favor.

 Since the project's original language Perl has strengths in prototyping, that's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is designed with a [common test suite](test/) among the different implementations to verify proper functioning.
 
 The legacy algorithms are in the [lab](lab/) directory. A newer algorithm "KR2" (Kluft Rank-Rate) is under experimentation in what is the new main source directory [src](src/).
 
 Project-wide documentation is in the [doc](doc/) directory.