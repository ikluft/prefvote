# PrefVote YAML Input File Specification

PrefVote's primary vote input file format uses YAML.
The file is separated by two or more YAML "documents", or separate file sections.
Each document in the YAML file is separated by a "---" line.
If there are more than two, then additional document sections are for testing purposes.

The first document in the file defines the vote including the voting method/algorithm.

The second document contains a list of ballots.
These should have been assembled into the YAML file from wherever the votes were submitted and assembled.

## Vote definition section
The first YAML document/section contains a definition of the vote - the voting algorithm, what the topic is, how many seats are up for election, what the choices are (with an abbreviation string and description for each).

At the top level are two items. Both are required.

* "method" names the voting algorithm, which may be Core, STV, Schulze or RankedPairs. Note that Core is for testing purposes only, and must never be used for processing actual people's votes because it only contains the average choice rank (ACR) which is only an average, not a quantitative measure. It is code which serves as a tie-breaker for all the other voting methods. But all voting must follow the principle that the candidate with the most votes wins.
Example: "method: RankedPairs"
* "params" contains a YAML structure which will be passed to the voting algorithm

The params structure contains the following items.

* "name" is the title of the vote topic as it should be displayed on results. It should be the same title as was displayed on ballots when votes were collected. This is a required parameter.
* "seats" is the number of seats up for election. The default number is 1. A future planned feature is to allow zero seats to mean the overall ranking order is the desired result. The use case for zero seats is for ranking polls. Until then, set the number of seats to the number of available choices to achieve a similar result.
* "choices" is a hash/map structure defining the choices or candidates. The map key is a short/abbreviated string for the choice. The map value is the full display name of the choice. This is a required parameter.

An example from a test vote shows a vote called "Test Vote" with 1 available seat and 6 choices, which for testing purposes start with the letters A through F.

<pre>
  ---
  method: RankedPairs
  params:
    name: Test Vote
    seats: 1
    choices:
      ABNORMAL: abnormal and antisocial
      BORING: boring as anything
      CHAOTIC: chaotic unpredictable
      DYSFUNCTIONAL: dysfunctional incompetent
      EVIL: evil villain
      FACTIOUS: factious/divisive
  ---
  [...second YAML document section contains ballots...]
</pre>

## Ballot section

The second YAML document contains a list of ballots.
Each ballot item in the list is an array containing the choices in order from highest to lowest preference.

Example:
<pre>
  - [BORING, EVIL, FACTIOUS, ABNORMAL, CHAOTIC]
</pre>

If input ties are allowed by the voting method and the vote configuration, ties may be 

Example:
<pre>
  - [BORING, [EVIL, FACTIOUS], ABNORMAL, CHAOTIC]
</pre>

(more detail in progress)
