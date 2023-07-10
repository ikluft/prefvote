# PrefVote

PrefVote is a project to promote preference voting. It supports several ranked-choice voting methods and algorithms. It was originally derived from the Vote::STV software written by Ian Kluft in Perl in 1999, with periodic maintenance over the years.

Since the project's original language Perl has strengths in prototyping, that's the reference implementation in this project for multiple language implementations. With translations to multiple programming languages, the library is designed with a [common test suite](test/) among the different implementations to verify proper functioning.

## About preference voting algorithms

The original Vote::STV software implemented the [single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote) algorithm, which is a subset of [ranked-choice voting](https://en.wikipedia.org/wiki/Ranked_voting), also called preference voting. PrefVote has expanded into a library of multiple voting method implementations all based on ranked choice.

STV was the first implemented voting method in PrefVote since it was the original implementation as Vote::STV back to 1998. But STV has largely fallen out of favor because studies of voting methods found it lacking on some desirable characteristics. STV was retained while modernizing the code to develop testing infrastructure.

No voting method can be perfect, due to a long list of desirable properties, some of which [turn out to be in conflict](https://electowiki.org/wiki/Arrow%27s_impossibility_theorem). Given that there is no perfect voting method, it's important to have agreement among a community on which method it uses. Methods which meet [Condorcet requirements](https://electowiki.org/wiki/Condorcet_method) make comparisons between each pair of candidates and, if one exists, always pick a winner who beats all other candidates in pairwise comparisons. Condorcet methods differ in how to handle cases where there isn't a clear Condorcet winner.

The second voting method implemented in PrefVote was the [Schulze algorithm](https://en.wikipedia.org/wiki/Schulze_method) (see [full definition paper)](https://arxiv.org/abs/1804.02973). The method was designed by Marcus Schulze in 1997 to compute a graph out of voter preferences among candidates and pick the ones preferred over all others. An ordering of all the candidates can be computed over multiple rounds after removing the previous round's winner(s).

Next was [Ranked Pairs](https://en.wikipedia.org/wiki/Ranked_pairs). It was designed by Nicolaus Tideman in 1987. It tallies ranked choice ballots into pairwise comparisons among all choices/candidates. The pairs are sorted by margin of victory from largest margin down to ties at zero. Pairs are "locked" in for consideration of the final order of candidates if they do not conflict with locked pairs with larger margins. Candidates are then ordered starting who beats all other candidates, then each who beat all remaining candidates.

After the reference implementation in Perl, next up for language implementations will be [Rust](https://www.rust-lang.org/).

## Input file format

PrefVote provides code to read YAML input files. There is [documentation for the data format](doc/PrefVote_YAML_input.md). Also, as a library any data can be submitted directly.

## Tie-breaking modifications to algorithms

PrefVote modifies all the algorithms in one way. It adds a tie-breaking factor using the average ballot-position ranking of a choice/candidate. It started as experimentation with intuition that the average ranking of a choice was indicative of the will of the voters. Though it wouldn't be acceptable as a primary factor because averages don't have quantitative data. Test runs show that it approximates Condorcet results fairly well and converges with Condorcet by around 100 random ballots. It didn't even need to be that close to Condorcet to convey meaning about voter's preferences. So this tie-breaking method restores ballot-position ordering information which Condorcet lacks.

PrefVote's Core module from which all the voting methods inherit common code is not a voting method itself. But in performing the counting of average choice ranking (ACR) for other methods to use for tie-breaking, it contains results which can be displayed for testing purposes. Since it only uses average ranking, it really must not be used for actual voting. There is a principle in voting that every vote counts. That means quantitative factors must be the primary ordering for results. But ACR turns out to be surprisingly well-suited to be a second sorting factor for tie-breaking.

## Example voting result from test suite

This is an example result from Single Transferable Vote (STV), Schulze and Ranked Pairs using the same [file in the test suite](test/inputs/100-rcv-test/004-rcv-test.yaml) with each algorithm. 250 ballots were randomly generated. So there's no actual meaning to the result except testing the software.

Notes about all the following examples:

- Candidate names are fictitious, just to get names that start with A, B, C, D, E and F as used universally throughout the test suite. The names are whimsical based on the difficult dilemma voters sometimes feel they are choosing between in real candidates.

- Even for a relatively small set of test data, this shows the importance of algorithm definition to handling of ranked-choice votes. The various algorithms can lead to different results which are valid by the definition of how each method does its counting. Following the procedures of each method, they can vary in behavior when vote counts are close. Typically they won't vary when results are not close. This example was one where a close race came out differently.

### Single Transferable Vote (STV) results from the example data

<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 004</h2>
<p>1 seat available &VerticalBar; 250 ballots</p>
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
<td>factious/divisive</td>
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

Notes about the STV example:

- In the Single Transferable Vote (STV) method used in this example, each round proceeds by either selecting winners who are above the quota of available votes, or eliminating the last-place candidate(s) and transferring those votes to the next choice on each ballot that had them. When a candidate wins, the fraction of their votes beyond the quota necessary to win also transfer to other candidates.

- The "Result" column shows a numerical place and disposition. The disposition will be one of
  
  - "selected" if the candidate/choice placed high enough to win an available seat
  
  - "tied" if a tie exists between multiple candidates and spans through at least one available seat and more than can be filled. It is the software's role to report this, not to decide what to do. Ties can and do happen. So an organization must have procedures to deal with them.
  
  - "placed" if the candidate placed after the last available seat, and therefore was not selected/elected.
  
  - "eliminated" if the candidate was eliminated from counting. A place number reflects order where the first or strongest elimination is ordered last.

### Schulze method results from the example data

<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 004</h2>
<p>1 seat available &VerticalBar; 250 ballots</p>
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
<td>factious/divisive</td>
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
<td>3/placed</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>4/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>5/placed</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>6/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<table>
<thead>
<tr>
<th></th>
<th>FACTIOUS</th>
<th>EVIL</th>
<th>CHAOTIC</th>
<th>DYSFUNCTIONAL</th>
<th>ABNORMAL</th>
<th>BORING</th>
</tr>
</thead>
<tbody>
<tr>
<td>FACTIOUS</td>
<td>🛇</td>
<td>7 ✅</td>
<td>57 ✅</td>
<td>67 ✅</td>
<td>74 ✅</td>
<td>79 ✅</td>
</tr>
<tr>
<td>EVIL</td>
<td>-7 ❌</td>
<td>🛇</td>
<td>48 ✅</td>
<td>68 ✅</td>
<td>68 ✅</td>
<td>64 ✅</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>-57 ❌</td>
<td>-48 ❌</td>
<td>🛇</td>
<td>16 ✅</td>
<td>5 ✅</td>
<td>15 ✅</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>-67 ❌</td>
<td>-68 ❌</td>
<td>-16 ❌</td>
<td>🛇</td>
<td>13 ✅</td>
<td>5 ✅</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>-74 ❌</td>
<td>-68 ❌</td>
<td>-5 ❌</td>
<td>-13 ❌</td>
<td>🛇</td>
<td>11 ✅</td>
</tr>
<tr>
<td>BORING</td>
<td>-79 ❌</td>
<td>-64 ❌</td>
<td>-15 ❌</td>
<td>-5 ❌</td>
<td>-11 ❌</td>
<td>🛇</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the Schulze example:

- The Schulze method is a Condorcet voting method. So it aggregates the ranked preferences from each ballot into pairwise preference of each of the candidates. In all Condorcet methods, if one candidate is preferred over all others then it is considered the Condorcet winner. The Schulze method also considers paths of preferences in a graph to pick between candidates when there isn't a single Condorcet winner.

- As with the STV results, the first table in the example is the final ranking order of the voting results. It indicates selected, tied, and placed candidates as above. There is no concept of eliminated candidates in the Schulze method. After the winner is found in each round, the vote is re-run for as many rounds as needed until all the candidates are ordered in the result.

- The margin-of-victory matrix shows the voting results with how much each candidate on the row labels are preferred over candidates on the column labels. Negative numbers mean the other candidate is more preferred. There is a "not applicable" icon in each cell diagonally down the middle where each candidate cannot be compared to themselves. The matrix always has an inverse symmetry because the same pair of candidates compared on the other side of the diagonal will be opposite - with A-B vs B-A, one of them must negative and opposite of the other. A Condorcet winner is easily visible as having all positive numbers (and check-mark icons) compared against all other candidates.

### Ranked Pairs voting results from the example data

<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 004</h2>
<p>1 seat available &VerticalBar; 250 ballots</p>
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
<td>factious/divisive</td>
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
<td>3/placed</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>4/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>5/placed</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>6/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<table>
<thead>
<tr>
<th></th>
<th>FACTIOUS</th>
<th>EVIL</th>
<th>CHAOTIC</th>
<th>DYSFUNCTIONAL</th>
<th>ABNORMAL</th>
<th>BORING</th>
</tr>
</thead>
<tbody>
<tr>
<td>FACTIOUS</td>
<td>🛇</td>
<td>7 ✅🔒</td>
<td>57 ✅🔒</td>
<td>67 ✅🔒</td>
<td>74 ✅🔒</td>
<td>79 ✅🔒</td>
</tr>
<tr>
<td>EVIL</td>
<td>-7 ❌</td>
<td>🛇</td>
<td>48 ✅🔒</td>
<td>68 ✅🔒</td>
<td>68 ✅🔒</td>
<td>64 ✅🔒</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>-57 ❌</td>
<td>-48 ❌</td>
<td>🛇</td>
<td>16 ✅🔒</td>
<td>5 ✅🔒</td>
<td>15 ✅🔒</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>-67 ❌</td>
<td>-68 ❌</td>
<td>-16 ❌</td>
<td>🛇</td>
<td>13 ✅🔒</td>
<td>5 ✅🔒</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>-74 ❌</td>
<td>-68 ❌</td>
<td>-5 ❌</td>
<td>-13 ❌</td>
<td>🛇</td>
<td>11 ✅🔒</td>
</tr>
<tr>
<td>BORING</td>
<td>-79 ❌</td>
<td>-64 ❌</td>
<td>-15 ❌</td>
<td>-5 ❌</td>
<td>-11 ❌</td>
<td>🛇</td>
</tr>
</tbody>
</table>
</div>
</blockquote>

Notes about the Ranked Pairs example:

- Ranked Pairs is also a Condorcet method, like Schulze. So there are fewer differences between them. And in this example there are no differences at all. Though other files in the test suite do have some modest differences between them when breaking ties.

- The lock icon (🔒) in the results indicate candidate majority pairings which were "locked" and accepted for use in the result order because they did not conflict with pairs with larger margins of victory. Table entries without a lock icon would be because they were a loss or tie, or a conflict with larger majorities. For example if A>B and B>C then C>A is not locked due to a conflict.

- I modified the Ranked Pairs implementation in the case of tie-breaking. Rather than select a random ballot to count a second time as Tideman recommended in his 1987 paper, I used average ballot-position ranking as a second priority sorting field. This was then retrofitted as a tie-breaker in STV and Schulze and adopted as a design feature of PrefVote::Core.
