# PrefVote::RankedPairs::PairData
# ABSTRACT: internal candidate-pair data for Ranked Pairs method
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs::PairData;

use autodie;
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Int);
use Types::Common::Numeric qw(PositiveOrZeroInt IntRange);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# constants for lock attribute
Readonly::Scalar my $no_lock => 0;
Readonly::Scalar my $direct_lock => 1;
Readonly::Scalar my $indirect_lock => 2;

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    preference => [qw(int)],
    mov => [qw(int)],
    lock => [qw(int)],
);

# preference: total votes showing preference of candidate i over j
# optional - should return 0 if nonexistent
has preference => (
    is => 'rw',
    isa => PositiveOrZeroInt,
);

# margin of victory (0 for tie)
has mov => (
    is => 'rw',
    isa => Int,
);

# flag: the pair is locked
has lock => (
    is => 'rw',
    isa => IntRange[$no_lock, $indirect_lock],
);

# add to pair node's preference total
sub add_preference
{
    my $self = shift;
    my $quantity = shift;

    # add to total
    my $total = $quantity + ($self->preference() // 0);
    $self->preference($total);
    return $total;
}

# read accessor for margin of victory (mov)
# if non-existent, return zero without creating the attribute
sub get_mov
{
    my $self = shift;
    return $self->{mov} // 0;
}

# set direct lock
sub set_direct_lock
{
    my $self = shift;
    $self->lock($direct_lock);
    return;
}

# set indirect_lock
sub set_indirect_lock
{
    my $self = shift;
    return if $self->get_lock() == $direct_lock; # skip: already has a higher lock
    $self->lock($indirect_lock);
    return;
}

# read lock flag
# if non-existent, return zero without creating the attribute
sub get_lock
{
    my $self = shift;
    return $self->{lock} // $no_lock;
}

# check if a direct lock exists
sub is_direct_lock
{
    my $self = shift;
    return $self->get_lock() == $direct_lock;

}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::RankedPairs:PairData - internal candidate-pair data for RankedPairs method

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
