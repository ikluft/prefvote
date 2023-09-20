# PrefVote support of Condorcet Election Format (CEF) input files

PrefVote interprets files named like \*.cvotes as [Condorcet Election Format (CEF)](https://github.com/CondorcetVote/CondorcetElectionFormat#invalid). CEF was developed as a common input file format intended to be supported by voting systems using Condorcet-compatible methods.

## CEF parameter lines

The CEF file begins with parameter lines at the top.
These must all occur before the first ballot line.

    [work in progress - to be continued]

## CEF ballot lines: syntax diagrams and ABNF definitions

Syntax diagrams and Augmented Backus–Naur Form (ABNF) (see [Internet Standard 68 / RFC 5234](https://tools.ietf.org/html/std68)) define lines of the CEF ballot

### tokens

    TAGDELIM = "||"

    EMPTY_RANKING = "/EMPTY_RANKING/"

    INT = 1*DIGIT

    WORD = 1*( ALPHA / DIGIT / "_" / "!" / "$" / "%" / "&" / "+" / "." / ":" / ";" / "@" / "-" )

### words

    word = WORD / INT

    words = words word
    words =/ word

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

