# PrefVote

PrefVote is a project to promote use and understanding of preference voting methods and algorithms. It is derived from the Vote::STV software written by Ian Kluft in Perl originally in 1999.

Since the project's original language Perl has strengths in prototyping, it's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is intended to have a common test suite among the different implementations to verify proper functioning.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting).

## Example voting result from test suite

This is an example result from a Single Transferable Vote (STV) using a [file in the test suite](test/inputs/100-rcv-test/001-rcv-test.yaml). 250 ballots were randomly generated. So there's no actual meaning to the result except testing the software.

> ```
> Results: Test Vote
> 1 seat available
> 
> ┌───────────────┬─────────────────────────────┬──────────────┐
> │ Abbreviation  │ Name/description            │ Result       │
> ├───────────────┼─────────────────────────────┼──────────────┤
> │ FACTIOUS      │ factious/divisive candidate │ 1/selected   │
> │ EVIL          │ evil villain                │ 2/placed     │
> │ CHAOTIC       │ chaotic unpredictable       │ 3/eliminated │
> │ ABNORMAL      │ abnormal and antisocial     │ 4/eliminated │
> │ BORING        │ boring as anything          │ 5/eliminated │
> │ DYSFUNCTIONAL │ dysfunctional incompetent   │ 6/eliminated │
> └───────────────┴─────────────────────────────┴──────────────┘
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

Notes about the example:

- Candidate names are fictitious, just to get names that start with A, B, C, D, E and F as used universally throughout the test suite. The names are whimsical based on the difficult dilemma voters sometimes feel they are choosing between in real candidates.

- The "Result" column shows a numerical place and disposition. The disposition will be one of
  
  - "selected" if the candidate/choice placed high enough to win an available seat
  
  - "tied" if a tie exists between multiple candidates and spans through at least one available seat and more than can be filled. It is the software's role to report this, not to decide what to do. Ties can and do happen. So an organization must have procedures to deal with them.
  
  - "placed" if the candidate placed after the last available seat, and therefore was not selected/elected.
  
  - "eliminated" if the candidate was eliminated from counting. A place number reflects order where the first or strongest elimination is ordered last.

STV is the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. Next up will be the Schulze algorithm.
