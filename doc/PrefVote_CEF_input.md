# PrefVote support of Condorcet Election Format (CEF) input files

PrefVote interprets files named like \*.cvotes as [Condorcet Election Format (CEF)](https://github.com/CondorcetVote/CondorcetElectionFormat#invalid). CEF was developed as a common input file format intended to be supported by voting systems using Condorcet-compatible methods.

## CEF parameter lines and comments

Comments start with a '#'. They do not have to be at the beginning of the line. No further parsing of the line is done after the start of a comment.

CEF parameter lines begin with "#/" followed by the name of the parameter, a colon ':', and the value of the parameter.

The CEF file begins with parameter lines at the top.
These must all occur before the first vote line.

### #/Candidates:

Semicolon-delimited list of names of choices/candidates in the election.

This is optional, but recommended. If not specified, the candidates will be collected from ballot lines. It is recommended to specify valid candidates so that invalid candidates can be recognized.

### #/Number of Seats:

Integer value with the number of seats available for election or selection. In other words, this is how many winners are allowed in the voting results.

This is optional. If not specified, PrefVote sets the number of seats to zero, which ranks all the candidates in order of voting results without mentioning a number of winners. This differs from the CEF definition which sets an arbitrary integer 100 for the number of seats, intended to be more than the number of candidates in most elections. In effect, both achieve similar results of ranking all the candidates.

    [work in progress - to be continued]

## CEF vote lines: syntax diagrams and ABNF definitions

Syntax diagrams and
[Augmented Backus–Naur Form (ABNF)](https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form)
(see [Internet Standard 68 / RFC 5234](https://tools.ietf.org/html/std68)) define how to parse lines of CEF votes.

### tokens

    TAGDELIM = "||"

    EMPTY_RANKING = "/EMPTY_RANKING/"

    INT = 1*DIGIT

    WORD = 1*( ALPHA / DIGIT / "_" / "!" / "$" / "%" / "&" / "+" / "." / ":" / ";" / "@" / "-" )

### words

    words = 1*( WORD / INT )

![syntax diagram for words](images/syndiag-cef-words.svg)

### candidate

    candidate = words

![syntax diagram for candidate](images/syndiag-cef-candidate.svg)

### quantifier

    quantifier = "*" INT

![syntax diagram for quantifier](images/syndiag-cef-quantifier.svg)

### weight

    weight = "^" INT

![syntax diagram for weight](images/syndiag-cef-weight.svg)

### tag 

    tag = words

![syntax diagram for tag](images/syndiag-cef-tag.svg)

### line

PrefVote differs from the official CEF definition in parsing multipliers (quantifier and/or weight) in any order, as long as each appears no more than once. For CEF files which strictly follow the official definition, when both are specified then the weight must be first, followed by the quantifier. PrefVote will not consider it an error if quantifier is followed by weight.

    tags = tags "," tag
	tags =/ tag

    multipliers = quantifier weight
    multipliers =/ weight quantifier
    multipliers =/ quantifier
    multipliers =/ weight

    ranking = choice_list 0*1multipliers
    ranking =/ EMPTY_RANKING 0*1multipliers

    line = tags TAGDELIM ranking
    line =/ ranking

![syntax diagram for line](images/syndiag-cef-line.svg)

