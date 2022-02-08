# PrefVote::Core::Ballot
# ABSTRACT: ballot structure for PrefVote voting system classes
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Ballot;

use autodie;
use Carp qw(croak);
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core::TestSpec;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Str ArrayRef);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::Set qw(Set);
extends 'PrefVote';

#
# file-scoped configuration variables submitted by PrefVote::Core
# A separate copy of this data here avoids a dependency loop and allows testing the module alone.
#

# set of valid ballot choices
my %choices;

# policy flag: allow ballot-input ties, defaults to false (Schulze sets it true)
my $ballot_input_ties_flag = 0;

#
# class definition
#

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    items => [qw(list set string)],
    quantity => [qw(int)],
    hex_id => [qw(string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec);
 
# per-ballot array of vote items
# Each item is a Set type to allow for voting methods which allow ballot-input ties. But not all do.
# PrefVote::Core class method ballot_input_ties_policy() defaults to false. Override it to true to enable ballot ties.
has items => (
    is => 'ro',
    isa => ArrayRef[Set[Str]],
    required => 1,
    constraint => sub {
        # if %choices is non-empty, use it to look up valid values in ballot items
        my $items_ref = $_;
        if (%choices) {
            foreach my $item (@$items_ref) {
                if (not exists $choices{$item}) {
                    return 0;
                }
            }
        }
        return 1;
    },
);

# quantity is a multiplier for the number of times this combination of items has occurred
has quantity => (
    is => 'rw',
    isa => PositiveInt,
    required => 1,
);

# hexadecimal identifier string used to cross-check hash lookups from PrefVote::Core
has hex_id => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    required => 1,
);

# ballot-input ties are not allowed by default. Voting methods which allow it should override this class method.
# this function acts as a read/write accessor to the file-scoped ballot-input tie flag, which defaults to false
# This should be set only from the voting method class based on its policy/definition on ballot-input ties.
# For example, Single Transferable Vote (STV) does not allow ballot-input ties. The Schulze Method does allow them.
sub ballot_input_ties_flag
{
    my $value = shift;
    if (defined $value) {
        $ballot_input_ties_flag = ($value ? 1 : 0)
    }
    return $ballot_input_ties_flag;
}

# set valid ballot choices in a class variable
# this allows testing separate from other classes
# under normal usage this is set once initially by PrefVote::Core
sub set_choices
{
    my @choices = @_;

    # put choices in class variable hash
    %choices = ();
    foreach my $item (@choices) {
        $choices{$item} = 1;
    }
    return;
}

# get list of choices
sub get_choices
{
    return wantarray ? (keys %choices) : \%choices;
}

# enforce ballot-input ties only allowed when ballot_input_ties_flag() is true
sub enforce_ballot_item_ties
{
    my $item_set = shift;
    if (ref $item_set ne "Set::Tiny") {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "ballot item",
            description => "ballot item is not a ref to Set::Tiny")
    }
    if ($item_set->is_empty()) {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "ballot item",
            description => "bad data: ballot item set is empty")
    }
    return if ballot_input_ties_flag(); # no further checks if ballot-item ties are allowed
    if ($item_set->size() > 1) {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "ballot item",
            description => "ballot item set has more than one item in voting method that doesn't support input ties")
    }
    return;
}

# return list of all items
# This is like returning all the entries in a list, except that each list entry is a set of potential input ties.
# If ballot_input_ties_flag() is false then enforce one item per ballot-item set - throw an exception otherwise.
sub items_all
{
    my $self = shift;
    my @result;
    foreach my $item (@{$self->{items}}) {
        enforce_ballot_item_ties($item);
        if ($item->size() > 1 and ballot_input_ties_flag()) {
            push @result, set($item->elements());
        } else {
            push @result, $item->elements();
        }
    }
    return @result;
}

# return a string of joined ballot-item entries
# This is does a join into a string after fetching all the sub-items from each ballot-item set.
# If ballot_input_ties_flag() is false then enforce one item per ballot-item set - throw an exception otherwise.
sub items_join
{
    my $self = shift;
    my $separator = shift;
    my @result;
    foreach my $item (@{$self->{items}}) {
        enforce_ballot_item_ties($item);
        if ($item->size() > 1) {
            push @result, join("/", sort $item->elements());
        } else {
            push @result, $item->elements();
        }
    }
    return join($separator, @result);
}

# return a count of ballot choices - including totals for ballot-item sets with ties of more than one choice.
# If ballot_input_ties_flag() is false then enforce one item per ballot-item set - throw an exception otherwise.
sub items_count
{
    my $self = shift;
    my $total = 0;
    foreach my $item (@{$self->{items}}) {
        $total += $item->size();
    }
    return $total;
}

# increment the quantity on this ballot record
sub increment
{
    my $self = shift;
    $self->{quantity}++;
    return;
}

# return string of ballot contents
sub as_string
{
    my $self = shift;
    return $self->items_join(" ");
}

1;


__END__

# POD documentation

=head1 NAME

PrefVote::Core::Ballot - ballot structure for PrefVote voting system classes

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
