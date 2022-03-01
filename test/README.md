# PrefVote test suite

PrefVote is designed for multiple programming language implementations using a common test suite. The test suite consists of "black box" test specs used across all languages, plus "white box" unit tests within each language's source code directory. The test harness collects Test Anywhere Protocol (TAP) data from each language's unit tests to report the results.

## Progress on the test suite

Numbers in each cell are test cases planned/passed/failed.

<blockquote>
<table>
<thead>
<tr>
<th>language/set</th>
<th>Core</th>
<th>STV</th>
<th>Schulze</th>
<th>RankedPairs</th>
<th>total</th>
</tr>
</thead>
<tbody>
<tr>
<td>Perl whitebox</td>
<td>319/319/0</td>
<td>195/195/0</td>
<td>182/182/0</td>
<td>𝟬</td>
<td>696/696/0</td>
</tr>
<tr>
<td>Rust whitebox</td>
<td>𝟬</td>
<td>𝟬</td>
<td>𝟬</td>
<td>𝟬</td>
<td>0/0/0</td>
</tr>
<tr>
<td>Perl blackbox</td>
<td>693/693/0</td>
<td>7043/7043/0</td>
<td>8282/8282/0</td>
<td>𝟬</td>
<td>16018/16018/0</td>
</tr>
<tr>
<td>Rust blackbox</td>
<td>𝟬</td>
<td>𝟬</td>
<td>𝟬</td>
<td>𝟬</td>
<td>0/0/0</td>
</tr>
<tr>
<td>total</td>
<td>1012/1012/0</td>
<td>7238/7238/0</td>
<td>8464/8464/0</td>
<td>0/0/0</td>
<td>16714/16714/0</td>
</tr>
</tbody>
</table>
</blockquote>
