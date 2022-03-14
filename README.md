# PrefVote

PrefVote is a project to promote preference voting methods and algorithms. It is derived from the Vote::STV software written by Ian Kluft in Perl originally in 1999.

Since the project's original language Perl has strengths in prototyping, it's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is designed with a [common test suite](test/) among the different implementations to verify proper functioning.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting), also called preference voting. PrefVote has expanded into a library of multiple voting method implementations all based on ranked choice.

STV was the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. But STV has largely fallen out of favor because studies of voting methods found it lacking on some desirable characteristics. STV was retained while modernizing the code to develop testing infrastructure.

No voting method can be perfect, due to a long list of desirable properties, some of which [turn out to be in conflict](https://electowiki.org/wiki/Arrow%27s_impossibility_theorem). Given that there is no perfect voting method, it's important to have agreement among a community on which method it uses. Methods which meet [Condorcet requirements](https://electowiki.org/wiki/Condorcet_method) make comparisons between each pair of candidates and, if one exists, always pick a winner who beats all other candidates in pairwise comparisons. Condorcet methods differ in how to handle cases where there isn't a clear Condorcet winner.

The second voting method implemented in PrefVote was the [Schulze algorithm](https://en.wikipedia.org/wiki/Schulze_method) (see [full definition paper)](https://arxiv.org/abs/1804.02973). The method was designed by Marcus Schulze in 1997 to compute a graph out of voter preferences among candidates and pick the ones preferred over all others. An ordering of all the candidates can be computed over multiple rounds after removing the previous round's winner(s).

Next was [Ranked Pairs](https://en.wikipedia.org/wiki/Ranked_pairs). It was designed by Nicolaus Tideman in 1987. It tallies ranked choice ballots into pairwise comparisons among all choices/candidates. The pairs are sorted by margin of victory from largest margin down to ties at zero. Pairs are "locked" in for consideration of the final order of candidates if they do not conflict with locked pairs with larger margins. Candidates are then ordered starting who beats all other candidates, then each who beat all remaining candidates.

After the reference implementation in Perl, next up for language implementations will be [Rust](https://www.rust-lang.org/).

## Example voting result from test suite

This is an example result from Single Transferable Vote (STV) and Schulze using the same [file in the test suite](test/inputs/100-rcv-test/004-rcv-test.yaml) with each algorithm. 250 ballots were randomly generated. So there's no actual meaning to the result except testing the software.

Notes about all the following examples:

- Candidate names are fictitious, just to get names that start with A, B, C, D, E and F as used universally throughout the test suite. The names are whimsical based on the difficult dilemma voters sometimes feel they are choosing between in real candidates.

- Even for a relatively small set of test data, this shows the importance of algorithm definition to handling of ranked-choice votes. The various algorithms can lead to different results following procedures that can vary in behavior when vote counts are close. This example was one where a close race came out differently.

## Single Transferable Vote (STV) results from the example data

<blockquote>
<div id="prefvote">
<h2>Results:&nbsp;Test&nbsp;Vote&nbsp;004</h2>
<p>1 seat available</p>
<table>
<thead>
<tr>
<th style="white-space: nowrap;">Abbreviation</th>
<th style="white-space: nowrap;">Name/description</th>
<th style="white-space: nowrap;">Result</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">FACTIOUS</td>
<td style="white-space: nowrap;">factious/divisive</td>
<td style="white-space: nowrap;">1/selected</td>
</tr>
<tr>
<td style="white-space: nowrap;">EVIL</td>
<td style="white-space: nowrap;">evil&nbsp;villain</td>
<td style="white-space: nowrap;">2/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">CHAOTIC</td>
<td style="white-space: nowrap;">chaotic&nbsp;unpredictable</td>
<td style="white-space: nowrap;">3/eliminated</td>
</tr>
<tr>
<td style="white-space: nowrap;">ABNORMAL</td>
<td style="white-space: nowrap;">abnormal&nbsp;and&nbsp;antisocial</td>
<td style="white-space: nowrap;">4/eliminated</td>
</tr>
<tr>
<td style="white-space: nowrap;">BORING</td>
<td style="white-space: nowrap;">boring&nbsp;as&nbsp;anything</td>
<td style="white-space: nowrap;">5/eliminated</td>
</tr>
<tr>
<td style="white-space: nowrap;">DYSFUNCTIONAL</td>
<td style="white-space: nowrap;">dysfunctional&nbsp;incompetent</td>
<td style="white-space: nowrap;">6/eliminated</td>
</tr>
</tbody>
</table>
<table>
<thead>
<tr>
<th style="white-space: nowrap;">Round&nbsp;#</th>
<th style="white-space: nowrap;">Quota</th>
<th style="white-space: nowrap;">FACTIOUS</th>
<th style="white-space: nowrap;">EVIL</th>
<th style="white-space: nowrap;">CHAOTIC</th>
<th style="white-space: nowrap;">ABNORMAL</th>
<th style="white-space: nowrap;">BORING</th>
<th style="white-space: nowrap;">DYSFUNCTIONAL</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">1</td>
<td style="white-space: nowrap;">125</td>
<td style="white-space: nowrap;">68</td>
<td style="white-space: nowrap;">54</td>
<td style="white-space: nowrap;">36</td>
<td style="white-space: nowrap;">31</td>
<td style="white-space: nowrap;">33</td>
<td style="white-space: nowrap;">28&nbsp;❌</td>
</tr>
<tr>
<td style="white-space: nowrap;">2</td>
<td style="white-space: nowrap;">124.5</td>
<td style="white-space: nowrap;">75</td>
<td style="white-space: nowrap;">58</td>
<td style="white-space: nowrap;">45</td>
<td style="white-space: nowrap;">36</td>
<td style="white-space: nowrap;">35&nbsp;❌</td>
<td style="white-space: nowrap;">❌</td>
</tr>
<tr>
<td style="white-space: nowrap;">3</td>
<td style="white-space: nowrap;">122</td>
<td style="white-space: nowrap;">78</td>
<td style="white-space: nowrap;">69</td>
<td style="white-space: nowrap;">51</td>
<td style="white-space: nowrap;">46&nbsp;❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
</tr>
<tr>
<td style="white-space: nowrap;">4</td>
<td style="white-space: nowrap;">118.5</td>
<td style="white-space: nowrap;">90</td>
<td style="white-space: nowrap;">81</td>
<td style="white-space: nowrap;">66&nbsp;❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
</tr>
<tr>
<td style="white-space: nowrap;">5</td>
<td style="white-space: nowrap;">114</td>
<td style="white-space: nowrap;">118&nbsp;✅</td>
<td style="white-space: nowrap;">110</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
</tr>
<tr>
<td style="white-space: nowrap;">6</td>
<td style="white-space: nowrap;">56.50847</td>
<td style="white-space: nowrap;">✅</td>
<td style="white-space: nowrap;">113.01695&nbsp;✅</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
<td style="white-space: nowrap;">❌</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the STV example:

- In the Single Transferable Vote (STV) method used in this example, each round proceeds by either selecting winners who are above the quota of available votes, or eliminating the last-place candidate(s) and transferring those votes to the next choice on each ballot that had them. When a candidate wins, the fraction of their votes beyond the quota necessary to win also transfer to other candidates.

- The "Result" column shows a numerical place and disposition. The disposition will be one of
  
  - "selected" if the candidate/choice placed high enough to win an available seat
  
  - "tied" if a tie exists between multiple candidates and spans through at least one available seat and more than can be filled. It is the software's role to report this, not to decide what to do. Ties can and do happen. So an organization must have procedures to deal with them.
  
  - "placed" if the candidate placed after the last available seat, and therefore was not selected/elected.
  
  - "eliminated" if the candidate was eliminated from counting. A place number reflects order where the first or strongest elimination is ordered last.

## Schulze method results from the example data

<blockquote>
<div id="prefvote">
<h2>Results:&nbsp;Test&nbsp;Vote&nbsp;004</h2>
<p>1 seat available</p>
<table>
<thead>
<tr>
<th style="white-space: nowrap;">Abbreviation</th>
<th style="white-space: nowrap;">Name/description</th>
<th style="white-space: nowrap;">Result</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">FACTIOUS</td>
<td style="white-space: nowrap;">factious/divisive</td>
<td style="white-space: nowrap;">1/selected</td>
</tr>
<tr>
<td style="white-space: nowrap;">EVIL</td>
<td style="white-space: nowrap;">evil&nbsp;villain</td>
<td style="white-space: nowrap;">2/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">CHAOTIC</td>
<td style="white-space: nowrap;">chaotic&nbsp;unpredictable</td>
<td style="white-space: nowrap;">3/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">DYSFUNCTIONAL</td>
<td style="white-space: nowrap;">dysfunctional&nbsp;incompetent</td>
<td style="white-space: nowrap;">4/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">ABNORMAL</td>
<td style="white-space: nowrap;">abnormal&nbsp;and&nbsp;antisocial</td>
<td style="white-space: nowrap;">5/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">BORING</td>
<td style="white-space: nowrap;">boring&nbsp;as&nbsp;anything</td>
<td style="white-space: nowrap;">6/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<table>
<thead>
<tr>
<th style="white-space: nowrap;"></th>
<th style="white-space: nowrap;">FACTIOUS</th>
<th style="white-space: nowrap;">EVIL</th>
<th style="white-space: nowrap;">CHAOTIC</th>
<th style="white-space: nowrap;">DYSFUNCTIONAL</th>
<th style="white-space: nowrap;">ABNORMAL</th>
<th style="white-space: nowrap;">BORING</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">FACTIOUS</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">7&nbsp;✅</td>
<td style="white-space: nowrap;">57&nbsp;✅</td>
<td style="white-space: nowrap;">67&nbsp;✅</td>
<td style="white-space: nowrap;">74&nbsp;✅</td>
<td style="white-space: nowrap;">79&nbsp;✅</td>
</tr>
<tr>
<td style="white-space: nowrap;">EVIL</td>
<td style="white-space: nowrap;">-7&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">48&nbsp;✅</td>
<td style="white-space: nowrap;">68&nbsp;✅</td>
<td style="white-space: nowrap;">68&nbsp;✅</td>
<td style="white-space: nowrap;">64&nbsp;✅</td>
</tr>
<tr>
<td style="white-space: nowrap;">CHAOTIC</td>
<td style="white-space: nowrap;">-57&nbsp;❌</td>
<td style="white-space: nowrap;">-48&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">16&nbsp;✅</td>
<td style="white-space: nowrap;">5&nbsp;✅</td>
<td style="white-space: nowrap;">15&nbsp;✅</td>
</tr>
<tr>
<td style="white-space: nowrap;">DYSFUNCTIONAL</td>
<td style="white-space: nowrap;">-67&nbsp;❌</td>
<td style="white-space: nowrap;">-68&nbsp;❌</td>
<td style="white-space: nowrap;">-16&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">13&nbsp;✅</td>
<td style="white-space: nowrap;">5&nbsp;✅</td>
</tr>
<tr>
<td style="white-space: nowrap;">ABNORMAL</td>
<td style="white-space: nowrap;">-74&nbsp;❌</td>
<td style="white-space: nowrap;">-68&nbsp;❌</td>
<td style="white-space: nowrap;">-5&nbsp;❌</td>
<td style="white-space: nowrap;">-13&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">11&nbsp;✅</td>
</tr>
<tr>
<td style="white-space: nowrap;">BORING</td>
<td style="white-space: nowrap;">-79&nbsp;❌</td>
<td style="white-space: nowrap;">-64&nbsp;❌</td>
<td style="white-space: nowrap;">-15&nbsp;❌</td>
<td style="white-space: nowrap;">-5&nbsp;❌</td>
<td style="white-space: nowrap;">-11&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the Schulze example:

- The Schulze method is a Condorcet voting method. So it aggregates the ranked preferences from each ballot into total occurrences of preference of each pair of candidates. In all Condorcet methods, if one candidate is preferred over all others then it is the winner. The Schulze method also considers paths of preferences in a graph to pick between candidates when there isn't a single Condorcet winner.

- As with the STV results, the first table in the example is the final ranking order of the voting results. It indicates selected, tied, and placed candidates as above. There is no concept of eliminated candidates in the Schulze method. After the winner is found in each round, the vote is re-run for as many rounds as needed until all the candidates are ordered in the result.

- The margin-of-victory matrix shows the voting results with how much each candidate on the row labels are preferred over candidates on the column labels. Negative numbers mean the other candidate is more preferred. There is a "not applicable" icon in each cell diagonally down the middle where each candidate cannot be compared to themselves. The matrix always has an inverse symmetry because the same pair of candidates compared on the other side of the diagonal will be opposite - with A-B vs B-A, one of them must negative and opposite of the other. A Condorcet winner is easily visible as having all positive numbers (and check-mark icons) compared against all other candidates.

## Ranked Pairs voting results from the example data

<blockquote>
<div id="prefvote">
<h2>Results:&nbsp;Test&nbsp;Vote&nbsp;004</h2>
<p>1 seat available</p>
<table>
<thead>
<tr>
<th style="white-space: nowrap;">Abbreviation</th>
<th style="white-space: nowrap;">Name/description</th>
<th style="white-space: nowrap;">Result</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">FACTIOUS</td>
<td style="white-space: nowrap;">factious/divisive</td>
<td style="white-space: nowrap;">1/selected</td>
</tr>
<tr>
<td style="white-space: nowrap;">EVIL</td>
<td style="white-space: nowrap;">evil&nbsp;villain</td>
<td style="white-space: nowrap;">2/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">CHAOTIC</td>
<td style="white-space: nowrap;">chaotic&nbsp;unpredictable</td>
<td style="white-space: nowrap;">3/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">DYSFUNCTIONAL</td>
<td style="white-space: nowrap;">dysfunctional&nbsp;incompetent</td>
<td style="white-space: nowrap;">4/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">ABNORMAL</td>
<td style="white-space: nowrap;">abnormal&nbsp;and&nbsp;antisocial</td>
<td style="white-space: nowrap;">5/placed</td>
</tr>
<tr>
<td style="white-space: nowrap;">BORING</td>
<td style="white-space: nowrap;">boring&nbsp;as&nbsp;anything</td>
<td style="white-space: nowrap;">6/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<table>
<thead>
<tr>
<th style="white-space: nowrap;"></th>
<th style="white-space: nowrap;">FACTIOUS</th>
<th style="white-space: nowrap;">EVIL</th>
<th style="white-space: nowrap;">CHAOTIC</th>
<th style="white-space: nowrap;">DYSFUNCTIONAL</th>
<th style="white-space: nowrap;">ABNORMAL</th>
<th style="white-space: nowrap;">BORING</th>
</tr>
</thead>
<tbody>
<tr>
<td style="white-space: nowrap;">FACTIOUS</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">7&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">57&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">67&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">74&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">79&nbsp;✅&nbsp;🔒</td>
</tr>
<tr>
<td style="white-space: nowrap;">EVIL</td>
<td style="white-space: nowrap;">-7&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">48&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">68&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">68&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">64&nbsp;✅&nbsp;🔒</td>
</tr>
<tr>
<td style="white-space: nowrap;">CHAOTIC</td>
<td style="white-space: nowrap;">-57&nbsp;❌</td>
<td style="white-space: nowrap;">-48&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">16&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">5&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">15&nbsp;✅&nbsp;🔒</td>
</tr>
<tr>
<td style="white-space: nowrap;">DYSFUNCTIONAL</td>
<td style="white-space: nowrap;">-67&nbsp;❌</td>
<td style="white-space: nowrap;">-68&nbsp;❌</td>
<td style="white-space: nowrap;">-16&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">13&nbsp;✅&nbsp;🔒</td>
<td style="white-space: nowrap;">5&nbsp;✅&nbsp;🔒</td>
</tr>
<tr>
<td style="white-space: nowrap;">ABNORMAL</td>
<td style="white-space: nowrap;">-74&nbsp;❌</td>
<td style="white-space: nowrap;">-68&nbsp;❌</td>
<td style="white-space: nowrap;">-5&nbsp;❌</td>
<td style="white-space: nowrap;">-13&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
<td style="white-space: nowrap;">11&nbsp;✅&nbsp;🔒</td>
</tr>
<tr>
<td style="white-space: nowrap;">BORING</td>
<td style="white-space: nowrap;">-79&nbsp;❌</td>
<td style="white-space: nowrap;">-64&nbsp;❌</td>
<td style="white-space: nowrap;">-15&nbsp;❌</td>
<td style="white-space: nowrap;">-5&nbsp;❌</td>
<td style="white-space: nowrap;">-11&nbsp;❌</td>
<td style="white-space: nowrap;">🛇</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the Ranked Pairs example:

- Ranked Pairs is also a Condorcet method, like Schulze. So there are fewer differences between them. And in this example there are no differences at all. Though other files in the test suite do have some modest differences when breaking ties.

- The lock icon (🔒) in the results indicate candidate majority pairings which were "locked" and accepted for use in the result order because they did not conflict with pairs with larger margins of victory. Table entries without a lock icon would be because they were a loss or tie, or a conflict with larger majorities. For example if A>B and B>C then C>A is not locked due to a conflict.

- I added a hack to the Ranked Pairs implementation on the tie-breaking. Rather than select a random ballot to count a second time as Tideman recommended in his 1987 paper, I used the total of each candidate's margins of victory compared to all other candidates as a second priority sorting field. I'll look into back-porting that to Schulze as well.
