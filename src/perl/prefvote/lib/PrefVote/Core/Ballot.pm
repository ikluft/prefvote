# PrefVote::Core::Ballot
# ABSTRACT: ballot structure for PrefVote voting system classes
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
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

# class definitions
use Moo;
use MooX::HandlesVia;
use Type::Tiny;
use Types::Standard qw(Str ArrayRef);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote';

# set of valid ballot choices submitted by PrefVote::Core
# separate copy here avoids dependency loop and helps testing the module alone
my %choices;

# per-ballot array of vote items
has items => (
    is => 'ro',
    isa => ArrayRef[Str],
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
    handles_via => 'Array',
    handles => {
        items_all => 'all',
        items_join => 'join',
        items_count => 'count',
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
