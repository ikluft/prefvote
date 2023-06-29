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
* "params" contains a YAML structure which will be passed to the voting algorithm

The params structure contains the following items.

(more detail in progress)
