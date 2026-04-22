# PrefVote: Preference Voting library

by Ian Kluft

PrefVote is a project to promote preference voting.

Implementations of several ranked-choice voting methods and algorithms are included in the ["LAB" (Legacy Algorithm Base)](lab/) directory. The Single Transferable Vote (STV) implementation is descended from the Vote::STV software I wrote in Perl in 1999, with periodic maintenance over the years. Implementation and experimentation with Condorcet-based algorithms Schulze and Ranked Pairs helped me better understand the flaws of STV, and why it has fallen out of favor among those looking for better voting algorithms.

Since the project's original language Perl has strengths in prototyping, that's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is designed with a [common test suite](test/) among the different implementations to verify proper functioning.
 
The legacy algorithms are in the [lab](lab/) directory, where the reference implementation in Perl is instrumented for study and testing. In addition to the older voting algorithms, a new algorithm "KR2" (Kluft Rank-Rate) is under experimentation.
 
Project-wide documentation is in the [doc](doc/) directory.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting), also called preference voting. PrefVote has expanded into a library of multiple voting method implementations all based on ranked choice.

STV was the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. But STV has largely fallen out of favor because studies of voting methods found it lacking on some desirable characteristics, particularly in close elections. STV was retained while modernizing the code to develop testing infrastructure.

No voting method can be perfect, due to a long list of desirable properties, some of which [turn out to be in conflict](https://electowiki.org/wiki/Arrow%27s_impossibility_theorem). Given that there is no perfect voting method, it's important to have agreement among a community on which method it uses. Methods which meet [Condorcet requirements](https://electowiki.org/wiki/Condorcet_method) make comparisons between each pair of candidates and picks a winner who beats all other candidates in pairwise comparisons, if such a winner exists. Condorcet methods differ in how to handle cases where there isn't a clear Condorcet winner. Cycles can happen where a subset of leading candidates fail to beat the others in that group.

The second voting method implemented in PrefVote was the [Schulze algorithm](https://en.wikipedia.org/wiki/Schulze_method) (see [full definition paper)](https://arxiv.org/abs/1804.02973). The method was designed by Marcus Schulze in 1997 to compute a graph out of voter preferences among candidates and pick the ones preferred over all others. An ordering of all the candidates can be computed over multiple rounds after removing the previous round's winner(s).

Next was [Ranked Pairs](https://en.wikipedia.org/wiki/Ranked_pairs). It was designed by Nicolaus Tideman in 1987. It tallies ranked choice ballots into pairwise comparisons among all choices/candidates. The pairs are sorted by margin of victory from largest margin down to ties at zero. Pairs are "locked" in for consideration of the final order of candidates if they do not conflict with locked pairs with larger margins. Candidates are then ordered starting who beats all other candidates, then each who beat all remaining candidates.

After the reference implementation in Perl, next up for language implementations will be [Rust](https://www.rust-lang.org/).

### Preference voting online resources

Here is general information about preference voting algorithms.

* [ElectoWiki](https://electowiki.org/), electoral systems wiki
* Wiki articles
  * Comparison: [electowiki](https://electowiki.org/wiki/Main_Page) [wikipedia](https://en.wikipedia.org/wiki/Comparison_of_electoral_systems)
  * Ranked voting: [electowiki](https://electowiki.org/wiki/Ranked_voting) [wikipedia](https://en.wikipedia.org/wiki/Ranked_voting)
  * Instant-runoff voting: [electowiki](https://electowiki.org/wiki/Instant-runoff_voting) [wikipedia](https://en.wikipedia.org/wiki/Instant-runoff_voting)
  * Condorcet method: [electowiki](https://electowiki.org/wiki/Condorcet_method) [wikipedia](https://en.wikipedia.org/wiki/Condorcet_method)
  * Schulze method: [electowiki](https://electowiki.org/wiki/Schulze_method) [wikipedia](https://en.wikipedia.org/wiki/Schulze_method)
  * Ranked Pairs: [electowiki](https://electowiki.org/wiki/Ranked_Pairs) [wikipedia](https://en.wikipedia.org/wiki/Ranked_pairs)
  * Condorcet Paradox: [electowiki](https://electowiki.org/wiki/Condorcet_paradox) [wikipedia](https://en.wikipedia.org/wiki/Condorcet_paradox)
  * Smith set: [electowiki](https://electowiki.org/wiki/Smith_set) [wikipedia](https://en.wikipedia.org/wiki/Smith_set)
  * voting system criteria: [electowiki](https://electowiki.org/wiki/Voting_system_criterion) [wikipedia](https://en.wikipedia.org/wiki/Voting_criteria)
* [FairVote](https://www.fairvote.org/), nonpartisan group promoting ranked choice voting (RCV) and proportional representation (PR)
* ["What is Democracy?" video series](http://www.professorbray.net/Teaching/GTD/2020-SummerTerm2/GTD.html), Prof HL Bray, Duke University
* ["Voting and Elections"](https://www.ams.org/publicoutreach/feature-column/fcarc-voting-introduction), American Mathematical Society articles
* [papers defining Schulze voting method](http://www.9mail.de/m-schulze/), Marcus Schulze, posted 2004-2012
* [Condorcet Voting](https://effectivegov.uchicago.edu/primers/condorcet-voting), part of Democracy Reform Primer Series, University of Chicago Center for Effective Government
* [Voting Methods](https://plato.stanford.edu/entries/voting-methods/), Stanford Encyclopedia of Philosophy

## Input file format

The original and primary input file format of PrefVote is YAML with a predefined data structure. There is [documentation for the data format](doc/PrefVote_YAML_input.md). Also, when PrefVote is used as a library any data can be submitted by calling functions directly.

In support of a proposed Open Source standard for preference voting systems, PrefVote also supports the [Condorcet Election Format (CEF)](https://github.com/CondorcetVote/CondorcetElectionFormat), or CEF. There is [documentation for PrefVote's support for CEF input files](doc/PrefVote_CEF_input.md).

## Tie-breaking modifications to algorithms

PrefVote modifies all the algorithms in one way. It adds a tie-breaking factor using the average ballot-position ranking of a choice/candidate. It started as experimentation with intuition that the average ranking of a choice was indicative of the will of the voters. Though it wouldn't be acceptable as a primary factor because averages don't have quantitative data - and quantitative data is paramount to meeting the expectation that the candidate with the most votes must be the winner. Test runs show that it approximates Condorcet results fairly well and converges with Condorcet by around 100 random ballots. It didn't even need to be that close to Condorcet to convey meaning about voter's preferences. That's because this tie-breaking method restores ballot-position ordering information which Condorcet lacks.

PrefVote's Core module from which all the voting methods inherit common code is not a voting method itself. In performing the counting of average choice ranking (ACR) for other methods to use for tie-breaking, it contains results which can be displayed for testing purposes. Since it only uses average ranking, it really must not be used for actual voting. There is a principle in voting that every vote counts. That means quantitative factors must be the primary ordering for results. ACR turns out to be well-suited to be a second sorting factor for tie-breaking because with all other things being equal in the case of a tie, the voter ranking positions are data that wasn't used by Condorcet comparison.

ACR isn't a Condorcet-compliant method on its own, which PrefVote requires, except having grandfathered in STV. It's basically a cardinal voting method. So in case of a Condorcet paradox (tie), then ACR becomes useful as a tie-breaker method.


