# Black-box test data overview for [0004_kr2_level5-test.yaml](0004_kr2_level5-test.yaml)

<blockquote>
title: KR2 Test Suite 0004 (100 ballots)
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
<td>CHAOTIC</td>
<td>2.46000 (246/100)</td>
<td>1</td>
<td>1 / 1</td>
<td>2 (7)</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.62000 (262/100)</td>
<td>2</td>
<td>2 / 2</td>
<td>3 (5)</td>
</tr>
<tr>
<td>BORING</td>
<td>3.23000 (323/100)</td>
<td>3</td>
<td>4 / 4</td>
<td>6 (-1)</td>
</tr>
<tr>
<td>EVIL</td>
<td>3.61000 (361/100)</td>
<td>4</td>
<td>3 / 3</td>
<td>5 (1)</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>4.08000 (408/100)</td>
<td>5</td>
<td>5 / 5</td>
<td>7 (-4)</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>5.00000 (500/100)</td>
<td>6</td>
<td>6 / 6</td>
<td>9 (-7)</td>
</tr>
</tbody>
</table>

<p><small><i>Voting results shown with/without ACR tie-breaking.</i></small></p>

</blockquote>

## Results for Core method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0004</h2>
<p>1 seat available ● 100 ballots processed</p>
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
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
<td>2/placed</td>
</tr>
<tr>
<td>BORING</td>
<td>tedious boring</td>
<td>3/placed</td>
</tr>
<tr>
<td>EVIL</td>
<td>evil villain</td>
<td>4/placed</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>5/placed</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>dysfunctional incompetent</td>
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
<td>CHAOTIC</td>
<td>2.46</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>2.62</td>
</tr>
<tr>
<td>BORING</td>
<td>3.23</td>
</tr>
<tr>
<td>EVIL</td>
<td>3.61</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>4.08</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>5</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

## Results for KR2 method
<blockquote>
<div id="prefvote">
<h2>Results: KR2 Test Suite 0004</h2>
<p>1 seat available ● 100 ballots processed</p>
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
<td>_support2</td>
<td>[rating bound _support2]</td>
<td>-</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>chaotic unpredictable</td>
<td>1/selected</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>abnormal antisocial</td>
<td>2/placed</td>
</tr>
<tr>
<td>_support1</td>
<td>[rating bound _support1]</td>
<td>-</td>
</tr>
<tr>
<td>EVIL</td>
<td>evil villain</td>
<td>3/placed</td>
</tr>
<tr>
<td>BORING</td>
<td>tedious boring</td>
<td>4/placed</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>factious divisive</td>
<td>5/placed</td>
</tr>
<tr>
<td>_oppose1</td>
<td>[rating bound _oppose1]</td>
<td>-</td>
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
<th>_support2</th>
<th>CHAOTIC</th>
<th>ABNORMAL</th>
<th>_support1</th>
<th>EVIL</th>
<th>BORING</th>
<th>FACTIOUS</th>
<th>_oppose1</th>
<th>DYSFUNCTIONAL</th>
<th>_oppose2</th>
</tr>
</thead>
<tbody>
<tr>
<td>_support2</td>
<td>9</td>
<td>🛇</td>
<td>20 ✅</td>
<td>32 ✅</td>
<td>100 ✅</td>
<td>54 ✅</td>
<td>46 ✅</td>
<td>74 ✅</td>
<td>100 ✅</td>
<td>84 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>7</td>
<td>-20 ❌</td>
<td>🛇</td>
<td>16 ✅</td>
<td>50 ✅</td>
<td>36 ✅</td>
<td>26 ✅</td>
<td>72 ✅</td>
<td>80 ✅</td>
<td>58 ✅</td>
<td>94 ✅</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>5</td>
<td>-32 ❌</td>
<td>-16 ❌</td>
<td>🛇</td>
<td>18 ✅</td>
<td>56 ✅</td>
<td>28 ✅</td>
<td>24 ✅</td>
<td>52 ✅</td>
<td>84 ✅</td>
<td>82 ✅</td>
</tr>
<tr>
<td>_support1</td>
<td>3</td>
<td>-100 ❌</td>
<td>-50 ❌</td>
<td>-18 ❌</td>
<td>🛇</td>
<td>12 ✅</td>
<td>20 ✅</td>
<td>42 ✅</td>
<td>100 ✅</td>
<td>60 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>EVIL</td>
<td>1</td>
<td>-54 ❌</td>
<td>-36 ❌</td>
<td>-56 ❌</td>
<td>-12 ❌</td>
<td>🛇</td>
<td>2 ✅</td>
<td>18 ✅</td>
<td>38 ✅</td>
<td>50 ✅</td>
<td>64 ✅</td>
</tr>
<tr>
<td>BORING</td>
<td>-1</td>
<td>-46 ❌</td>
<td>-26 ❌</td>
<td>-28 ❌</td>
<td>-20 ❌</td>
<td>-2 ❌</td>
<td>🛇</td>
<td>12 ✅</td>
<td>26 ✅</td>
<td>98 ✅</td>
<td>64 ✅</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>-4</td>
<td>-74 ❌</td>
<td>-72 ❌</td>
<td>-24 ❌</td>
<td>-42 ❌</td>
<td>-18 ❌</td>
<td>-12 ❌</td>
<td>🛇</td>
<td>0 🔵</td>
<td>10 ✅</td>
<td>38 ✅</td>
</tr>
<tr>
<td>_oppose1</td>
<td>-4</td>
<td>-100 ❌</td>
<td>-80 ❌</td>
<td>-52 ❌</td>
<td>-100 ❌</td>
<td>-38 ❌</td>
<td>-26 ❌</td>
<td>0 🔵</td>
<td>🛇</td>
<td>22 ✅</td>
<td>100 ✅</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>-7</td>
<td>-84 ❌</td>
<td>-58 ❌</td>
<td>-84 ❌</td>
<td>-60 ❌</td>
<td>-50 ❌</td>
<td>-98 ❌</td>
<td>-10 ❌</td>
<td>-22 ❌</td>
<td>🛇</td>
<td>18 ✅</td>
</tr>
<tr>
<td>_oppose2</td>
<td>-9</td>
<td>-100 ❌</td>
<td>-94 ❌</td>
<td>-82 ❌</td>
<td>-100 ❌</td>
<td>-64 ❌</td>
<td>-64 ❌</td>
<td>-38 ❌</td>
<td>-100 ❌</td>
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
<td>_support2</td>
<td>2.45</td>
</tr>
<tr>
<td>CHAOTIC</td>
<td>3.44</td>
</tr>
<tr>
<td>ABNORMAL</td>
<td>4.02</td>
</tr>
<tr>
<td>_support1</td>
<td>4.67</td>
</tr>
<tr>
<td>BORING</td>
<td>5.11</td>
</tr>
<tr>
<td>EVIL</td>
<td>5.43</td>
</tr>
<tr>
<td>FACTIOUS</td>
<td>6.47</td>
</tr>
<tr>
<td>_oppose1</td>
<td>6.87</td>
</tr>
<tr>
<td>DYSFUNCTIONAL</td>
<td>7.74</td>
</tr>
<tr>
<td>_oppose2</td>
<td>8.8</td>
</tr>
</tbody>
</table>
</div>

</blockquote>

