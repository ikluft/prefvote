# PrefVote::RankedPairs::Majority
# ABSTRACT: internal pairwise majority structure for Ranked Pairs method
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs::Majority;

use autodie;
use Data::Dumper;
use Readonly;
use overload
    '<=>' => \&cmp_pair,
    '""'  => \&stringify;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(ArrayRef);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => ( cand => [qw(list string)], );

# candidates paired either as winner-loser or alphabetical for ties
has cand => (
    is          => 'ro',
    isa         => ArrayRef [ NonEmptySimpleStr, 2, 2 ],
    required    => 1,
    handles_via => 'Array',
    handles     => {
        cand_all  => 'all',
        cand_join => 'join',
    },
);

# get candidates in the pair
sub cands
{
    my $self = shift;
    return @{ $self->cand() };
}

# comparison function for sorting PrefVote::RankedPairs::Majority elements by margin of victory (mov)
sub cmp_pair
{
    my ( $self, $other, $swap ) = @_;

    # make sure both elements in the comparison are of this package's type, or a subclass
    if ( not $other->isa(__PACKAGE__) ) {
        PrefVote::Core::Exception->throw( description => "majority comparison type mismatch" );
    }

    # pairs in comparison must be swapped if $swap flag is on
    my ( $pair1, $pair2 ) =
        $swap ? ( $self->{cand}, $other->{cand} ) : ( $other->{cand}, $self->{cand} );

    # compare for sorting margin of victory in descending order
    my $rp_obj = PrefVote::RankedPairs->instance();
    my $mov1   = $rp_obj->get_mov(@$pair1);
    my $mov2   = $rp_obj->get_mov(@$pair2);
    if ( $mov1 != $mov2 ) {
        return $mov1 <=> $mov2;
    }

    # if margin of victory was equal, secondary comparison is for lesser opposition (ascending order)
    my $oppose1 = $rp_obj->get_preference( reverse @$pair1 );
    my $oppose2 = $rp_obj->get_preference( reverse @$pair2 );
    return $oppose2 <=> $oppose1;
}

# convert to string
sub stringify
{
    my $self = shift;
    return $self->cand_join('>');
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

my $majority_ref = PrefVote::RankedPairs::Majority->new(cand => \@pair);

my @majority_elements = $majority_ref->cand_all();
my $str = majority_ref->stringify();

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

A PrefVote::RankedPairs::Majority object contains two strings representing a pair of choices/candidates
in a L<PrefVote::RankedPairs> vote. The Ranked Pairs algorithm sorts (ranks) candidate pairs (majorities)
by the strength of the margin of victory between them.
PrefVote::RankedPairs tracks those pairs with an array of PrefVote::RankedPairs::Majority objects,
which is sorts using margin of victory (mov) data from PrefVote::RankedPairs::PairData objects 
which were populated during vote counting.

=head1 ATTRIBUTES

=over 1

=item cand

Array of 2 strings which contains the names of the two choices/candidates naming a pairwise comparison.

=back

=head1 METHODS

=over 1

=item cands()

Returns an array of strings with the names of the 2 choices/candidates in this pair.

=item cmp_pair()

Performs a comparison of the canididates in the pair and, like the <=> operator,
returns 1, 0 or -1 if candidate 1 beats, ties or loses to candidate 2.

=item stringify()

Returns a string with the two canididate names in the pair, joined by a greater-than sign ">" between them.

=back

=head1 SEE ALSO

L<PrefVote::RankedPairs>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
