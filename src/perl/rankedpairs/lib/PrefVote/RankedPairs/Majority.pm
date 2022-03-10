# PrefVote::RankedPairs::Majority
# ABSTRACT: internal pairwise majority structure for Ranked Pairs method
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::RankedPairs::Majority;

use autodie;
use Data::Dumper;
use Readonly;
use overload
    '<=>' => \&pair_cmp;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Tuple);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    cand => [qw(array string)],
);

# candidates paired either as winner-loser or alphabetical for ties
has cand => (
    is => 'ro',
    isa => Tuple[NonEmptySimpleStr, NonEmptySimpleStr],
    required => 1,
);

# get candidates in the pair
sub cands
{
    my $self = shift;
    return @{$self->cand()};
}

# comparison function for sorting PrefVote::RankedPairs::Majority elements by margin of victory (mov)
sub pair_cmp
{
    my ($self, $other, $swap) = @_;

    # make sure both elements in the comparison are of this package's type, or a subclass
    if (not $other->isa(__PACKAGE__)) {
        PrefVote::Core::Exception->throw(description => "majority comparison type mismatch");
    }

    # pairs in comparison must be swapped if $swap flag is on
    my ($pair1, $pair2) = $swap ? ($self->{cand}, $other->{cand}) : ($other->{cand}, $self->{cand});

    # compare for sorting margin of victory in descending order
    my $rp_obj = PrefVote::RankedPairs->instance();
    my $mov1 = $rp_obj->get_mov(@$pair1);
    my $mov2 = $rp_obj->get_mov(@$pair2);
    if ($mov1 != $mov2) {
        return $mov1 <=> $mov2;
    }

    # if margin of victory was equal, secondary comparison is for lesser opposition (ascending order)
    my $oppose1 = $rp_obj->get_preference(reverse @$pair1);
    my $oppose2 = $rp_obj->get_preference(reverse @$pair2);
    return $oppose2 <=> $oppose1;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::RankedPairs:Majority - internal pairwise majority structure for Ranked Pairs method

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
