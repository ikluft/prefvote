# PrefVote::Core
# ABSTRACT: core code for all PrefVote voting methods
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
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
use PrefVote::Core::Ballot;
use PrefVote::Core::Exception;              # pre-load in case exception is thrown
use PrefVote::Core::InternalDataException;   # pre-load in case exception is thrown

# supported voting methods - for constructing class names from vote definitions
# use Core only for testing because the base class doesn't actually have voting-method code
Readonly::Array my @voting_methods => qw(Core STV Schulze);

#
# class definitions
#
use Moo;
use Type::Tiny;
use Types::Standard qw(Str Int ArrayRef HashRef Map InstanceOf Any);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt);
extends 'PrefVote';
with 'MooX::Singleton';

# name of poll/vote
has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# strings identifying poll/vote choices
has choices => (
    is => 'ro',
    isa => HashRef,
    requred => 1,
    trigger => sub {
        my $self = shift;
        $self->debug_print("set choices to ".join(" ", keys %{$self->choices}));
        PrefVote::Core::Ballot::set_choices(keys %{$self->choices});
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
    #isa => ArrayRef[InstanceOf["PrefVote::Core::Ballot"]],
    default => sub { return {} },
);

# count of total ballots
has total_ballots => (
    is => 'rw',
    isa => PositiveOrZeroInt,
    default => 0,
);

# misc additional info: storage for extra data from input file, used for testing
has extra => (
    is => 'ro',
    isa => Any,
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
    return (exists $self->{choices}{$str} ? 1 : 0);
}

# get list of choices
sub get_choices
{
    my $class_or_obj = shift;
    my $self = class_or_obj($class_or_obj);
    return keys %{$self->{choices}};
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
    my $combo = join " ", @filtered_ballot;

    # check if this combination already exists and increment it if it does, if not create/save new combo
    my $ballot;
    my $action;
    if (exists $self->{ballots}{$combo}) {
        $action = "increment";
        $ballot = $self->{ballots}{$combo};
        $ballot->increment();
    } else {
        $action = "new";
        $ballot = PrefVote::Core::Ballot->new(items => \@filtered_ballot, quantity => 1);
        $self->{ballots}{$combo} = $ballot;
    }
    $self->debug_print("accepting $action: ", $ballot->as_string());
    $self->{total_ballots}++;
    return $combo; # returns filtered combination, whose absence can be used to detect if an exception was thrown
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
    if ($extra_data) {
        # stash extra YAML documents in "extra" for use in testing
        $params->{extra} = $extra_data;
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

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core - core code for all PrefVote voting methods

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
