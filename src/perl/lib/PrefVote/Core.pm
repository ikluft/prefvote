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
use PrefVote::Core::Ballot;

#
# class definitions
#
use Moo;
use Type::Tiny;
use Types::Standard qw(Str Int ArrayRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveInt);
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
        $self->debug_print("set choices to ".join(" ", keys %{$self->choices})."\n");
    },
);

# number of seats/selections to be filled by poll/vote
has seats => (
    is => 'ro',
    isa => PositiveInt,
    default => sub { return 1 },
);

# poll/vote end time
has end_time => (
    is => 'ro',
    isa => InstanceOf["DateTime"],
    required => 0,
);

# array of ballots
has ballots => (
    is => 'rw',
    isa => ArrayRef[InstanceOf["PrefVote::Core::Ballot"]],
    default => sub { return [] },
);

# check existence of a voting choice/option
# class method
sub choice_exists
{
    my $class = shift;
    my $str = shift;
    my $self = $class->instance();
    my $choices_ref = $self->choices;
    return exists $choices_ref->{$str};
}

# get list of choices
sub get_choices
{
    my $class_or_obj = shift;
    my $self = ($class_or_obj->isa("PrefVote::Core")) ? $class_or_obj : $class_or_obj->instance();
    return keys %{$self->{choices}};
}

# get ballot count
sub count_ballots
{
    my $class_or_obj = shift;
    my $self = ($class_or_obj->isa("PrefVote::Core")) ? $class_or_obj : $class_or_obj->instance();
    my $ballots_ref = $self->ballots();
    return scalar @$ballots_ref;
}

#
# data input
#

# submit a ballot - just store it, do not count yet
# exceptions: ballot content errors
sub submit_ballot
{
    my ($self, @ballot) = @_;

    # Note: ballots are anonymous once this function is called.
    # Protection against casting multiple votes must be done elsewhere
    # (preferably when the vote is received) because this module doesn't
    # retain any association between the ballot and the voter.
    my $ballot = PrefVote::Core::Ballot->new($self, items => \@ballot); # throws exception on content error
    $self->debug_print("accepting ", $ballot->as_string(), "\n");
    push ( @{$self->{ballots}}, $ballot );
    return;
}

# return string of ballot contents
sub as_string
{
    my $self = shift;
    return join " ", @{$self->items()};
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
