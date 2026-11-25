# Black-box test data overview for [007-rcv-test.yaml](007-rcv-test.yaml)

<blockquote>
title: Test Vote 007 (IIA) (20 ballots)
<table border=1>
<thead>
<tr>
<th>choice</th>
<th>avg choice rank</th>
<th>Core</th>
<th>STV</th>
<th>Schulze</th>
<th>RankedPairs</th>
<th>KR2</th>
<th>Copeland</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.90000 (38/20)</td>
<td>1</td>
<td>2 / 2</td>
<td>2 / 2</td>
<td>1 / 1</td>
<td>1 / 1</td>
<td>1 (0)</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95000 (39/20)</td>
<td>2</td>
<td>1 / 1</td>
<td>1 / 1</td>
<td>2 / 2</td>
<td>2 / 2</td>
<td>1 (0)</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15000 (43/20)</td>
<td>3</td>
<td>3 / 3</td>
<td>3 / 3</td>
<td>3 / 3</td>
<td>3 / 3</td>
<td>1 (0)</td>
</tr>
</tbody>
</table>

<p><small><i>Voting results shown with/without ACR tie-breaking.</i></small></p>

</blockquote>

## Results for Core method
<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 007 (IIA)</h2>
<p>1 seat available ● 20 ballots processed</p>
<table border=1>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>1/selected</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>2/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>3/placed</td>
</tr>
</tbody>
</table>
<h3>Average ballot ranking positions</h3>
<p>Lower numbers are favored. First place = 1.</p>
<table border=1>
<thead>
<tr>
<th>Candidate</th>
<th>average ranking</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.9</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for STV method
<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 007 (IIA)</h2>
<p>1 seat available ● 20 ballots processed</p>
<table border=1>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>1/selected</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>2/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>3/eliminated</td>
</tr>
</tbody>
</table>
<table border=1>
<thead>
<tr>
<th>Round #</th>
<th>Quota</th>
<th>BORING</th>
<th>CHAOTIC</th>
<th>ABNORMAL</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>10</td>
<td>8</td>
<td>7</td>
<td>5 ❌</td>
</tr>
<tr>
<td>2</td>
<td>10</td>
<td>13 ✅</td>
<td>7</td>
<td>❌</td>
</tr>
<tr>
<td>3</td>
<td>5</td>
<td>✅</td>
<td>10 ✅</td>
<td>❌</td>
</tr>
</tbody>
</table>
<h3>Average ballot ranking positions</h3>
<p>Lower numbers are favored. First place = 1. Average rank is used to break ties in the primary voting method.</p>
<table border=1>
<thead>
<tr>
<th>Candidate</th>
<th>average ranking</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.9</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for Schulze method
<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 007 (IIA)</h2>
<p>1 seat available ● 20 ballots processed</p>
<table border=1>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>1/selected</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>2/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>3/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<p>This compares how each choice ranks against others, ordered by Schulze algorithm.</p>
<table border=1>
<thead>
<tr>
<th></th>
<th>BORING</th>
<th>CHAOTIC</th>
<th>ABNORMAL</th>
</tr>
</thead>
<tbody>
<tr>
<td>BORING</td>
<td>⊘</td>
<td>6 ✅</td>
<td>-4 ❌</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>-6 ❌</td>
<td>⊘</td>
<td>10 ✅</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4 ✅</td>
<td>-10 ❌</td>
<td>⊘</td>
</tr>
</tbody>
</table>
<h3>Average ballot ranking positions</h3>
<p>Lower numbers are favored. First place = 1. Average rank is used to break ties in the primary voting method.</p>
<table border=1>
<thead>
<tr>
<th>Candidate</th>
<th>average ranking</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.9</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for RankedPairs method
<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 007 (IIA)</h2>
<p>1 seat available ● 20 ballots processed</p>
<table border=1>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>1/selected</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>2/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>3/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<p>This compares how each choice ranks against others, ordered by Ranked Pairs algorithm.</p>
<table border=1>
<thead>
<tr>
<th></th>
<th>CHAOTIC</th>
<th>BORING</th>
<th>ABNORMAL</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>⊘</td>
<td>-6 ❌</td>
<td>10 ✅🔒</td>
</tr>
<tr>
<td>BORING</td>
<td>6 ✅🔒</td>
<td>⊘</td>
<td>-4 ❌</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>-10 ❌</td>
<td>4 ✅</td>
<td>⊘</td>
</tr>
</tbody>
</table>
<h3>Average ballot ranking positions</h3>
<p>Lower numbers are favored. First place = 1. Average rank is used to break ties in the primary voting method.</p>
<table border=1>
<thead>
<tr>
<th>Candidate</th>
<th>average ranking</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.9</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for KR2 method
<blockquote>
<div id="prefvote">
<h2>Results: Test Vote 007 (IIA)</h2>
<p>1 seat available ● 20 ballots processed</p>
<table border=1>
<thead>
<tr>
<th>Abbreviation</th>
<th>Name/description</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>1/selected</td>
</tr>
<tr>
<td>BORING</td>
<td>boring as anything</td>
<td>2/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal and antisocial</td>
<td>3/placed</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<p>This compares how each choice ranks against others. The KR2 (Kluft Rank-Rate) algorithm orders results by pairwise wins minus losses, with tie-breaking by average ballot ranking.</p>
<table border=1>
<thead>
<tr>
<th></th>
<th>wins-loss</th>
<th>CHAOTIC</th>
<th>BORING</th>
<th>ABNORMAL</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>0</td>
<td>⊘</td>
<td>-6 ❌</td>
<td>10 ✅</td>
</tr>
<tr>
<td>BORING</td>
<td>0</td>
<td>6 ✅</td>
<td>⊘</td>
<td>-4 ❌</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>0</td>
<td>-10 ❌</td>
<td>4 ✅</td>
<td>⊘</td>
</tr>
</tbody>
</table>
<h3>Average ballot ranking positions</h3>
<p>Lower numbers are favored. First place = 1. Average rank is used to break ties in the primary voting method.</p>
<table border=1>
<thead>
<tr>
<th>Candidate</th>
<th>average ranking</th>
</tr>
</thead>
<tbody>
<tr>
<td>CHAOTIC</td>
<td>1.9</td>
</tr>
<tr>
<td>BORING</td>
<td>1.95</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.15</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

