# PrefVote support of Condorcet Election Format (CEF) input files

PrefVote interprets files named like \*.cvotes as [Condorcet Election Format (CEF)](https://github.com/CondorcetVote/CondorcetElectionFormat#invalid). CEF is intended as a common input file format intended to be supported by voting systems using Condorcet-compatible methods. PrefVote added support for CEF in addition to the original YAML-based input files.

CEF files consist of two sections: election/poll configuration parameters followed by vote data.

## Example

This is an example of Condorcet Election Format (CEF) from the definition page.

    # My beautiful election
    #/Candidates: Candidate A;Candidate B;Candidate C
    #/Implicit Ranking: true
    #/Weight allowed: true

    # vote data:
    Candidate A > Candidate B > Candidate C * 42
    julien@condorcet.vote , signature:55073db57b0a859911 || Candidate A > Candidate B > Candidate C # Same as above, so there will be 43 votes with this ranking. And tags are registered by the software if able.
    Candidate C > Candidate A = Candidate B ^7 * 8 # 8 votes with a weight of 7.
    Candidate B = Candidate A > Candidate C
    Candidate C # Interpreted as Candidate C > Candidate A = Candidate B, because implicit ranking is true (which is also default, but it's better to say it)
    Candidate B > Candidate C # Interpreted as Candidate B > Candidate C

The example shows how all CEF files start with parameter lines which describe the election.

After the parameters come the vote lines. Preferences are marked with the greater-than ">" operator. Equality among candidates are marked with the equals "=" operator. Candidate/option names may contain spaces.

CEF allows tags to contain additional data about a vote line. At this time, PrefVote parses the tag data but does not use it.

Parameters are no longer allowed after the first vote line. In other words, you cannot change the configuration of the election after processing the first vote.

## CEF parameter lines and comments

Comments start with a '#'. They do not have to be at the beginning of the line. No further parsing of the line is done after the start of a comment.

CEF parameter lines begin with "#/" followed by the name of the parameter, a colon ':', and the value of the parameter. The parameter name may contain spaces.

The CEF file begins with parameter lines at the top.
These must all occur before the first vote line.

### #/Candidates:

Semicolon-delimited list of names of choices/candidates in the election.

This is optional, but recommended. If not specified, the candidates will be collected from ballot lines. It is recommended to specify valid candidates so that invalid candidates can be recognized.

### #/Number of Seats:

Integer value with the number of seats available for election or selection. In other words, this is how many winners are allowed in the voting results.

This is optional. If not specified, PrefVote sets the number of seats to zero, which ranks all the candidates in order of voting results without mentioning a number of winners. This differs from the CEF definition which sets an arbitrary integer 100 for the number of seats, intended to be more than the number of candidates in most elections. In effect, both achieve similar results of ranking all the candidates.

### #/Implicit Ranking:

Boolean "true" or "false" value, if set, signals that choices/candidates omitted from a ballot get ranked into last place.

This is optional. The default value is true. It is recommended to set this to true (which happens by default). The setting can make a difference in voting results and is important to be aware which setting is in use.

### #/Voting Methods:

Semicolon-delimited list of names of voting methods allowed for processing the election.

This can also be specified by the singular-form alias "#/Voting Method:".

This is optional. CEF provides no default value and leaves that decision to the underlying voting system. PrefVote usually requires a voting method via the YAML or direct-API calls. For processing CEF, PrefVote uses a default value of RankedPairs.

### #/Weight Allowed:

Boolean "true" or "false" value, if set, signals that weights are allowed on votes. When weights are not allowed or not specified, they have a weight multiplier of 1.

The default value is false. Specifying a weight (with the "^" operator) when the "Weight Allowed" parameter is not set is considered by PrefVote to be an error and results in rejection of any such ballot line as invalid.

### Non-standard parameters

Handling of non-standard parameter names is not defined by the CEF standard. For orderly degradation of service among varying versions of software, PrefVote takes no action when a non-standard parameter name is used. The effect is that all parameters are stored, but software only reads and acts on standard names from the spec.

## CEF vote lines: syntax diagrams and ABNF definitions

Following the parameters are vote lines. No more parameters are allowed after the first vote line.

Vote lines may represent individual ballots with a quantifier of 1, or ballots which all had the same content and a quantifier indicating how many identical-pattern ballots were aggregated into one line.

Syntax diagrams and
[Augmented Backus–Naur Form (ABNF)](https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form)
(see [Internet Standard 68 / RFC 5234](https://tools.ietf.org/html/std68)) define how to parse lines of CEF votes.

### tokens

    TAGDELIM = "||"

    EMPTY_RANKING = "/EMPTY_RANKING/"

    INT = 1*DIGIT

    WORD = 1*( ALPHA / DIGIT / "_" / "!" / "$" / "%" / "&" / "+" / "." / ":" / ";" / "@" / "-" )

### words

Sequences of words may have numbers in them as well. Since numbers are parsed as INT, those are included in recognized word sequences.

    words = 1*( WORD / INT )

![syntax diagram for words](images/syndiag-cef-words.svg)

### candidate

Candidate names are sequences of words.

    candidate = words

![syntax diagram for candidate](images/syndiag-cef-candidate.svg)

### quantifier

A quantifier specifies multiple votes which contained the same content and order.

    quantifier = "*" INT

![syntax diagram for quantifier](images/syndiag-cef-quantifier.svg)

### weight

A weight specifies a vote which for some reason of voting rules counts as a greater value than others.
Weights are only allowed when the "Weight Allowed" parameter is set to true.
Under normal/default circumstances, they are not allowed and all votes have an equal weight of 1.

    weight = "^" INT

![syntax diagram for weight](images/syndiag-cef-weight.svg)

### tag 

Tags are strings attached to a vote line.
These are defined in the CEF standard but currently not used by PrefVote.

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

