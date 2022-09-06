# PrefVote::Core::Ballot
# ABSTRACT: ballot structure for PrefVote voting system classes
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Ballot;

use autodie;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core::TestSpec;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(ArrayRef);
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
    items    => [qw(list set string)],
    quantity => [qw(int)],
    hex_id   => [qw(string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__, spec => \%blackbox_spec );

# per-ballot array of vote items
# Each item is a Set type to allow for voting methods which allow ballot-input ties. But not all do.
# PrefVote::Core class method ballot_input_ties_policy() defaults to false. Override it to true to enable ballot ties.
has items => (
    is         => 'ro',
    isa        => ArrayRef [ Set [NonEmptySimpleStr] ],
    required   => 1,
    constraint => sub {

        # if %choices is non-empty, use it to look up valid values in ballot items
        my $items_ref = $_;
        if (%choices) {
            foreach my $item (@$items_ref) {
                if ( not exists $choices{$item} ) {
                    return 0;
                }
            }
        }
        return 1;
    },
);

# quantity is a multiplier for the number of times this combination of items has occurred
has quantity => (
    is       => 'rw',
    isa      => PositiveInt,
    required => 1,
);

# hexadecimal identifier string used to cross-check hash lookups from PrefVote::Core
has hex_id => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

# Ballot-input ties, where a voter casts a ranked choice ballot with two or more choices as equals, are not allowed
# by default. Voting methods which allow it should override PrefVote::Core's ballot_input_ties_policy() class method,
# replacing it with one that returns true. That will be used by PrefVote::Core initialization to set this flag.
# This function acts as a read/write accessor to the file-scoped ballot-input tie flag, which defaults to false.
# For example, Single Transferable Vote (STV) does not allow ballot-input ties. The Schulze Method does allow them.
# This flag only exists in this class to avoid a cicrular dependency with PrefVote::Core - if this class queried
# PrefVote::Core for the flag then this class would depend on it. So it provides the flag to this class at startup.
sub ballot_input_ties_flag
{
    my $value = shift;
    if ( defined $value ) {
        $ballot_input_ties_flag = ( $value ? 1 : 0 );
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
    return wantarray ? ( keys %choices ) : \%choices;
}

# enforce ballot-input ties only allowed when ballot_input_ties_flag() is true
sub enforce_ballot_item_ties
{
    my $item_set = shift;
    if ( ref $item_set ne "Set::Tiny" ) {
        PrefVote::Core::InternalDataException->throw(
            classname   => __PACKAGE__,
            attribute   => "ballot item",
            description => "ballot item is not a ref to Set::Tiny"
        );
    }
    if ( $item_set->is_empty() ) {
        PrefVote::Core::InternalDataException->throw(
            classname   => __PACKAGE__,
            attribute   => "ballot item",
            description => "bad data: ballot item set is empty"
        );
    }
    return if ballot_input_ties_flag();    # no further checks if ballot-item ties are allowed
    if ( $item_set->size() > 1 ) {
        PrefVote::Core::InternalDataException->throw(
            classname   => __PACKAGE__,
            attribute   => "ballot item",
            description => "ballot item set has more than one item in voting method that doesn't support input ties"
        );
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
    foreach my $item ( @{ $self->{items} } ) {
        enforce_ballot_item_ties($item);
        if ( $item->size() > 1 and ballot_input_ties_flag() ) {
            push @result, set( $item->elements() );
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
    my $self      = shift;
    my $separator = shift;
    my @result;
    foreach my $item ( @{ $self->{items} } ) {
        enforce_ballot_item_ties($item);
        if ( $item->size() > 1 ) {
            push @result, join( "/", sort $item->elements() );
        } else {
            push @result, $item->elements();
        }
    }
    return join( $separator, @result );
}

# return a count of ballot choices - including totals for ballot-item sets with ties of more than one choice.
# If ballot_input_ties_flag() is false then enforce one item per ballot-item set - throw an exception otherwise.
sub items_count
{
    my $self  = shift;
    my $total = 0;
    foreach my $item ( @{ $self->{items} } ) {
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
=encoding utf8

=head1 SYNOPSIS

As used by PrefVote::Core:

    use PrefVote::Core::Ballot;
    
    # before instantiating any ballot objects - this is done by PrefVote::Core
    PrefVote::Core::Ballot::set_choices(@keys);
    PrefVote::Core::Ballot::ballot_input_ties_flag($flag);

    # instantiating a new ballot - this is done by PrefVote::Core
    $ballot = PrefVote::Core::Ballot->new(items => \@filtered_ballot, hex_id => $hex_id, quantity => 1);

As used by PrefVote::STV, demonstrating use by voting method classes:

    use Moo;
    # ...
    extends 'PrefVote::Core';

    foreach my $combo ($self->ballots_keys()) {
        my $ballot = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();
        # count votes based on contents of @ballot_items
    }

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Ballot encapsulates the data of a ballot, listing a voter's choices as items in order of
decreasing preference. Ballots with the same combination of choices in the same order are aggregated by
incrementing the quantity attribute rather than creating a duplicate ballot record.

PrefVote::Core stores ranked-choice ballots as the base class for multiple voting methods.

=head1 ATTRIBUTES

=over 1

=item items : ArrayRef[Set[string]]

This is an array of sets of non-empty strings.
The strings contained in it are the voter's choices from their ballot, in order of decreasing preference.
Though sets may have more than one entry, that is only used on voting methods which allow ballot-input ties,
i.e. allowing voters to cast the same preference for more than one candidate and treating them as equals.
Voting methods which allow ballot-input ties will have more than one entry in a set when multiple entries are
considered equal in their place in the order of preference.

=item quantity : integer

This is a multiplier on the ballot combination, indicating how many times this specific combination occurred.

=item hex_id : string

This is a unique string used as a hash key for the ballot.
It is generated from one or more hexadecimal digits indicating the position
of each candidate from the table of contents for the race.

In voting methods that allow ballot-input ties, hexadecimal codes for equal candidates are shown between
square brackets. Though the order isn't significant for equal choices, the hex codes are sorted within the brackets
in order to maintain consistent results for search matching and testing.

=back

=head1 METHODS

=over 1

=item items_all

This returns a list of all the choices on the ballot in order of decreasing preference.
This is only for display.
It isn't sufficient for counting because this list loses the information about ballot-input ties.

=item items_join ( $separator )

This returns a string with the ballot choices concatenated with the $separator between them.
(See join in L<perlfunc>.)
If there are ballot-input ties on the ballot, those entries are joined by a slash "/" separator before entering the
bigger join to show result order correctly.

=item items_count

This returns the number of items on the ballot. It takes ballot-input ties into account and returns the total items
across all places in the ballot.

=item increment

This increments the count on the ballot.
It is called by PrefVote::Core when submit_ballot() receives a ballot of the same combination as an existing one.
This should not be called from voting method subclasses.

=item as_string

This returns a string representing the ballot, formed by the items_join() method with a space for the separator.

=back

=head1 FUNCTIONS

=over 1

=item set_choices

This function is called by PrefVote::Core during initialization and should not be used elsewhere.
It establishes the list of choices available to vote for.

=item get_choices

This returns a list of the string identifiers for the available voting choices.
Order is not significant here - it's a list of hash keys.

=back

=head1 SEE ALSO

L<PrefVote>, L<Moo>, L<Set::Tiny>

L<https://github.com/ikluft/prefvote>


=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
