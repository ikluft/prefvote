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
<td>319/319/0</td>
<td>195/195/0</td>
<td>182/182/0</td>
<td>132/132/0</td>
<td>828/828/0</td>
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
<td>6433/6433/0</td>
<td>7401/7401/0</td>
<td>8528/8528/0</td>
<td>6851/6851/0</td>
<td>29213/29213/0</td>
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
<td>6752/6752/0</td>
<td>7596/7596/0</td>
<td>8710/8710/0</td>
<td>6983/6983/0</td>
<td>30041/30041/0</td>
</tr>
</tbody>
</table>
</blockquote>
