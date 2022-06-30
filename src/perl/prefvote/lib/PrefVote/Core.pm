# PrefVote::Core
# ABSTRACT: common code for all PrefVote voting methods
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core;

use autodie;
use DateTime;
use Readonly;
use Set::Tiny qw(set);
use Scalar::Util 'reftype';
use YAML::XS;
use PrefVote::Core::Ballot;
use PrefVote::Core::Exception;
use PrefVote::Core::MethodMismatchException;
use PrefVote::Core::TestSpec;

# supported voting methods - for constructing class names from vote definitions
# use Core only for testing because the base class doesn't actually have voting-method code
Readonly::Array my @voting_methods => qw(Core STV Schulze RankedPairs);

#
# class definitions
#
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Str Int Enum ArrayRef HashRef Map Tuple InstanceOf Any);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp float_internal PVPositiveOrZeroNum);
extends 'PrefVote';
with 'MooX::Singleton';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    name => [qw(string)],
    choice_to_index => [qw(hash string)],
    index_to_choice => [qw(hash string)],
    choice_to_result => [qw(hash list string)], # list of strings is all we can do for a tuple
    choices => [qw(hash string)],
    seats => [qw(int)],
    ballots => [qw(hash PrefVote::Core::Ballot)],
    total_ballots => [qw(int)],
    choice_rank => [qw(hash list int)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec);

# name of poll/vote
has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# bidirectional hashes for converting between index strings and choice identifier strings
has choice_to_index => (
    is => 'rw',
    isa => Map[NonEmptySimpleStr, NonEmptySimpleStr],
    handles_via => 'Hash',
    handles => {
        c2i_exists => 'exists',
        c2i_get => 'get',
        c2i_set => 'set',
    },
);
has index_to_choice => (
    is => 'rw',
    isa => Map[NonEmptySimpleStr, NonEmptySimpleStr],
    handles_via => 'Hash',
    handles => {
        i2c_exists => 'exists',
        i2c_get => 'get',
        i2c_set => 'set',
    },
);

# Hash from choice names to final result/disposition
# This must be provided by the voting method subclass from its count.
# The map structure hashes from choice name to a tuple of place number & disposition (selected/tied/placed/eliminated)
# Place numbers are not necessarily unique, and will be equal for ties
# Selected choices are those whose placement was less than or equal to the number of seats.
# Tied choices are any group in a tie whose numbers span the number of seats to beyond it.
# Placed choices got a result in sequence after the last seat was filled.
# Eliminated candidates still have place numbers depending on the order or strength of elimination.
has choice_to_result => (
    is => 'rw',
    isa => Map[NonEmptySimpleStr, Tuple[Int, Enum[qw(selected tied placed eliminated)]]],
    handles_via => 'Hash',
    handles => {
        c2r_exists => 'exists',
        c2r_get => 'get',
        c2r_set => 'set',
    },
);

# strings identifying poll/vote choices
has choices => (
    is => 'ro',
    isa => HashRef[NonEmptySimpleStr],
    required => 1,
    trigger => sub {
        my $self = shift;
        $self->debug_print("set choices to ".join(" ", $self->choices_keys()));
        $self->gen_choice_hex();
        PrefVote::Core::Ballot::set_choices($self->choices_keys());
        PrefVote::Core::Ballot::ballot_input_ties_flag($self->ballot_input_ties_policy());
    },
    handles_via => 'Hash',
    handles => {
        choices_count => 'count',
        choices_exists => 'exists',
        choices_get => 'get',
        choices_keys => 'keys',
    },
);

# number of seats/selections to be filled by poll/vote
has seats => (
    is => 'ro',
    isa => PositiveInt,
    default => sub { return 1 },
);

# array of ballot structures
has ballots => (
    is => 'rw',
    isa => Map[Str,InstanceOf["PrefVote::Core::Ballot"]],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        ballots_exists => 'exists',
        ballots_get => 'get',
        ballots_keys => 'keys',
        ballots_set => 'set',
    },
);

# count of total ballots
has total_ballots => (
    is => 'rw',
    isa => PositiveOrZeroInt,
    default => 0,
);

# keep each choice/candidate's position on ballots to compute average placement
has choice_rank => (
    is => 'rw',
    isa => HashRef[ArrayRef[PositiveOrZeroInt]],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        cr_exists => 'exists',
        cr_get => 'get',
        cr_keys => 'keys',
        cr_set => 'set',
    },
);

# average position on ballots for each choice/candidate
has average_choice_rank => (
    is => 'rw',
    isa => HashRef[PVPositiveOrZeroNum],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        acr_exists => 'exists',
        acr_get => 'get',
        acr_keys => 'keys',
        acr_set => 'set',
    },
),

# blackbox testing checklist structure
# this is filled from the extra data from YAML input file, used for testing all PrefVote language implementations
has testspec => (
    is => 'ro',
    isa => InstanceOf["PrefVote::Core::TestSpec"],
    required => 0,
);

# By default PrefVote::Core sets ballot-input ties policy to false.
# Override this in voting method subclasses which allow input ties. (i.e. Schulze)
my $ballot_input_ties_policy = __PACKAGE__->config("input-ties") // 0; # only change this for testing purposes
sub ballot_input_ties_policy
{
    shift; # discard unneeded $self parameter - it doesn't matter if this is called as a class or object method
    my $value = shift;
    if (defined $value) {
        $ballot_input_ties_policy = ($value ? 1 : 0)
    }
    return $ballot_input_ties_policy;
}

# final result status per candidate
# key: candidate abbreviation string
# value: hashref with place (integer), 

# utility for functions to select between class and object
sub _class_or_obj
{
    my $coo = shift;
    if (not $coo->isa(__PACKAGE__)) {
        PrefVote::Core::Exception->throw(description => "_class_or_obj: parameter not in class hierarchy"
            .((ref $coo) ? ref $coo : $coo));
    }
    if (ref $coo) {
        return $coo;
    }
    return $coo->instance();
}

# get class suffix, which for subclasses of PrefVote::Core is the voting methods name
sub _suffix
{
    my ($class_or_obj) = @_;
    my $self = _class_or_obj($class_or_obj);
    my $class_suffix = ref $self;
    $class_suffix =~ s/^.*:://x; # remove everything except the last part of the class name
    return $class_suffix;
}

# check existence of a voting choice/option
sub choice_exists
{
    my ($class_or_obj, $str) = @_;
    return 0 if not defined $str;
    my $self = _class_or_obj($class_or_obj);
    return $self->choices_exists($str) ? 1 : 0;
}

# get list of choices
sub get_choices
{
    my $class_or_obj = shift;
    my $self = _class_or_obj($class_or_obj);
    return $self->choices_keys();
}

# check if a string matches a supported voting method
sub supported_method
{
    my $method = shift;
    foreach my $supported (@voting_methods) {
        if (fc $method eq fc $supported) {
            return $supported;
        }
    }
    return;
}

# tally ballot positions of choices/candidates
sub save_ranking
{
    my ($self, @ballot) = @_;

    # increment tallies for numeric places of each choice
    my $choices_num = $self->choices_count();
    for (my $i=0; $i < scalar @ballot; $i++) {
        my $choice = $ballot[$i];

        # make sure place record exists for this choice
        foreach my $item ($choice->elements()) {
            if (not exists $self->{choice_rank}{$item}) {
                # init array of position tallies to zero
                $self->{choice_rank}{$item} = [(0) x $choices_num];
            }

            # increment count for this choice in its ballot position
            $self->{choice_rank}{$item}[$i]++;
        }
    }
    return;
}

# get candidate average ballot-position ranking
# return max/last place if no data on the choice/candidate (never appeared on any ballots)
# note: average ballot placement doesn't consider total votes and shouldn't be a primary criteria, except in testing
# after primary voting criteria are computed, this can be a tie-breaker like scoring the candidates
sub average_ranking
{
    my ($self, $choice) = @_;

    # if we already computed this, use the stored value
    if ($self->acr_exists($choice)) {
        return $self->acr_get($choice);
    }

    # set defualt result last place case if no data, which can happen if a candidate never appeared on any ballots
    my $result = $self->choices_count(); # default result is last place

    # process average if data exists
    if (exists $self->{choice_rank}{$choice}) {
        # compute average place (array index + 1) for the choice/candidate
        my $total_votes = 0;
        my $total_place = 0.0;
        for (my $i=0; $i < scalar @{$self->{choice_rank}{$choice}}; $i++) {
            $total_votes += $self->{choice_rank}{$choice}[$i];
            $total_place += ($i+1)*$self->{choice_rank}{$choice}[$i];
        }

        # set average if votes were found
        if ($total_votes > 0) {
            $result = float_internal($total_place/$total_votes);
            $self->acr_set($choice, $result);
        }
    }
    return $result;
}

# generate choice hexadecimal index values and bidirectional hash lookup tables
# hexadecimal number indexes substantially shorten the hash key strings used to look up unique ballot combinations
sub gen_choice_hex
{
    my $self = shift;

    # compute how many hex digits are needed for all the choices
    my $count = $self->choices_count();
    my $hexdigits = int(log($count)/log(16)); # compute number of hex digits necessary to contain total choices

    # initialize lookup tables - we can't count a default value being set yet since this is called from a trigger
    $self->choice_to_index({});
    $self->index_to_choice({});

    # populate lookup tables in both directions: choice id <-> hex index
    my @sorted_keys = sort $self->choices_keys();
    for (my $i=0; $i<$count; $i++) {
        my $choice_str = $sorted_keys[$i];
        my $index_str = sprintf("%0*x", $hexdigits, $i);
        $self->c2i_set($choice_str, $index_str);
        $self->i2c_set($index_str, $choice_str);
    }
    return;
}

# convert a ballot combination to a hex index string
sub ballot_to_hex
{
    my ($self, @ballot) = @_;
    my $hex_id = "";

    # generate hex digit(s) for each candidate's listed position
    foreach my $item (@ballot) {
        my $set_hex = "";
        # sort elements within a ballot-input tie group for consistency and enclose them in square brackets
        foreach my $set_item (sort $item->elements()) {
            if ($self->c2i_exists($set_item)) {
                $set_hex .= $self->c2i_get($set_item);
            }
        }
        if ($item->size() > 1) {
            $hex_id .= "[$set_hex]";
        } else {
            $hex_id .= $set_hex;
        }
    }
    return $hex_id;
}

#
# data input
#

# submit a ballot - just store it, do not count yet
# exceptions: ballot content errors
sub submit_ballot
{
    my ($self, @ballot) = @_;

    # filter out invalid items from ballot
    my @filtered_ballot;
    foreach my $item (@ballot) {
        # check for ballot-input ties
        if (index($item, "/") == -1) {
            # just a single item - save it if it's valid
            if ($self->choice_exists($item)) {
                push @filtered_ballot, set($item);
            }
            next;
        }

        # handle ballot-input tie if allowed by this voting method
        if (not $self->ballot_input_ties_policy()) {
            PrefVote::Core::Exception->throw(description => "ballot-input ties not allowed in ".(ref $self));
        }
        my @set_items;
        foreach my $set_item (split("/", $item)) {
            if ($self->choice_exists($set_item)) {
                push @set_items, $set_item;
            }
        }
        push @filtered_ballot, set(@set_items);
    }

    # throw exception for empty ballot after filtering
    if ((scalar @filtered_ballot) == 0) {
        PrefVote::Core::Exception->throw(description => "empty ballot");
    }

    # Note: ballots are anonymous and become aggregated once this function is called.
    # Protection against casting multiple votes must be done elsewhere
    # (preferably when the vote is received) because this module doesn't
    # retain any association between the ballot and the voter.

    # record placement of choices on ballot
    $self->save_ranking(@filtered_ballot);

    # make a string of this ballot combination for lookup
    my $hex_id = $self->ballot_to_hex(@filtered_ballot);

    # check if this combination already exists and increment it if it does, if not create/save new combo
    my $ballot;
    my $action;
    if ($self->ballots_exists($hex_id)) {
        $action = "increment";
        $ballot = $self->ballots_get($hex_id);
        $ballot->increment();
    } else {
        $action = "new";
        $ballot = PrefVote::Core::Ballot->new(items => \@filtered_ballot, hex_id => $hex_id, quantity => 1);
        $self->ballots_set($hex_id, $ballot);
    }
    $self->debug_print("accepting $action: ", $ballot->as_string());
    $self->{total_ballots}++;
    return $hex_id; # returns index key, whose absence can be used to detect if an exception was thrown
}

# read YAML input
sub read_yaml
{
    my $filepath = shift;

    # read YAML
    (-e $filepath) or PrefVote::Core::Exception->throw(description => "$filepath not found");
    (-f $filepath) or PrefVote::Core::Exception->throw(description => "$filepath not a regular file");
    my @yaml_docs = eval { YAML::XS::LoadFile($filepath) };
    if ($@) {
        PrefVote::Core::Exception->throw(description => "$0: error reading $filepath: $@");
    }
    return @yaml_docs;
}

# input ballots to a PrefVote::Core-subclass voting method
sub ingest_ballots
{
    my ($vote_obj, $ballots) = @_;

    # ingest ballots from 2nd YAML document
    my $submitted = 0;
    my $accepted = 0;
    foreach my $ballot (@$ballots) {
        $submitted++;
        if ( eval { $vote_obj->submit_ballot(@$ballot) }) {
            $accepted++;
        } else {
            $vote_obj->debug_print("ballot entry failed: $@");
        }
    }
    $vote_obj->debug_print("votes: submitted=$submitted accepted=$accepted");
    return;
}

# count votes
# for testing only: Core is not a voting method
# IMPORTANT: count() METHOD MUST BE OVERRIDDEN BY ALL SUBCLASSES - THIS IS WHERE THEY IMPLEMENT THEIR VOTING METHOD
# since PrefVote::Core contains average ballot positions of each candidate, that data is used here for testing
# note: average ballot position doesn't take number of votes into account
# Do not use it as a primary sorting field in actual voting.
sub count
{
    my $self = shift;

    # sort results
    my @order = sort {fp_cmp($self->average_ranking($a), $self->average_ranking($b))} $self->choices_keys();
    my @winners;
    while (scalar @order) {
        my $cand = shift @order;
        my $cand_set = set($cand);
        while ((scalar @order) and fp_equal($self->average_ranking($order[0]), $self->average_ranking($cand))) {
            $cand_set->insert(shift @order);
        }
        push @winners, $cand_set;
    }

    # simplistic sort by average ballot position
    $self->save_c2r(winners => \@winners);
    return;
}

# determine voting method to use
# this may throw exceptions for method mismatch
sub determine_method
{
    my ($opts, $vote_def) = @_;

    # if a specific method was selected by %opts, make sure it's supported
    my $selected_method;
    if (exists $opts->{method}) {
        my $supported_method = supported_method($opts->{method});
        if (not defined $supported_method) {
            PrefVote::Core::MethodMismatchException->throw(description => "specified voting method "
                .($opts->{method} // "(undef)")." is not supported");
        }
        $selected_method = $supported_method;
    }

    # translate a voting method string into a voting-method class within this hierarchy
    # instantiate the voting object from 1st YAML document
    my $method_list = $vote_def->{method};
    my @methods_allowed = split(/\s+/x, $method_list);
    my $method;
    if (scalar @methods_allowed > 1) {
        if (defined $selected_method) {
            foreach my $method_item (@methods_allowed) {
                if (fc($selected_method) eq fc($method_item)) {
                    $method = $selected_method;
                    last;
                }
            }
            if (not defined $method) {
                PrefVote::Core::MethodMismatchException->throw(description => "specified voting method "
                    ."$selected_method not found in allowed options ".join(" ",@methods_allowed));
            }
        } else {
            PrefVote::Core::Exception->throw(description => "voting method not specified when multiple choices exist");
        }
    } else {
        if (defined $selected_method and $selected_method ne $methods_allowed[0]) {
            PrefVote::Core::MethodMismatchException->throw(description => "specified voting method $selected_method "
                ."doesn't match allowed option ".$methods_allowed[0]);
        }
        $method = $methods_allowed[0];
    }
    if (not defined $method) {
        PrefVote::Core::Exception->throw(description => "$selected_method not found in input file's voting methods");
    }
    return $method;
}

# convert YAML input to PrefVote::Core structure and ballots
# if first parameter is a hash reference, use it as options
# filepath scalar parameter points to YAML input file
sub yaml2vote
{
    my @args = @_;
    my %opts;
    if (ref $args[0] eq "HASH") {
        my $opts_ref = shift @args;
        %opts = %$opts_ref;
    }
    my $filepath = $args[0];
    my @yaml_docs = read_yaml($filepath);

    # save the first YAML document as the definition of the vote for entry into a PrefVote::Core structure
    my $yaml_vote_def = shift @yaml_docs;
    if (ref $yaml_vote_def ne "HASH") {
        PrefVote::Core::Exception->throw(description => "$0: misformatted YAML input: 1st document must be in "
            ."map/hash format");
    }
    foreach my $key ( qw(method params)) {
        if (not exists $yaml_vote_def->{$key}) {
            PrefVote::Core::Exception->throw(description => "$0: misformatted YAML input: "
                ."'$key' parameter missing from top level of vote definition");
        }
    }

    # save the second YAML document as the list of ballots
    my $yaml_ballots = shift @yaml_docs;
    if (ref $yaml_ballots ne "ARRAY") {
        PrefVote::Core::Exception->throw(description => "$0: misformatted YAML input: 2nd document "
            ."must be in list/array format");
    }

    # save any additional YAML documents in extra, available for testing
    my $extra_data = [@yaml_docs];

    # translate a voting method string into a voting-method class within this hierarchy
    # instantiate the voting object from 1st YAML document
    my $method = determine_method(\%opts, $yaml_vote_def);
    my $class = "PrefVote::$method";
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    if (not eval "require $class") {
        PrefVote::Core::Exception->throw(description => "failed to load class $class: $@");
    }
    ## critic (BuiltinFunctions::ProhibitStringyEval)
    if (not $class->isa(__PACKAGE__)) {
        PrefVote::Core::Exception->throw(description => "class $class in vote defintion is not a subclass of "
            .__PACKAGE__);
    }
    my $params = $yaml_vote_def->{params};
    if (scalar @$extra_data) {
        # use extra YAML documents as TestSpec for blackbox testing checklist
        my $testdoc = shift @$extra_data;
        if (ref $testdoc eq "HASH" and exists $testdoc->{$method}) {
            my $testspec = $testdoc->{$method};
            $params->{testspec} = PrefVote::Core::TestSpec->new(checklist => $testspec);
        }
    }
    ## no critic (Subroutines::ProtectPrivateSubs)
    PrefVote::Core->_clear_instance(); # replace the singleton: toss out previous instance if it exists
    ## use critic (Subroutines::ProtectPrivateSubs)
    my $vote_obj = eval { $class->instance(%$params) };
    if (not defined $vote_obj) {
        PrefVote::Core::Exception->throw(description => "failed to instantiate object of $class: $@");
    }

    # ingest ballots from 2nd YAML document
    ingest_ballots($vote_obj, $yaml_ballots);

    return $vote_obj;
}

# save per-candidate final results in choice_to_result map
sub save_c2r
{
    my ($self, %opts) = @_;
    my $seats = $self->seats();
    my $place = 0;

    # initialize the result map
    if (not exists $self->{choice_to_result}) {
        $self->choice_to_result({});
    }

    # scan winners to assign places and determine elected seats
    if (exists $opts{winners}) {
        my @winners = @{$opts{winners}};
        for (my $win_l1=0; $win_l1 < scalar @winners; $win_l1++) {
            # candidates in this list are tied if there's more than one
            my @group = $winners[$win_l1]->members();
            my $disposition;
            if ($place + scalar @group <= $seats) {
                $disposition = "selected";
            } elsif ($place < $seats and $place + scalar @group > $seats) {
                $disposition = "tied";
            } else {
                $disposition = "placed";
            }
            foreach my $cand_key (@group) {
                $self->c2r_set($cand_key, [$place+1, $disposition]);
            }
            $place += scalar @group;
        }
    }

    # mark results for eliminated candidates
    if (exists $opts{eliminated}) {
        my @eliminated = @{$opts{eliminated}};
        for (my $elim_l1=scalar @eliminated - 1; $elim_l1 >= 0; $elim_l1--) {
            my @group = $eliminated[$elim_l1]->members();
            foreach my $cand_key (@group) {
                $self->c2r_set($cand_key, [$place+1, "eliminated"]);
            }
            $place += scalar @group;
        }
    }

    # compute average_choice_rank for candidates where it didn't exist so it will be recorded with YAML results
    # this happens for any candidate where it wasn't computed on demand for tie-breaking
    foreach my $choice ($self->choices_keys()) {
        if (not $self->acr_exists($choice)) {
            $self->average_ranking($choice);
        }
    }

    return;
}

# collect detailed result nodes recursively for generation of YAML tests
sub result_node
{
    my $node = shift;

    # return scalar value directly
    if (not ref $node) {
        return $node;
    }

    # roll up Set::Tiny into an array of its elements
    if (ref $node eq "Set::Tiny") {
        return [$node->elements()];
    }

    # recursively collect array contents
    if (reftype $node eq "ARRAY") {
        my $result = [];
        foreach my $entry (@$node) {
            push @$result, result_node($entry);
        }
        return $result;
    }

    # recursively collect hash contents
    if (reftype $node eq "HASH") {
        my $result = {};
        foreach my $key (keys %$node) {
            next if $key eq "prev"; # omit all prev links since we know they're duplication
            $result->{$key} = result_node($node->{$key});
        }
        return $result;
    }

    # We got something else? Instead of throwing an exception, return it raw. YAML will tag whatever it is.
    return $node;
}

# collect result structure
# this is for conversion into YAML. But the conversion is not done here.
sub result_yaml
{
    my $self = shift;

    # copy relevant round/result records into YAML result structure
    my $result_out = {};
    foreach my $key (keys %$self) {
        next if $key eq "testspec"; # omit any current testspec since we use this to build a future testspec
        $result_out->{$key} = result_node($self->{$key});
    }
    $result_out->{timestamp} = localtime;

    # return result under item named for voting method class suffix
    # this makes the YAML output drop-in compatible with the input for black-box test data
    my $suffix = $self->_suffix();
    return {$suffix => $result_out};
}

# delegate output formatting to applicable classes
sub format_output
{
    my ($self, $format) = @_;

    # directly handle special cases of YAML and raw YAML formats
    if (fc($format) eq fc("yaml")) {
        # output YAML results
        print YAML::XS::Dump($self->result_yaml());
        return;
    }
    if (fc($format) eq fc("rawyaml")) {
        # output YAML results
        print YAML::XS::Dump($self);
        return;
    }

    # run output handler
    require PrefVote::Core::Output;
    PrefVote::Core::Output::do_output($format, ref $self, [YAML::XS::Dump($self->result_yaml())]);
    return;
}


# perform blackbox tests from current voting-method object
sub blackbox_check
{
    my $self = shift;
    return $self->{testspec}->check($self);
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Core - common code for all PrefVote voting methods

=head1 SYNOPSIS

    use PrefVote::Core;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::Core::yaml2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...


=head1 DESCRIPTION

I<PrefVote::Core> is the common code base between voting methods supported by L<PrefVote>.
It handles data and code in common among the preference voting systems, including
input and tallying of ranked choice ballots, indexing of choices/candidates,
computing average choice rank (ACR) as tie-breaking data, storage of basic results,
and black-box testing infrastructure.

=head1 ATTRIBUTES

=over 1

=item name

the name or title of the poll to be performed

=item choice_to_index

a hash using a choice/candidate's identifier string as the key and containing the hexadecimal index code for
that choice/candidate

=item index_to_choice

a hash using the hexadecimal index code for a choice/candidate as the key and containing
the choice/candidate's identifier string

=item choice_to_result

a hash using a choice/candidate's identifier string as the key and containing the results for that
choice/candidate

=item choices

a hash using a choice/candidate's identifier string as the key and containing a longer printable name or description
for the choice/candidate

=item seats

integer number of seats to be filled by this vote.
If not provided the default is 1.

=item ballots

a hash indexed by a hash string (see below) and containing references to L<PrefVote::Core::Ballot> structures.

The hash string used as the index contains a unique representation of the ballot
by concatenating the hexadecimal number representation for each choice/candidate in the order they appear
on the ballot.
On voting methods which allow ballot-input ties (ranking two or more choices/candidates as equal),
those equal items are enclosed in square brackets and listed in ascending sorted order within them.
Together these represent a unique combination of voting preferences for a ballot.

The  L<PrefVote::Core::Ballot> structure also contains an integer quantity of the number of ballots
in which that combination occurred.
Each combination present in the submitted ballots will only occur once in the hash.
The quantity says how many of them were received.

=item total_ballots

is an integer value of the number of ballots that were counted.

=item choice_rank

is a workspace to tally each choice/candidate's number of times at each position on a ranked choice ballot.
This is used after all ballots have been tallied to compute the average choice rank (ACR) which PrefVote uses
for tie-breaking in all its supported voting methods.

It's a hash structure indexed by the candidate's identifier string, and containing an array of integers
each with a tally of the number of times the choice/candidate occurred in the nth place on a ballot.

=item average_choice_rank

is a hash indexed by the choice/candidate identifier string, and containing the average choice rank (ACR) for
that choice/candidate.
PrefVote uses ACR for tie-breaking.

=item testspec

is optional and only assigned a value when black-box testing is being done.
It contains a reference to a L<PrefVote::Core::TestSpec> tree,
which defines a tree of tests to run in comparison against this PrefVote::Core object,
or any subclass of it for supported voting methods.

=back

=head1 METHODS

=over 1

=item ballot_input_ties_policy(flag)

can be called as either a class or object method to set the flag which allows ballots to have choices tied.
In PrefVote this is called "ballot input ties" to differentiate it from ties in voting results.
Under L<PrefVote::Core> this flag defaults to false.
Voting methods which need to set it to default true, such as L<PrefVote::Schulze>, must override the method to do so.

=item choice_exists(str)

returns true if the string parameter is a valid choice/candidate identifier string as configured for this vote.
This is used for validating choices during ballot input processing.

=item get_choices()

returns a list of choice/candidate identifier strings for the current vote.

=item save_ranking(ballot)

is called by submit_ballot() to record the rankings of an individual ballot.
The ballot parameter is a list of strings (not an array reference) with choice/candidate identifier strings.

=item average_ranking(choice)

returns the average choice rank (ACR) for a choice/candidate.
This is the average of all the ballot positions where this choice/candidate occurred on ballots,
where 1 is first place, 2 is second place and so on.
The choice parameter is a choice/candidate identifier string.

In voting methods which allow tied input rankings, such as Schulze, all tied choices/candidates will be recorded
with the same number from ballots where input ties occur.

=item gen_choice_hex()

is used by I<PrefVote::Core> during initialization to generate the lookup tables choice_to_index and index_to_choice
to convert both directions between choice/candidate identifier strings and a sequential hexadecimal number to use
as their hash index abbreviations.

The hexadecimal index is also in ballot combination index strings by concatenating them
sequentially in ballot order.

=item ballot_to_hex(@ballot)

receives a ballot combination as an array of strings
and converts it to a hex index string by concatenating the hexadecimal codes for the choices/candidates
in ballot order.
For voting methods which allow ties input rankings, such as Schulze, square brackets enclose the tied items,
listed in ascending order to ensure uniqueness and matching when compared.

This is called by submit_ballot().

=item submit_ballot(@ballot)

receives a ballot as an array of strings and stores it for later counting after all have been received.

It throws exceptions if the ballot has content errors.
Exceptions should be caught and considered rejected ballots which have not been stored for counting.
Exceptions only reject the ballot and should not be fatal for the program.
Errors which result in exceptions are as follows:

=over 1

=item an empty ballot

=item a ballot input tie is given in a voting method which doesn't accept them

=back

=item ingest_ballots

is called by yaml2vote() after it instantiates an object of I<PrefVote::Core> or a derivative class.
This reads the 2nd YAML document in the input, which contains a list of ballots to be counted.

=item count()

counts votes in the I<PrefVote::Core> object.

The count() method must be overridden in each class derived from I<PrefVote::Core>.

In I<PrefVote::Core> this method is only for testing purposes because it isn't a valid voting method.
The voting method must be provided by a derived class specifically written to handle them.
Since I<PrefVote::Core> contains average ballot positions of each candidate, that data is used f or testing
purposes.
But average ballot position doesn't take quantity votes into account,
which must be used in the first pass of any valid voting method.

An example of what could easily go wrong if I<PrefVote::Core> was used to count real ranked-choice ballots
is if a choice/candidate was ranked first place on one or few ballots, leaving a high average rank
even with few votes in favor.

=item save_c2r(winners => [wlist], eliminated => [elist])

is a method which must be called by subclasses of I<PrefVote::Core> to record their voting results.
The I<winners> parmeter is required, and must contain a list in order from first place to last of the winning
choices/candidates by their identifier strings.
The I<eliminated> parameter is optional,
provided only by voting methods whose definition includes elimination of candidates
such as Single Transferable Vote (STV).

save_c2r() uses the I<winners> and I<eliminated> to populate the I<choice_to_result> hash attribute withs
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

I<PrefVote::Core> makes average choice rank (ACR) data available to subclasses which must use it for tie-breaking,
except when the I<no-tiebreak> configuration flag is set.
Ties should be extremely unlikely with ACR tie-breaking enabled.

=item result_yaml()

returns a summary of this I<PrefVote::Core> or derivative object which is suitable to hand off to YAML::Dump()
to generate YAML output of the results.

It is called by the I<format_output()> method if the format "yaml" is specified.
The data returned is too detailed and technical for display to users or voters.
The output is intended to be processed by another program supplied by the developer whose code called this.

=item format_output(format)

uses the I<format> parameter to determine the function to call for output formatting.

=over 1

=item yaml

calls L<YAML::XS> I<Dump()> using the output of the I<result_yaml()> method.
This detailed data is intended for use by an external program provided by a developer.

=item rawyaml

calls L<YAML::XS> I<Dump()> using this object.
This is intended for testing only, and is used to create black box testing baseline data from the current run.

=item others

delegates output formatting to the appropriate subclass of L<PrefVote::Core::Output> named by the parameter.
Currently supported formats are Text, Markdown, HTML and rawcapture.
The "rawcapture" format is intended for testing.
The others are intended for human-readable display.

To add new formats, a new subclass of L<PrefVote::Core::Output> must be created to handle it.

=back

=item blackbox_check()

initiates a black-box test run by calling the I<check()> method on the I<testspec> attribute,
which is an instance of L<PrefVote::Core::TestSpec>.
It passes the current object as a parameter to I<check()>.

It builds a test tree by querying metadata about testable subclasses of L<PrefVote>,
which are those that stored their test trees via the I<register_blackbox_spec()> class method.
Each node in the test tree corresponds to an attribute in that class' objects.
A test is generated comparing the node's value with a value from a previous run stored in the
YAML input data's 3rd document.

If there is no 3rd document data in the YAML file, then black-box testing is skipped.

It returns a test tree which may be run by L<Test::More>.
The L<vote-count> script performs that task when given the I<--test> command-line option.

=back

=head1 FUNCTIONS

=over 1

=item supported_method(method)

returns true if the method string passed as a parameter matches any of the supported voting methods.
The matching is not case-sensitive.

=item read_yaml(filepath)

uses the I<filepath> parameter as a string with the filename of a YAML file to read and parse.
It returns a list of the parsed YAML document structures found in that file.

This function throws exceptions if the filepath names a file which doesn't exist or is not a regular file.
It also throws an exception if the content of that file can't be parsed by L<YAML::XS>.

=item determine_method({key => value, ...}, votedef)

determines which class will handle the vote counting and processing.
It returns the name of a class which is either L<PrefVote::Core> or a subclass of it.
The votedef parameter comes from the YAML input file first parsed YAML document.
It must contain a I<method> attribute which contains a space-delimeted string of one or more voting method names,
which are all the voting methods allowed/supported for this YAML data file.
Usually only one would be specified, whichever was defined for the vote.
For testing more than one is useful to test the same data on multiple ranked-choice voting methods.

The optional key/value parameters currently only support a key of "method" and a voting method to select.
The method parameter is required if the votedef structure allows more than one voting method,
in order to select which one to use.

Currently supported voting methods are Core (testing only), STV, Schulze and RankedPairs.
New voting methods can be implemented by adding a new subclass of L<PrefVote::Core>.

=item yaml2vote({key => value, ...}, filepath)

reads a YAML input file and constructs an object of I<PrefVote::Core>
or the appropriate subclass to handle the selected voting method.

It takes a file path as a parameter.
Optionally a hash reference may be provided inserted as the first option in order to provide
key/value configuration options.
The options are passed to determine_method() so the only currently supported option is "method",
which must be provided if the YAML data allows more that one type of voting method on the data.
It determines which voting method to use on this run.

The scenario of a vote definition supporting more than one type of voting method is mainly for testing,
where black-box tests may run the same ranked-chocie ballot data through multiple voting methods, one at a time.

=item result_node(node)

=back

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
