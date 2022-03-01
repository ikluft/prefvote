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
<td>317/317/0</td>
<td>103/103/0</td>
<td>79/79/0</td>
<td>𝟬</td>
<td>499/499/0</td>
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
<td>1010/1010/0</td>
<td>7146/7146/0</td>
<td>8361/8361/0</td>
<td>0/0/0</td>
<td>16517/16517/0</td>
</tr>
</tbody>
</table>
</blockquote>
