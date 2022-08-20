# PrefVote::RankedPairs::PairData
# ABSTRACT: internal candidate-pair data for Ranked Pairs method
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs::PairData;

use autodie;
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Bool Int);
use Types::Common::Numeric qw(PositiveOrZeroInt IntRange);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    preference => [qw(int)],
    mov        => [qw(int)],
    lock       => [qw(int)],
);

# preference: total votes showing preference of candidate i over j
# optional - should return 0 if nonexistent
has preference => (
    is  => 'rw',
    isa => PositiveOrZeroInt,
);

# margin of victory (0 for tie)
has mov => (
    is  => 'rw',
    isa => Int,
);

# flag: the pair is locked
has lock => (
    is  => 'rw',
    isa => Bool,
);

# add to pair node's preference total
sub add_preference
{
    my $self     = shift;
    my $quantity = shift;

    # add to total
    my $total = $quantity + ( $self->preference() // 0 );
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

# set lock
sub set_lock
{
    my $self = shift;
    $self->lock(1);
    return;
}

# read lock flag
# if non-existent, return zero without creating the attribute
sub get_lock
{
    my $self = shift;
    return $self->{lock} // 0;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

use PrefVote::RankedPairs::PairData;
my $pairdata_ref = PrefVote::RankedPairs::PairData->new();

$pairdata_ref->add_preference(1);
my $count = $pairdata_ref->preference();

$pairdata_ref->mov(10);
my $mov = $pairdata_ref->mov();

$pairdata_ref->set_lock();
my $locked = $pairdata_ref->get_lock();

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

A PrefVote::RankedPairs:PairData object contains data pertaining to a pair of candidates.
Outside the scope of this object, L<PrefVote::RankedPairs> has a sparse table (two-level hash) of the
candidates being compared: candidate 1 (represented by the outer hash) and candidate 2 (inner hash).
An instance of this object is contained within each entry of that table.

=head1 ATTRIBUTES

Attributes include accessor methods of the same name. With no parameter, it gets the value.
With a parameter it sets the value.

=over 1

=item preference

Integer tally of the votes cast which favor Candidate 1 over Candidate 2.
It does not contain votes the opposite direction, Candidate 2 over Candidate 1.
If those votes exist, they are tallied in the appropriate cell in the table
for Candidate 2 against Candidate 1, the opposite order of this cell.

See "mov" for the result of subtracting Candidate 2's preference from Candidate 1's.

=item mov

Margin of victory is the result after subtracting Candidate 2's preference votes from Candidate 1's.
If Candidate 1 is more preferred, then this number is positive.
If Candidate 2 is more preferred, then this is negative.
In a tie, the number is zero (0).

=item lock

This is a boolean flag which, if true, indicates the comparison of Candidate 1 to Candidate 2 has been locked
for inclusion in the final results.
A pair is locked by the Ranked Pairs method when the comparison is a win (positive margin of victory)
and does not conflict with candidate pairs with larger margins of victory.

=back

=head1 METHODS

=over 1

=item add_preference(n)

This method adds n votes to the tally in the preference attribute, first initializing it to zero if it didn't exist.

=item get_mov()

This reads the mov (margin of victory) attribute.
If it isn't defined, this method returns zero and leaves the attribute undefined.
By using this method, the mov attribute should only exist if a value has been set,
and is not set by a side-effect of reading it.

=item set_lock()

This sets the lock flag true.

=item get_lock()

This reads the lock flag attribute.
If it isn't defined, this method returns false (zero) and leaves the attribute undefined.
By using this method, the flag should only exist if set to true, and is not set by a side-effect of reading it.

=back

=head1 SEE ALSO

L<PrefVote::RankedPairs>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
