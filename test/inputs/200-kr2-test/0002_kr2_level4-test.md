# Black-box test data overview for [0002_kr2_level4-test.yaml](0002_kr2_level4-test.yaml)

<blockquote>
title: KR2 Test Suite 0002 (100 ballots)
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
<td>EVIL</td>
<td>2.10000 (210/100)</td>
<td>1</td>
<td>1 / 1</td>
<td>1 (7)</td>
</tr>
<tr>
<td>BORING</td>
<td>2.38000 (238/100)</td>
<td>2</td>
<td>2 / 2</td>
<td>1 (7)</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>2.75000 (275/100)</td>
<td>3</td>
<td>3 / 3</td>
<td>3 (3)</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>4.30000 (430/100)</td>
<td>4</td>
<td>4 / 4</td>
<td>5 (0)</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>4.70000 (470/100)</td>
<td>5</td>
<td>6 / 6</td>
<td>8 (-6)</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4.77000 (477/100)</td>
<td>6</td>
<td>5 / 5</td>
<td>7 (-4)</td>
</tr>
</tbody>
</table>

<p><small><i>Voting results shown with/without ACR tie-breaking.</i></small></p>

</blockquote>

## Results for Core method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0002</h2>
<p>2 seats available ● 100 ballots processed</p>
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
<td>EVIL</td>
<td>evil villain</td>
<td>1/selected</td>
</tr>
<tr>
<td>BORING</td>
<td>tedious boring</td>
<td>2/selected</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>3/placed</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>4/placed</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>5/placed</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
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
<td>EVIL</td>
<td>2.1</td>
</tr>
<tr>
<td>BORING</td>
<td>2.38</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>2.75</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>4.3</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>4.7</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4.77</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for KR2 method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0002</h2>
<p>2 seats available ● 100 ballots processed</p>
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
<td>EVIL</td>
<td>evil villain</td>
<td>1/selected</td>
</tr>
<tr>
<td>BORING</td>
<td>tedious boring</td>
<td>2/selected</td>
</tr>
<tr>
<td>_support2</td>
<td>[rating bound _support2]</td>
<td>-</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>3/placed</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>4/placed</td>
</tr>
<tr>
<td>_neutral</td>
<td>[rating bound _neutral]</td>
<td>-</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
<td>5/eliminated</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
<td>6/eliminated</td>
</tr>
<tr>
<td>_oppose2</td>
<td>[rating bound _oppose2]</td>
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
<th>EVIL</th>
<th>BORING</th>
<th>_support2</th>
<th>FACTIOUS</th>
<th>CHAOTIC</th>
<th>_neutral</th>
<th>ABNORMAL</th>
<th>DYSFUNCTIONAL</th>
<th>_oppose2</th>
</tr>
</thead>
<tbody>
<tr>
<td>EVIL</td>
<td>7</td>
<td>🛇</td>
<td>0 🔵</td>
<td>18 ✅</td>
<td>58 ✅</td>
<td>82 ✅</td>
<td>78 ✅</td>
<td>76 ✅</td>
<td>64 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>BORING</td>
<td>7</td>
<td>0 🔵</td>
<td>🛇</td>
<td>22 ✅</td>
<td>18 ✅</td>
<td>50 ✅</td>
<td>76 ✅</td>
<td>64 ✅</td>
<td>92 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>_support2</td>
<td>3</td>
<td>-18 ❌</td>
<td>-22 ❌</td>
<td>🛇</td>
<td>0 🔵</td>
<td>62 ✅</td>
<td>100 ✅</td>
<td>70 ✅</td>
<td>74 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>3</td>
<td>-58 ❌</td>
<td>-18 ❌</td>
<td>0 🔵</td>
<td>🛇</td>
<td>92 ✅</td>
<td>52 ✅</td>
<td>80 ✅</td>
<td>54 ✅</td>
<td>96 ✅</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>0</td>
<td>-82 ❌</td>
<td>-50 ❌</td>
<td>-62 ❌</td>
<td>-92 ❌</td>
<td>🛇</td>
<td>6 ✅</td>
<td>44 ✅</td>
<td>20 ✅</td>
<td>56 ✅</td>
</tr>
<tr>
<td>_neutral</td>
<td>-2</td>
<td>-78 ❌</td>
<td>-76 ❌</td>
<td>-100 ❌</td>
<td>-52 ❌</td>
<td>-6 ❌</td>
<td>🛇</td>
<td>14 ✅</td>
<td>20 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>-4</td>
<td>-76 ❌</td>
<td>-64 ❌</td>
<td>-70 ❌</td>
<td>-80 ❌</td>
<td>-44 ❌</td>
<td>-14 ❌</td>
<td>🛇</td>
<td>10 ✅</td>
<td>48 ✅</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>-6</td>
<td>-64 ❌</td>
<td>-92 ❌</td>
<td>-74 ❌</td>
<td>-54 ❌</td>
<td>-20 ❌</td>
<td>-20 ❌</td>
<td>-10 ❌</td>
<td>🛇</td>
<td>44 ✅</td>
</tr>
<tr>
<td>_oppose2</td>
<td>-8</td>
<td>-100 ❌</td>
<td>-100 ❌</td>
<td>-100 ❌</td>
<td>-96 ❌</td>
<td>-56 ❌</td>
<td>-100 ❌</td>
<td>-48 ❌</td>
<td>-44 ❌</td>
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
<td>EVIL</td>
<td>2.62</td>
</tr>
<tr>
<td>BORING</td>
<td>2.89</td>
</tr>
<tr>
<td>_support2</td>
<td>3.17</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>3.51</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>5.8</td>
</tr>
<tr>
<td>_neutral</td>
<td>5.89</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>6.45</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>6.45</td>
</tr>
<tr>
<td>_oppose2</td>
<td>8.22</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

