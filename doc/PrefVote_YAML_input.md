# PrefVote YAML Input File Specification

PrefVote's primary vote input file format uses YAML.
The file is separated by two or more YAML "documents", or separate file sections.
Each document in the YAML file is separated by a "---" line.
If there are more than two, then additional document sections are for testing purposes.

The first document in the file defines the vote including the voting method/algorithm.

The second document contains a list of ballots.
These should have been assembled into the YAML file from wherever the votes were submitted and assembled.

(more detail in progress)
