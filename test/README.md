# PrefVote test suite

PrefVote is designed for multiple programming language implementations using a common test suite. The test suite consists of "black box" test specs used across all languages, plus "white box" unit tests within each language's source code directory. The test harness collects [Test Anything Protocol (TAP)](https://testanything.org/) data from each language's unit tests to report the results.

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
<td>321/321/0</td>
<td>195/195/0</td>
<td>182/182/0</td>
<td>132/132/0</td>
<td>830/830/0</td>
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
<td>7758/7758/0</td>
<td>8922/8922/0</td>
<td>10279/10279/0</td>
<td>8259/8259/0</td>
<td>35218/35218/0</td>
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
<td>8079/8079/0</td>
<td>9117/9117/0</td>
<td>10461/10461/0</td>
<td>8391/8391/0</td>
<td>36048/36048/0</td>
</tr>
</tbody>
</table>
</blockquote>
