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
use Type::Tiny;
use Types::Standard qw(Str ArrayRef);
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
    }
);

# set valid ballot choices
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

# return number of items on ballot
sub total_items
{
    my $self = shift;
    return scalar @{$self->{items}};
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

PrefVote::Core::Ballot - ballot structure for PrefVote voting system classes

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
