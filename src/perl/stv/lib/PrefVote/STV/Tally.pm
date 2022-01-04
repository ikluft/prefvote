# PrefVote::STV::Tally
# ABSTRACT: internal per-round candidate tally structure used by PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# STV candidate record within each round
#
package PrefVote::STV::Tally;

use autodie;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Bool Int StrictNum Str ArrayRef);
extends 'PrefVote';

# candidate name (identifier string)
has 'name' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# candidate vote total
has votes => (
    is => 'rw',
    isa => StrictNum,
    default => 0,
);

# flag: winner of current or previous round (exclude from later rounds)
has winner => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

# flag: eliminated in current or previous round (exclude from later rounds)
has eliminated => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

# result: finished in nth place
has place => (
    is => 'rw',
    isa => Int,
    default => 0,
);

# total votes available for transfer
has transfer => (
    is => 'rw',
    isa => StrictNum,
    default => 0,
);

# fraction of votes which exceed the quota needed to win, and are available for transfer
has surplus => (
    is => 'rw',
    isa => StrictNum,
    default => 0,
);

# mark candidate as a winner
# if there is a tie, call this once per winning candidate
sub mark_as_winner
{
    my ($self, %opts) = @_;
    $self->winner(1);
    foreach my $key (qw(place votes surplus transfer)) {
        if (exists $opts{$key}) {
            $self->$key($opts{$key});
        }
    }
    return;
}

# mark candidate as eliminated
sub mark_as_eliminated
{
    my $self = shift;
    $self->eliminated(1);
    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Tally - internal per-round candidate tally structure used by PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
