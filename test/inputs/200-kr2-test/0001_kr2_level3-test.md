# Black-box test data overview for [0001_kr2_level3-test.yaml](0001_kr2_level3-test.yaml)

<blockquote>
title: KR2 Test Suite 0001 (50 ballots)
<table border=1>
<thead>
<tr>
<th>choice</th>
<th>avg choice rank</th>
<th>Core</th>
<th>KR2</th>
<th>Copeland</th>
</tr>
</thead>
<tbody>
<tr>
<td>BORING</td>
<td>2.06000 (103/50)</td>
<td>1</td>
<td>1 / 1</td>
<td>1 (7)</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>2.94000 (147/50)</td>
<td>2</td>
<td>2 / 2</td>
<td>3 (3)</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>3.20000 (160/50)</td>
<td>3</td>
<td>3 / 3</td>
<td>4 (1)</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4.16000 (208/50)</td>
<td>4</td>
<td>4 / 4</td>
<td>5 (-2)</td>
</tr>
<tr>
<td>EVIL</td>
<td>4.28000 (214/50)</td>
<td>5</td>
<td>5 / 5</td>
<td>5 (-2)</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>4.36000 (218/50)</td>
<td>6</td>
<td>6 / 6</td>
<td>7 (-5)</td>
</tr>
</tbody>
</table>

<p><small><i>Voting results shown with/without ACR tie-breaking.</i></small></p>

</blockquote>

## Results for Core method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0001</h2>
<p>1 seat available ● 50 ballots processed</p>
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
<td>tedious boring</td>
<td>1/selected</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>2/placed</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>3/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
<td>4/placed</td>
</tr>
<tr>
<td>EVIL</td>
<td>evil villain</td>
<td>5/placed</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>6/placed</td>
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
<td>BORING</td>
<td>2.06</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>2.94</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>3.2</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4.16</td>
</tr>
<tr>
<td>EVIL</td>
<td>4.28</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>4.36</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for KR2 method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0001</h2>
<p>1 seat available ● 50 ballots processed</p>
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
<td>tedious boring</td>
<td>1/selected</td>
</tr>
<tr>
<td>_support</td>
<td>[rating bound _support]</td>
<td>-</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>2/placed</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>3/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
<td>4/placed</td>
</tr>
<tr>
<td>EVIL</td>
<td>evil villain</td>
<td>5/placed</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>6/placed</td>
</tr>
<tr>
<td>_oppose</td>
<td>[rating bound _oppose]</td>
<td>-</td>
</tr>
</tbody>
</table>
<h3>Margin-of-victory matrix</h3>
<p>This compares how each choice ranks against others, ordered by Kluft algorithm.</p>
<table border=1>
<thead>
<tr>
<th></th>
<th>wins-loss</th>
<th>BORING</th>
<th>_support</th>
<th>DYSFUNCTIONAL</th>
<th>FACTIOUS</th>
<th>ABNORMAL</th>
<th>EVIL</th>
<th>CHAOTIC</th>
<th>_oppose</th>
</tr>
</thead>
<tbody>
<tr>
<td>BORING</td>
<td>7</td>
<td>🛇</td>
<td>16 ✅</td>
<td>20 ✅</td>
<td>22 ✅</td>
<td>34 ✅</td>
<td>34 ✅</td>
<td>34 ✅</td>
<td>50 ✅</td>
</tr>
<tr>
<td>_support</td>
<td>5</td>
<td>-16 ❌</td>
<td>🛇</td>
<td>12 ✅</td>
<td>18 ✅</td>
<td>30 ✅</td>
<td>36 ✅</td>
<td>32 ✅</td>
<td>50 ✅</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>3</td>
<td>-20 ❌</td>
<td>-12 ❌</td>
<td>🛇</td>
<td>4 ✅</td>
<td>14 ✅</td>
<td>26 ✅</td>
<td>32 ✅</td>
<td>44 ✅</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>1</td>
<td>-22 ❌</td>
<td>-18 ❌</td>
<td>-4 ❌</td>
<td>🛇</td>
<td>24 ✅</td>
<td>20 ✅</td>
<td>12 ✅</td>
<td>38 ✅</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>-2</td>
<td>-34 ❌</td>
<td>-30 ❌</td>
<td>-14 ❌</td>
<td>-24 ❌</td>
<td>🛇</td>
<td>0 🔵</td>
<td>6 ✅</td>
<td>32 ✅</td>
</tr>
<tr>
<td>EVIL</td>
<td>-2</td>
<td>-34 ❌</td>
<td>-36 ❌</td>
<td>-26 ❌</td>
<td>-20 ❌</td>
<td>0 🔵</td>
<td>🛇</td>
<td>2 ✅</td>
<td>20 ✅</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>-5</td>
<td>-34 ❌</td>
<td>-32 ❌</td>
<td>-32 ❌</td>
<td>-12 ❌</td>
<td>-6 ❌</td>
<td>-2 ❌</td>
<td>🛇</td>
<td>18 ✅</td>
</tr>
<tr>
<td>_oppose</td>
<td>-7</td>
<td>-50 ❌</td>
<td>-50 ❌</td>
<td>-44 ❌</td>
<td>-38 ❌</td>
<td>-32 ❌</td>
<td>-20 ❌</td>
<td>-18 ❌</td>
<td>🛇</td>
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
<td>BORING</td>
<td>2.4</td>
</tr>
<tr>
<td>_support</td>
<td>2.88</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>3.62</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>4</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>5.14</td>
</tr>
<tr>
<td>EVIL</td>
<td>5.44</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>5.5</td>
</tr>
<tr>
<td>_oppose</td>
<td>7.02</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

