Kluft Rank-Rate (KR2) voting method
===================================

The Kluft Rank-Rate (KR2) voting method is intended to advance preference/ranked choice voting. Condorcet-compliant voting methods have been around for decades, making pairwise comparison of voter preferences between candidates. They have proven to be technically sound. But complexity has been a barrier to public acceptance. All Condorcet methods have some kind of tie-breaking when no candidates win outright on the Condorcet criteria. Use of graph algorithms has been common. For tie-breaking, the KR2 algorithm uses a cardinal method. The algorithm has been tested against random voting data and, with satisfactory results so far, the next step is to write a paper about it.

KR2 adds an additional feature of rating levels. These are optionally selected by the administrator before starting the poll. If enabled, voters rate choices by approval, opposition or neutrality. The KR2 level indicates how many rating groups are used.

* At Level 1, rating is disabled and everything is in one group, like other ranked voting algorithms. (KR2 still differs from other Condorcet methods by using average choice rank for tie-breaking.)
* Level 2 has two rating groups: approve and oppose.
* Level 3 has three rating groups: approve, neutral and oppose. This is expected to be the most common.
* Level 4 has four rating groups: strong approve, approve, oppose and strong oppose.
* Level 5 has five rating groups: strong approve, approve, neutral, oppose and strong oppose.

The ratings are handled by including rating bound markers in the ballot to divide the voter's choices. The bound markers are excluded from lists of winning or losing choices, but can be configured as thresholds of acceptance or rejection. The rating bound markers must be in the correct order, wherever they are among the voter's selections - otherwise the ballot will be rejected. The results will then include rating bound markers among the list of choices. Results which show choices falling below the threshold(s) of opposition are marked as eliminated, even if it leaves one or more available seats of a multi-winner race vacant.

## Simplifying Condorcet for acceptance by the public

In elections, ["Ranked Choice Voting" (RCV)](https://electowiki.org/wiki/Instant-runoff_voting) is becoming more widely accepted as a step up from the old ["First Past the Post" (FPTP)](https://electowiki.org/wiki/First_Past_the_Post_electoral_system) voting. Instead of voting for just one candidate, Ranked Choice allows voters to submit their preferences in order. With more information available about voters' intentions, the system can eliminate run-off elections by handling everything in one pass.

While RCV is a big step up from FPTP, there are limitations to the ["Single Transferable Vote" (STV)](https://electowiki.org/wiki/Single_transferable_vote) method which is usually used to implement what is called Instant Runoff Voting (IRV). The method eliminates a candidate from the bottom of the list if no one wins, or picks from the top of the list if they win. In this multi-winner variant, votes are processed again in multiple rounds, transferring votes to the next choices on voters' ballots as their initial choices get eliminated. While STV is better than FPTP, in close elections STV can have some quirks on which candidates to whom it transfers votes. That effect has been used by opponents (such as proponents of other voting methods) to downplay RCV.

There are better ranked choice algorithms at capturing voters' intent, including properly differentiating similar candidates without splitting the vote between them. Variations of the [Condorcet Method](https://electowiki.org/wiki/Condorcet_method) make pairwise comparisons of candidates' wins against others, and pick one if they are preferred against everyone else. But there isn't always a "Condorcet winner" who beats all other candidates in pairwise comparisons. So all Condorcet-based voting methods add some form of tie-breaking to select a winner. Condorcet methods are accepted by mathematicians and computer scientists as much more effective voting methods than FPTP or STV.

So Condorcet methods are better. But they tend to be too complicated to explain to the non-technical public. While the [Schulze](https://electowiki.org/wiki/Schulze_method) and [Tideman/Ranked Pairs](https://electowiki.org/wiki/Ranked_Pairs) methods are mathematically and technically sound, they involve graph theory algorithms which are much too complex to explain for public acceptance. We must solve that before Condorcet algorithms can break through to become acceptable for wider public use.

## The Kluft Rank-Rate (KR2) method

With the Schulze and Tideman algorithms named for their authors, I call this the Kluft Rank-Rate (KR2) method.

Technical documentation is in the [PrefVote::KR2 module source code directory](../../lab/perl/kr2/).

A paper on the algorithm will be written in this directory.

#### Algorithm

The Kluft Rank-Rate (KR2) voting method combines ranked choice ballots in multiple rating groups to incorporate approval or opposition information into a ranked choice poll or election. KR2 polls/elections can have single or multiple winners, depending on the number of seats (winners per election) configured for the poll.

#### Condorcet compliance

KR2 is a Condorcet-compliant system. That means the definition starts with using ranked preference ballot data to perform pairwise comparisons among all candidates. If one candidate beats all the others in pairwise comparisons, then that candidate wins.

It is possible for close elections to have two or more candidates either tie or make a cycle of beating each other which prevents having one pairwise winner. All Condorcet methods differ in how to handle these ties, also known as the Condorcet Paradox. KR2 orders the candidates by their Copeland Score, which is the number of pairwise wins minus the pairwise losses, with pairwise ties counting as zero. It acts like a round-robin tournament, where competing teams play against each other to make such a ranking order. Except the ranked preference ballots contain enough information to order the candidates by Copeland Score. A Condorcet Winner, if present, will always win this ranking.

#### Condorcet tie-breaking

Otherwise ties are broken by using the average choice rank (ACR) where 1st choice equals 1, 2nd choice is 2, etc. ACR is used as a secondary sorting criteria so that it won't break Condorcet ordering. ACR is mathematically equivalent to a Borda Count, except reversed to favor lower numbers instead of higher, because of the simplicity value of first place being 1. Thus far, the algorithm is like Black's Method, except that positional data (ACR in this case) is used to break ties, without throwing out the Condorcet ordering.

#### Rating levels

KR2 ballots can defined before the poll to use multiple rating groups. If no groups are configured, then the vote is a Condorcet-compliant ranked choice algorithm. Testing has so far shown it to be comparable to the Schulze 2004 or Tideman 1987 (Ranked Pairs) methods.

If multiple rating groups are defined, then "rating bound markers" between the groups are inserted in each ballot by the vote entry system at the boundaries as specified by the voter, such as between approve and neutral. By definition of the algorithm, these markers must all be present in the correct order. A ballot missing any rating bound markers or using them out of order must be rejected. For that reason, the rating bound markers must be added by the ballot-input system, using data where the voter sees the ballot grouped by the rating levels.

The number of rating groups in a KR2 election are called levels. The definition of a poll/election must include a level number if one is desired. Otherwise Level 1 is the default setting.

The default setting at Level 1 is compatible with other ranked choice voting algorithms, taking input ballots with the voter's ranking order and no rating bound markers. At that level, it still differentiates from other ranked choice algorithms by how it breaks a Condorcet tie/paradox using average choice rank (ACR).

##### Comparisons involving rating bound markers

In computation, sorting a list involves comparisons between each of the items. A corner case introduced by KR2's rating bound markers is how to handle comparisons when these markers are one or both of the items being compared in result sorting. The following rules were made to handle this scenario:

* As in other comparison functions between parameters p1 and p2, 0 means equal/tie, -1 means p1 &lt; p2, +1 means p1 &gt; p2
* If p1 and p2 are regular ballot items: equality is a tie (0)
* If p1 and p2 are both rating bound markers: support2 &gt; support &gt; neutral &gt; oppose &gt; oppose2
* In a tie between a regular ballot item and an oppose marker: the oppose marker is greater (rationale: tying with an oppose marker indicates the option is generally opposed)
* In a tie between a regular ballot item and a support or neutral marker: the support or neutral marker is less (rationale: tying with a support or neutral marker indicates the item is included at the marker's level)

<table border="1">
<tr>
<th rowspan="2" colspan="2">&nbsp;</th>
<th colspan="6" align="center">p2</th>
</tr>
<tr>
<th>item</th>
<th>support2</th>
<th>support</th>
<th>neutral</th>
<th>oppose</th>
<th>oppose2</th>
</tr>
<tr>
<th rowspan="6">p1</th>
<th>item</th>
<td>0</td>
<td>+1</td>
<td>+1</td>
<td>+1</td>
<td>-1</td>
<td>-1</td>
</tr>
<tr>
<th>support2</th>
<td>-1</td>
<td>n/a</td>
<td>+1</td>
<td>+1</td>
<td>+1</td>
<td>+1</td>
</tr>
<tr>
<th>support</th>
<td>-1</td>
<td>-1</td>
<td>n/a</td>
<td>+1</td>
<td>+1</td>
<td>+1</td>
</tr>
<tr>
<th>neutral</th>
<td>-1</td>
<td>-1</td>
<td>-1</td>
<td>n/a</td>
<td>+1</td>
<td>+1</td>
</tr>
<tr>
<th>oppose</th>
<td>+1</td>
<td>-1</td>
<td>-1</td>
<td>-1</td>
<td>n/a</td>
<td>+1</td>
</tr>
<tr>
<th>oppose2</th>
<td>+1</td>
<td>-1</td>
<td>-1</td>
<td>-1</td>
<td>-1</td>
<td>n/a</td>
</tr>
</table>
