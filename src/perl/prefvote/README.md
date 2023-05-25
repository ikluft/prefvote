# PrefVote::Core

# SYNOPSIS

    use PrefVote::Core;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::Core::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...

# DESCRIPTION

_PrefVote::Core_ is the common code base between voting methods supported by [PrefVote](https://metacpan.org/pod/PrefVote).
It handles data and code in common among the preference voting systems, including
input and tallying of ranked choice ballots, indexing of choices/candidates,
computing average choice rank (ACR) as tie-breaking data, storage of basic results,
and black-box testing infrastructure.

It is important to understand that _PrefVote::Core_ alone is not a valid voting method.
For counting any real votes or polls, this must be used as the superclass for a ranked-choice
voting method, such as [PrefVote::STV](https://metacpan.org/pod/PrefVote%3A%3ASTV), [PrefVote::Schulze](https://metacpan.org/pod/PrefVote%3A%3ASchulze) or [PrefVote::RankedPairs](https://metacpan.org/pod/PrefVote%3A%3ARankedPairs).
Those methods make quantitative counts, such that a greater number of votes for one choice
will make it win over another if all other things are equal. That is a required expectation
in any voting system.

_PrefVote::Core_ collects average choice rank (ACR) data to be used for tie-breaking in any
of the supported voting methods. _PrefVote::Core_ may be run alone for testing purposes and
will use ACR data in that case. However, the reason ACR is not appropriate as a voting method
on its own is because it is an average ranking, regardless of the number of votes cast for a
particular choice.
It only makes sense for tie-breaking, where becomes meaningful if everything else is equal.

# ATTRIBUTES

- name

    the name or title of the poll to be performed

- choice\_to\_index

    a hash using a choice/candidate's identifier string as the key and containing the hexadecimal index code for
    that choice/candidate

- index\_to\_choice

    a hash using the hexadecimal index code for a choice/candidate as the key and containing
    the choice/candidate's identifier string

- choice\_to\_result

    a hash using a choice/candidate's identifier string as the key and containing the results for that
    choice/candidate

- choices

    a hash using a choice/candidate's identifier string as the key and containing a longer printable name or description
    for the choice/candidate

- seats

    integer number of seats to be filled by this vote.
    If not provided the default is 1.

- ballots

    a hash indexed by a hash string (see below) and containing references to [PrefVote::Core::Ballot](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3ABallot) structures.

    The hash string used as the index contains a unique representation of the ballot
    by concatenating the hexadecimal number representation for each choice/candidate in the order they appear
    on the ballot.
    On voting methods which allow ballot-input ties (ranking two or more choices/candidates as equal),
    those equal items are enclosed in square brackets and listed in ascending sorted order within them.
    Together these represent a unique combination of voting preferences for a ballot.

    The  [PrefVote::Core::Ballot](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3ABallot) structure also contains an integer quantity of the number of ballots
    in which that combination occurred.
    Each combination present in the submitted ballots will only occur once in the hash.
    The quantity says how many of them were received.

- total\_ballots

    is an integer value of the number of ballots that were counted.

- choice\_rank

    is a workspace to tally each choice/candidate's number of times at each position on a ranked choice ballot.
    This is used after all ballots have been tallied to compute the average choice rank (ACR) which PrefVote uses
    for tie-breaking in all its supported voting methods.

    It's a hash structure indexed by the candidate's identifier string, and containing an array of integers
    each with a tally of the number of times the choice/candidate occurred in the nth place on a ballot.

- average\_choice\_rank

    is a hash indexed by the choice/candidate identifier string, and containing the average choice rank (ACR) for
    that choice/candidate.
    PrefVote uses ACR for tie-breaking.

- testspec

    is optional and only assigned a value when black-box testing is being done.
    It contains a reference to a [PrefVote::Core::TestSpec](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3ATestSpec) tree,
    which defines a tree of tests to run in comparison against this PrefVote::Core object,
    or any subclass of it for supported voting methods.

# METHODS

- ballot\_input\_ties\_policy(flag)

    can be called as either a class or object method to set the flag which allows ballots to have choices tied.
    In PrefVote this is called "ballot input ties" to differentiate it from ties in voting results.
    Under [PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore) this flag defaults to false.
    Voting methods which need to set it to default true, such as [PrefVote::Schulze](https://metacpan.org/pod/PrefVote%3A%3ASchulze), must override the method to do so.

- choice\_exists(str)

    returns true if the string parameter is a valid choice/candidate identifier string as configured for this vote.
    This is used for validating choices during ballot input processing.

- get\_choices()

    returns a list of choice/candidate identifier strings for the current vote.

- save\_ranking(ballot)

    is called by submit\_ballot() to record the rankings of an individual ballot.
    The ballot parameter is a list of strings (not an array reference) with choice/candidate identifier strings.

- average\_ranking(choice)

    returns the average choice rank (ACR) for a choice/candidate.
    This is the average of all the ballot positions where this choice/candidate occurred on ballots,
    where 1 is first place, 2 is second place and so on.
    The choice parameter is a choice/candidate identifier string.

    In voting methods which allow tied input rankings, such as Schulze, all tied choices/candidates will be recorded
    with the same number from ballots where input ties occur.

- gen\_choice\_hex()

    is used by _PrefVote::Core_ during initialization to generate the lookup tables choice\_to\_index and index\_to\_choice
    to convert both directions between choice/candidate identifier strings and a sequential hexadecimal number to use
    as their hash index abbreviations.

    The hexadecimal index is also in ballot combination index strings by concatenating them
    sequentially in ballot order.

- ballot\_to\_hex(@ballot)

    receives a ballot combination as an array of strings
    and converts it to a hex index string by concatenating the hexadecimal codes for the choices/candidates
    in ballot order.
    For voting methods which allow ties input rankings, such as Schulze, square brackets enclose the tied items,
    listed in ascending order to ensure uniqueness and matching when compared.

    This is called by submit\_ballot().

- submit\_ballot(@ballot)

    receives a ballot as an array of strings and stores it for later counting after all have been received.

    It throws exceptions if the ballot has content errors.
    Exceptions should be caught and considered rejected ballots which have not been stored for counting.
    Exceptions only reject the ballot and should not be fatal for the program.
    Errors which result in exceptions are as follows:

    - an empty ballot
    - a ballot input tie is given in a voting method which doesn't accept them

- ingest\_ballots

    is called by file2vote() after it instantiates an object of _PrefVote::Core_ or a derivative class.
    This reads the 2nd YAML document in the input, which contains a list of ballots to be counted.

- count()

    counts votes in the _PrefVote::Core_ object.

    The count() method must be overridden in each class derived from _PrefVote::Core_.

    In _PrefVote::Core_ this method is only for testing purposes because it isn't a valid voting method.
    The voting method must be provided by a derived class specifically written to handle them.
    Since _PrefVote::Core_ contains average ballot positions of each candidate, that data is used f or testing
    purposes.
    But average ballot position doesn't take quantity votes into account,
    which must be used in the first pass of any valid voting method.

    An example of what could easily go wrong if _PrefVote::Core_ was used to count real ranked-choice ballots
    is if a choice/candidate was ranked first place on one or few ballots, leaving a high average rank
    even with few votes in favor.

- save\_c2r(winners => \[wlist\], eliminated => \[elist\])

    is a method which must be called by subclasses of _PrefVote::Core_ to record their voting results.
    The _winners_ parmeter is required, and must contain a list in order from first place to last of the winning
    choices/candidates by their identifier strings.
    The _eliminated_ parameter is optional,
    provided only by voting methods whose definition includes elimination of candidates
    such as Single Transferable Vote (STV).

    save\_c2r() uses the _winners_ and _eliminated_ to populate the _choice\_to\_result_ hash attribute withs
    and array containing each choice/candidate's numeric place and a disposition string:
    "selected" for winner(s) up to the number of seats up for election,
    "tied" if a tie between multiple choices/candidates spans more than available seats,
    "placed" if a choice/candidate placed in the results but did not attain one of the available seats, and
    "eliminated" if a choice/candidate was eliminated from contention (such as in STV).

    In case of any choice/candidate marked "tied", it is the software's responsibility to report that the count
    resulted in an unresolved tie.
    The organization using the software should have already made a policy before the poll how to handle ties.
    For low-stakes polls, such as where to meet for dinner, a random selection such as a coin-toss may be acceptable.
    For high-stakes elections, a runoff may be a more appropriate action.
    For polls on approval of a proposal or measure, a tie should mean failure to achieve a majority.

    _PrefVote::Core_ makes average choice rank (ACR) data available to subclasses which must use it for tie-breaking,
    except when the _no-tiebreak_ configuration flag is set.
    Ties should be extremely unlikely with ACR tie-breaking enabled.

- result\_yaml()

    returns a summary of this _PrefVote::Core_ or derivative object which is suitable to hand off to YAML::Dump()
    to generate YAML output of the results.

    It is called by the _format\_output()_ method if the format "yaml" is specified.
    The data returned is too detailed and technical for display to users or voters.
    The output is intended to be processed by another program supplied by the developer whose code called this.

- format\_output(format)

    uses the _format_ parameter to determine the function to call for output formatting.

    - yaml

        calls [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) _Dump()_ using the output of the _result\_yaml()_ method.
        This detailed data is intended for use by an external program provided by a developer.

    - rawyaml

        calls [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) _Dump()_ using this object.
        This is intended for testing only, and is used to create black box testing baseline data from the current run.

    - others

        delegates output formatting to the appropriate subclass of [PrefVote::Core::Output](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3AOutput) named by the parameter.
        Currently supported formats are Text, Markdown, HTML and rawcapture.
        The "rawcapture" format is intended for testing.
        The others are intended for human-readable display.

        To add new formats, a new subclass of [PrefVote::Core::Output](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3AOutput) must be created to handle it.

- blackbox\_check()

    initiates a black-box test run by calling the _check()_ method on the _testspec_ attribute,
    which is an instance of [PrefVote::Core::TestSpec](https://metacpan.org/pod/PrefVote%3A%3ACore%3A%3ATestSpec).
    It passes the current object as a parameter to _check()_.

    It builds a test tree by querying metadata about testable subclasses of [PrefVote](https://metacpan.org/pod/PrefVote),
    which are those that stored their test trees via the _register\_blackbox\_spec()_ class method.
    Each node in the test tree corresponds to an attribute in that class' objects.
    A test is generated comparing the node's value with a value from a previous run stored in the
    YAML input data's 3rd document.

    If there is no 3rd document data in the YAML file, then black-box testing is skipped.

    It returns a test tree which may be run by [Test::More](https://metacpan.org/pod/Test%3A%3AMore).
    The [vote-count](https://metacpan.org/pod/vote-count) script performs that task when given the _--test_ command-line option.

# FUNCTIONS

- supported\_method(method)

    returns true if the method string passed as a parameter matches any of the supported voting methods.
    The matching is not case-sensitive.

- read\_yaml(filepath)

    uses the _filepath_ parameter as a string with the filename of a YAML file to read and parse.
    It returns a list of the parsed YAML document structures found in that file.

    This function throws exceptions if the filepath names a file which doesn't exist or is not a regular file.
    It also throws an exception if the content of that file can't be parsed by [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS).

- determine\_method({key => value, ...}, votedef)

    determines which class will handle the vote counting and processing.
    It returns the name of a class which is either [PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore) or a subclass of it.
    The votedef parameter comes from the YAML input file first parsed YAML document.
    It must contain a _method_ attribute which contains a space-delimeted string of one or more voting method names,
    which are all the voting methods allowed/supported for this YAML data file.
    Usually only one would be specified, whichever was defined for the vote.
    For testing more than one is useful to test the same data on multiple ranked-choice voting methods.

    The optional key/value parameters currently only support a key of "method" and a voting method to select.
    The method parameter is required if the votedef structure allows more than one voting method,
    in order to select which one to use.

    Currently supported voting methods are Core (testing only), STV, Schulze and RankedPairs.
    New voting methods can be implemented by adding a new subclass of [PrefVote::Core](https://metacpan.org/pod/PrefVote%3A%3ACore).

- file2vote({key => value, ...}, filepath)

    reads a YAML input file and constructs an object of _PrefVote::Core_
    or the appropriate subclass to handle the selected voting method.

    It takes a file path as a parameter.
    Optionally a hash reference may be provided inserted as the first option in order to provide
    key/value configuration options.
    The options are passed to determine\_method() so the only currently supported option is "method",
    which must be provided if the YAML data allows more that one type of voting method on the data.
    It determines which voting method to use on this run.

    The scenario of a vote definition supporting more than one type of voting method is mainly for testing,
    where black-box tests may run the same ranked-chocie ballot data through multiple voting methods, one at a time.

# SEE ALSO

[PrefVote](https://metacpan.org/pod/PrefVote)
[https://github.com/ikluft/prefvote](https://github.com/ikluft/prefvote)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/prefvote/issues](https://github.com/ikluft/prefvote/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/prefvote/pulls](https://github.com/ikluft/prefvote/pulls)
