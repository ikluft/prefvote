Kluft Rank-Rate (KR2) voting method
===================================

## Experimental voting method

This is an area for experimentation with the Kluft Rank-Rate (KR2) voting method.  The experiment will test the algorithm against test data and, if results are satisfactory, could lead to writing a paper about it.

## Simplifying Condorcet for acceptance by the public

In elections, ["Ranked Choice Voting" (RCV)](https://electowiki.org/wiki/Instant-runoff_voting) is becoming more widely accepted as a step up from the old "First Past the Post" (FPTP) voting. Instead of voting for just one candidate, Ranked Choice allows voters to submit their preferences in order. With more information available about voters' intentions, the system can eliminate run-off elections by handling everything in one pass.

While RCV is a big step up from FPTP, there are limitations to the ["Single Transferable Vote" (STV)](https://electowiki.org/wiki/Single_transferable_vote) method which is usually used to implement it. The method eliminates a candidate from the bottom of the list if no one wins, or from the top of the list if they win. Then votes are processed again in multiple rounds, transferring votes to the next choices on voters' ballots as their initial choices get eliminated. While STV is better than FPTP, in close elections STV can have some quirks.

There are better algorithms at capturing voters' intent, including properly differentiating similar candidates without splitting the vote between them. Variations of the [Condorcet Method](https://electowiki.org/wiki/Condorcet_method) make pairwise comparisons of candidates' wins against others, and pick one if they are preferred against everyone else. But Condorcet methods all add complicated tie-breaking. These have been accepted by mathematicians and computer scientists as better voting methods. But they're too complicated to explain to the non-technical public. Both the [Schulze]() and [Tideman/Ranked Pairs]() methods involve complex graph data structures to explain how they resolve Condorcet ties. We must solve that before Condorcet algorithms can break through to become acceptable by the general public.

## The Kluft Rank-Rate method

This is what I'm currently experimenting with. If tests show it works well, then it will be time to write a paper about the algorithm and the test results.

more details TBD
