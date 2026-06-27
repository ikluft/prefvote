Kluft Rank-Rate (KR2) voting method
===================================

## Experimental voting method

This is an area for experimentation with the Kluft Rank-Rate (KR2) voting method.  The experiment has been testing the algorithm against test data and, with satisfactory results so far, has led to writing a paper about it.

## Simplifying Condorcet for acceptance by the public

In elections, ["Ranked Choice Voting" (RCV)](https://electowiki.org/wiki/Instant-runoff_voting) is becoming more widely accepted as a step up from the old "First Past the Post" (FPTP) voting. Instead of voting for just one candidate, Ranked Choice allows voters to submit their preferences in order. With more information available about voters' intentions, the system can eliminate run-off elections by handling everything in one pass.

While RCV is a big step up from FPTP, there are limitations to the ["Single Transferable Vote" (STV)](https://electowiki.org/wiki/Single_transferable_vote) method which is usually used to implement what is called Instant Runoff Voting (IRV). The method eliminates a candidate from the bottom of the list if no one wins, or picks from the top of the list if they win. In this multi-winner variant, votes are processed again in multiple rounds, transferring votes to the next choices on voters' ballots as their initial choices get eliminated. While STV is better than FPTP, in close elections STV can have some quirks on which candidates to whom it transfers votes.

There are better algorithms at capturing voters' intent, including properly differentiating similar candidates without splitting the vote between them. Variations of the [Condorcet Method](https://electowiki.org/wiki/Condorcet_method) make pairwise comparisons of candidates' wins against others, and pick one if they are preferred against everyone else. But there isn't always a "Condorcet winner" who beats all other candidates in pairwise comparisons. So all Condorcet methods add some form of tie-breaking to select a winner. But Condorcet methods are accepted by mathematicians and computer scientists as much more effective voting methods than FPTP or STV.

So Condorcet methods are better. But they tend to be too complicated to explain to the non-technical public. While the [Schulze]() and [Tideman/Ranked Pairs]() methods are mathematically and technically sound, they involve graph theory which is too complex to explain toward public acceptance. We must solve that before Condorcet algorithms can break through to become acceptable for wider public use.

## The Kluft Rank-Rate (KR2) method

With the Schulze and Tideman algorithms named for their authors, I call this the Kluft Rank-Rate (KR2) method.

Technical documentation is in the [PrefVote::KR2 module source code directory](../../lab/perl/kr2/).

A paper on the algorithm will be written in this directory.

#### Algorithm

The Kluft Rank-Rate (KR2) voting method combines ranked choice ballots in multiple rating groups to incorporate approval or opposition information into a ranked choice poll or election. KR2 polls/elections can have single or multiple winners, depending on the number of seats configured for the poll.

#### Condorcet compliance

KR2 is a Condorcet-compliant system. That means the definition starts with using ranked preference ballot data to perform pairwise comparisons among all candidates. If one candidate beats all the others in pairwise comparisons, then that candidate wins.

It is possible for close elections to have two or more candidates either tie or make a cycle of beating each other which prevents having one pairwise winner. All Condorcet methods differ in how to handle these ties, also known as the Condorcet Paradox. KR2 orders the candidates by their Copeland Score, which is the number of pairwise wins minus the pairwise losses, with pairwise ties counting as zero. It acts like a round-robin tournament, where competing teams play against each other to make such a ranking order. Except the ranked preference ballots contain enough information to order the candidates by Copeland Score. A Condorcet Winner, if present, will always win this ranking.

#### Condorcet tie-breaking

Otherwise ties are broken by using the average choice rank (ACR) where 1st choice equals 1, 2nd choice is 2, etc. ACR is used as a secondary sorting criteria so that it won't break Condorcet ordering. ACR is mathematically equivalent to a Borda Count, except reversed to favor lower numbers instead of higher, because of the simplicity value of first place being 1. Thus far, the algorithm is like Black's Method, except that positional data (ACR in this case) is used to break ties, without throwing out the Condorcet ordering.

#### Rating levels

KR2 ballots can defined before the poll to use multiple rating groups. If no groups are configured, then the vote is a Condorcet-compliant ranked choice algorithm. Testing has so far shown it to be comparable to the Schulze 2004 or Tideman 1987 (Ranked Pairs) methods. If multiple rating groups are defined, then "rating bound markers" between the groups are inserted in each ballot by the vote entry system. By definition of the algorithm, these markers must all be present in the correct order. Otherwise a ballot missing any rating bound markers or using them out of order must be rejected.

The number of rating groups in a KR2 election are called levels. The definition of a poll/election must include a level number if one is desired. Otherwise Level 1 is the default setting.
