# PrefVote

PrefVote is a project to promote use and understanding of preference voting methods and algorithms. It is derived from the Vote::STV software written by Ian Kluft in Perl originally in 1999.

Since the project's original language Perl has strengths in prototyping, it's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is intended to have a common test suite among the different implementations to verify proper functioning.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting).

## Example voting result from test suite

This is an example result from a Single Transferable Vote from the test suite. 250 ballots were randomly generated. So there's no actual meaning to the result except testing the software. Candidate names are fictitious, just to get names that start with A, B, C, D, E and F as used universally throughout the test suite. The names are whimsical based on the difficult dilemma voters sometimes feel they are choosing between in real candidates.

> ```
> Results: Test Vote
> 
> ┌───────────────┬─────────────────────────────┐
> │ Abbreviation  │ Name/description            │
> ├───────────────┼─────────────────────────────┤
> │ FACTIOUS      │ factious/divisive candidate │
> │ EVIL          │ evil villain                │
> │ CHAOTIC       │ chaotic unpredictable       │
> │ ABNORMAL      │ abnormal and antisocial     │
> │ BORING        │ boring as anything          │
> │ DYSFUNCTIONAL │ dysfunctional incompetent   │
> └───────────────┴─────────────────────────────┘
> ┌─────────┬──────────┬──────────┬─────────────┬─────────┬──────────┬────────┬───────────────┐
> │ Round # │ Quota    │ FACTIOUS │ EVIL        │ CHAOTIC │ ABNORMAL │ BORING │ DYSFUNCTIONAL │
> ├─────────┼──────────┼──────────┼─────────────┼─────────┼──────────┼────────┼───────────────┤
> │ 1       │ 125      │ 68       │ 54          │ 36      │ 31       │ 33     │ 28 ❌         │
> │ 2       │ 124.5    │ 75       │ 58          │ 45      │ 36       │ 35 ❌  │ ❌            │
> │ 3       │ 122      │ 78       │ 69          │ 51      │ 46 ❌    │ ❌     │ ❌            │
> │ 4       │ 118.5    │ 90       │ 81          │ 66 ❌   │ ❌       │ ❌     │ ❌            │
> │ 5       │ 114      │ 118 ✓    │ 110         │ ❌      │ ❌       │ ❌     │ ❌            │
> │ 6       │ 56.50847 │ ✓        │ 113.01695 ✓ │ ❌      │ ❌       │ ❌     │ ❌            │
> └─────────┴──────────┴──────────┴─────────────┴─────────┴──────────┴────────┴───────────────┘
> ```

STV is the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. Next up will be the Schulze algorithm.
