# PrefVote::Core::PairData
# ABSTRACT: internal candidate-pair data in common for all Condorcet methods
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::PairData;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Common qw(Bool Int PositiveOrZeroInt IntRange);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => ( preference => [qw(int)], );

# preference: total votes showing preference of candidate i over j
# optional - should return 0 if nonexistent
has preference => (
    is  => 'rw',
    isa => PositiveOrZeroInt,
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

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

  use PrefVote::Core::PairData;
  my $pairdata_ref = PrefVote::Core::PairData->new();

  $pairdata_ref->add_preference(1);
  my $count = $pairdata_ref->preference();

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

A PrefVote::Core:PairData object contains data pertaining to a pair of candidates.
It serves as a base class for more specific PairData classes in Condorcet voting methods.
Outside the scope of this class, L<PrefVote::Core::PairMatrix> has a sparse table (two-level hash) of the
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

=back

=head1 METHODS

=over 1

=item add_preference(n)

This method adds n votes to the tally in the preference attribute, first initializing it to zero if it didn't exist.

=back

=head1 SEE ALSO

L<PrefVote::Core::PairMatrix>, L<PrefVote::Schulze::PairData>, L<PrefVote::RankedPairs::PairData>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

