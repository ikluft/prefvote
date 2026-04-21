# PrefVote::KR2::PairData
# ABSTRACT: internal candidate-pair data for Kluft Rank-Rate KR2 method
# Copyright (c) 2022-2026 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::KR2::PairData;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Common qw(Bool Int PositiveOrZeroInt IntRange);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core::PairData';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    mov  => [qw(int)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core::PairData'
);

# margin of victory (0 for tie)
has mov => (
    is  => 'rw',
    isa => Int,
);

# read accessor for margin of victory (mov)
# if non-existent, return zero without creating the attribute
sub get_mov
{
    my $self = shift;
    return $self->{mov} // 0;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

use PrefVote::KR2::PairData;
my $pairdata_ref = PrefVote::KR2::PairData->new();

$pairdata_ref->add_preference(1);
my $count = $pairdata_ref->preference();

$pairdata_ref->mov(10);
my $mov = $pairdata_ref->mov();

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

A PrefVote::KR2:PairData object contains data pertaining to a pair of candidates.
Outside the scope of this class, L<PrefVote::KR2> has a sparse table (two-level hash) of the
candidates being compared: candidate 1 (represented by the outer hash) and candidate 2 (inner hash).
An instance of this object is contained within each entry of that table.

=head1 ATTRIBUTES

Attributes include accessor methods of the same name. With no parameter, it gets the value.
With a parameter it sets the value.

=over 1

=item preference

This is inherited from PrefVote::Core::PairData.

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

=back

=head1 METHODS

=over 1

=item add_preference(n)

This is inherited from PrefVote::Core::PairData.

This method adds n votes to the tally in the preference attribute, first initializing it to zero if it didn't exist.

=item get_mov()

This reads the mov (margin of victory) attribute.
If it isn't defined, this method returns zero and leaves the attribute undefined.
By using this method, the mov attribute should only exist if a value has been set,
and is not set by a side-effect of reading it.

=back

=head1 SEE ALSO

L<PrefVote::KR2>, L<PrefVote::Core::PairData>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
