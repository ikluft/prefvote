# PrefVote::Core
# ABSTRACT: core code for all PrefVote voting methods
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
use Carp qw(croak);
use DateTime;
use Readonly;
use Scalar::Util 'reftype';
use YAML::XS;
use PrefVote::Core::Ballot;
use PrefVote::Core::Exception;              # pre-load in case exception is thrown
use PrefVote::Core::InternalDataException;   # pre-load in case exception is thrown
use PrefVote::Core::TestSpec;

# supported voting methods - for constructing class names from vote definitions
# use Core only for testing because the base class doesn't actually have voting-method code
Readonly::Array my @voting_methods => qw(Core STV Schulze);

#
# class definitions
#
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Str Int ArrayRef HashRef Map InstanceOf Any);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote';
with 'MooX::Singleton';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    name => [qw(string)],
    choice_to_index => [qw(hash string)],
    index_to_choice => [qw(hash string)],
    choices => [qw(hash string)],
    seats => [qw(int)],
    ballots => [qw(hash PrefVote::Core::Ballot)],
    total_ballots => [qw(int)],
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

# strings identifying poll/vote choices
has choices => (
    is => 'ro',
    isa => HashRef[NonEmptySimpleStr],
    requred => 1,
    trigger => sub {
        my $self = shift;
        $self->debug_print("set choices to ".join(" ", $self->choices_keys()));
        $self->gen_choice_hex();
        PrefVote::Core::Ballot::set_choices($self->choices_keys());
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

# blackbox testing checklist structure
# this is filled from the extra data from YAML input file, used for testing all PrefVote language implementations
has testspec => (
    is => 'ro',
    isa => InstanceOf["PrefVote::Core::TestSpec"],
    required => 0,
);

# utility for functions to select between class and object
sub class_or_obj
{
    my $coo = shift;
    if (not $coo->isa(__PACKAGE__)) {
        croak "class_or_obj: parameter not in class hierarchy".((ref $coo) ? ref $coo : $coo);
    }
    if (ref $coo) {
        return $coo;
    }
    return $coo->instance();
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
        if ($method eq $supported) {
            return 1;
        }
    }
    return 0;
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
    foreach my $item (@ballot) {
        if ($self->c2i_exists($item)) {
            $hex_id .= $self->c2i_get($item);
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
        if ($self->choice_exists($item)) {
            push @filtered_ballot, $item;
        }
    }

    # throw exception for empty ballot after filtering
    if ((scalar @filtered_ballot) == 0) {
        PrefVote::Core::Exception->throw(description => "empty ballot");
    }

    # Note: ballots are anonymous once this function is called.
    # Protection against casting multiple votes must be done elsewhere
    # (preferably when the vote is received) because this module doesn't
    # retain any association between the ballot and the voter.

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
    (-e $filepath) or croak "$filepath not found";
    (-f $filepath) or croak "$filepath not a regular file";
    my @yaml_docs = eval { YAML::XS::LoadFile($filepath) };
    if ($@) {
        croak "$0: error reading $filepath: $@";
    }
    return @yaml_docs;
}

# convert YAML input to PrefVote::Core structure and ballots
sub yaml2vote
{
    my $filepath = shift;
    my @yaml_docs = read_yaml($filepath);

    # save the first YAML document as the definition of the vote for entry into a PrefVote::Core structure
    my $yaml_vote_def = shift @yaml_docs;
    if (ref $yaml_vote_def ne "HASH") {
        croak "$0: misformatted YAML input: 1st document must be in map/hash format";
    }
    foreach my $key ( qw(method params)) {
        if (not exists $yaml_vote_def->{$key}) {
            croak "$0: misformatted YAML input: '$key' parameter missing from top level of vote definition";
        }
    }

    # save the second YAML document as the list of ballots
    my $yaml_ballots = shift @yaml_docs;
    if (ref $yaml_ballots ne "ARRAY") {
        croak "$0: misformatted YAML input: 2nd document must be in list/array format";
    }

    # save any additional YAML documents in extra, available for testing
    my $extra_data = [@yaml_docs];

    # translate a voting method string into a voting-method class within this hierarchy
    # instantiate the voting object from 1st YAML document
    my $method = $yaml_vote_def->{method};
    if (not supported_method($method)) {
        croak "$method is not a supported voting method";
    }
    my $class = "PrefVote::$method";
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    if (not eval "require $class") {
        croak "failed to load class $class: $@";
    }
    ## critic (BuiltinFunctions::ProhibitStringyEval)
    if (not $class->isa(__PACKAGE__)) {
        croak "class $class in vote defintion is not a subclass of ".__PACKAGE__;
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
        croak "failed to instantiate object of $class: $@";
    }

    # ingest ballots from 2nd YAML document
    my $submitted = 0;
    my $accepted = 0;
    foreach my $ballot (@$yaml_ballots) {
        $submitted++;
        if ( eval { $vote_obj->submit_ballot(@$ballot) }) {
            $accepted++;
        } else {
            $vote_obj->debug_print("ballot entry failed: $@");
        }
    }
    $vote_obj->debug_print("votes: submitted=$submitted accepted=$accepted");

    return $vote_obj;
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
    return $result_out;
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

=head1 NAME

PrefVote::Core - core code for all PrefVote voting methods

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


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
