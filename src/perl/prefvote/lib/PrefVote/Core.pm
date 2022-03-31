# PrefVote::Core
# ABSTRACT: common code for all PrefVote voting methods
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
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
use PrefVote::Core::InternalDataException;
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
sub class_or_obj
{
    my $coo = shift;
    if (not $coo->isa(__PACKAGE__)) {
        PrefVote::Core::Exception->throw(description => "class_or_obj: parameter not in class hierarchy"
            .((ref $coo) ? ref $coo : $coo));
    }
    if (ref $coo) {
        return $coo;
    }
    return $coo->instance();
}

# get class suffix
sub suffix
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);
    my $class_suffix = ref $self;
    $class_suffix =~ s/^.*:://x; # remove everything except the last part of the class name
    return $class_suffix;
}

# check existence of a voting choice/option
sub choice_exists
{
    my ($class_or_obj, $str) = @_;
    return 0 if not defined $str;
    my $self = class_or_obj($class_or_obj);
    return $self->choices_exists($str) ? 1 : 0;
}

# get list of choices
sub get_choices
{
    my $class_or_obj = shift;
    my $self = class_or_obj($class_or_obj);
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
    my $suffix = $self->suffix();
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

=head1 ATTRIBUTES

=over 1

=back

=head1 METHODS

=over 1

=back

=head1 FUNCTIONS

=over 1

=back

=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
