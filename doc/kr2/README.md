Kluft Rank-Rate (KR2) voting method
===================================

## Experimental voting method

This is an area for experimentation with the Kluft Rank-Rate (KR2) voting method.  The experiment has been testing the algorithm against test data and, with satisfactory results so far, has led to writing a paper about it.

## Simplifying Condorcet for acceptance by the public

In elections, ["Ranked Choice Voting" (RCV)](https://electowiki.org/wiki/Instant-runoff_voting) is becoming more widely accepted as a step up from the old "First Past the Post" (FPTP) voting. Instead of voting for just one candidate, Ranked Choice allows voters to submit their preferences in order. With more information available about voters' intentions, the system can eliminate run-off elections by handling everything in one pass.

While RCV is a big step up from FPTP, there are limitations to the ["Single Transferable Vote" (STV)](https://electowiki.org/wiki/Single_transferable_vote) method which is usually used to implement what is called Instant Runoff Voting (IRV). The method eliminates a candidate from the bottom of the list if no one wins, or picks from the top of the list if they win. In this multi-winner variant, votes are processed again in multiple rounds, transferring votes to the next choices on voters' ballots as their initial choices get eliminated. While STV is better than FPTP, in close elections STV can have some quirks on which candidates to whom it transfers votes.

There are better algorithms at capturing voters' intent, including properly differentiating similar candidates without splitting the vote between them. Variations of the [Condorcet Method](https://electowiki.org/wiki/Condorcet_method) make pairwise comparisons of candidates' wins against others, and pick one if they are preferred against everyone else. But Condorcet methods all add complicated tie-breaking. These have been accepted by mathematicians and computer scientists as better voting methods.

But they're too complicated to explain to the non-technical public. While the [Schulze]() and [Tideman/Ranked Pairs]() methods are mathematically and technically sound, they involve graph theory which is too complex to explain toward public acceptance. We must solve that before Condorcet algorithms can break through to become acceptable for wider public use.

## The Kluft Rank-Rate (KR2) method

With the Schulze and Tideman algorithms named for their authors, I call this the Kluft Rank-Rate (KR2) method.

Technical documentation in the [PrefVote::KR2 module source code directory](../lab/perl/kr2/).

A paper on the algorithm will be written in this directory.
