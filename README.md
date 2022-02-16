# PrefVote

PrefVote is a project to promote use and understanding of preference voting methods and algorithms. It is derived from the Vote::STV software written by Ian Kluft in Perl originally in 1999.

Since the project's original language Perl has strengths in prototyping, it's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is intended to have a common test suite among the different implementations to verify proper functioning.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting).

STV is the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. But STV has largely fallen out of favor because studies of voting methods found it lacking on some desirable characteristics.

 While no voting method can be perfect, methods which meet Condorcet requirements are among the best around. So next up for voting methods will be the [Schulze algorithm](https://en.wikipedia.org/wiki/Schulze_method) (see [full definition paper)](https://arxiv.org/abs/1804.02973) and [Ranked Pairs](https://en.wikipedia.org/wiki/Ranked_pairs).

After the reference implementation in Perl, next up for language implementations will be [Rust](https://www.rust-lang.org/).

## Example voting result from test suite

This is an example result from a Single Transferable Vote (STV) using a [file in the test suite](test/inputs/100-rcv-test/001-rcv-test.yaml). 250 ballots were randomly generated. So there's no actual meaning to the result except testing the software.

<blockquote>
<div id="prefvote">
<h2>Results: Test Vote</h2>
<p>1 seat available</p>
<table>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>FACTIOUS</td>
<td>factious/divisive candidate</td>
<td>1/selected</td>
</tr>
<tr>
<td>EVIL</td>
<td>evil villain</td>
<td>2/placed</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>3/eliminated</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>4/eliminated</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>5/eliminated</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>6/eliminated</td>
</tr>
</tbody>
</table>
<table>
<thead>
<tr>
<th>Round #</th>
<th>Quota</th>
<th>FACTIOUS</th>
<th>EVIL</th>
<th>CHAOTIC</th>
<th>ABNORMAL</th>
<th>BORING</th>
<th>DYSFUNCTIONAL</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>125</td>
<td>68</td>
<td>54</td>
<td>36</td>
<td>31</td>
<td>33</td>
<td>28 ❌</td>
</tr>
<tr>
<td>2</td>
<td>124.5</td>
<td>75</td>
<td>58</td>
<td>45</td>
<td>36</td>
<td>35 ❌</td>
<td>❌</td>
</tr>
<tr>
<td>3</td>
<td>122</td>
<td>78</td>
<td>69</td>
<td>51</td>
<td>46 ❌</td>
<td>❌</td>
<td>❌</td>
</tr>
<tr>
<td>4</td>
<td>118.5</td>
<td>90</td>
<td>81</td>
<td>66 ❌</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
</tr>
<tr>
<td>5</td>
<td>114</td>
<td>118 ✅</td>
<td>110</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
</tr>
<tr>
<td>6</td>
<td>56.50847</td>
<td>✅</td>
<td>113.01695 ✅</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the example:

- Candidate names are fictitious, just to get names that start with A, B, C, D, E and F as used universally throughout the test suite. The names are whimsical based on the difficult dilemma voters sometimes feel they are choosing between in real candidates.

- In the Single Transferable Vote (STV) method used in this example, each round proceeds by either selecting winners who are above the quota of available votes, or eliminating the last-place candidate(s) and transferring those votes to the next choice on each ballot that had them. When a candidate wins, the fraction of their votes beyond the quota necessary to win also transfer to other candidates.

- The "Result" column shows a numerical place and disposition. The disposition will be one of
  
  - "selected" if the candidate/choice placed high enough to win an available seat
  
  - "tied" if a tie exists between multiple candidates and spans through at least one available seat and more than can be filled. It is the software's role to report this, not to decide what to do. Ties can and do happen. So an organization must have procedures to deal with them.
  
  - "placed" if the candidate placed after the last available seat, and therefore was not selected/elected.
  
  - "eliminated" if the candidate was eliminated from counting. A place number reflects order where the first or strongest elimination is ordered last.
