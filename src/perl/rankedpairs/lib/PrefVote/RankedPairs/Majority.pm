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
    '<=>' => \&mycmp;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# candidates paired either as winner-loser or alphabetical for ties
has cand => (
    is => 'ro',
    isa => Tuple[NonEmptySimpleStr, NonEmptySimpleStr],
    required => 1,
);

# margin of victory (0 for tie)
has mov => (
    is => 'ro',
    isa => PositiveOrZeroInt,
    required => 1,
);

sub mycmp
{
    my ($self, $other, $swap) = @_;
    if (not $other->isa(__PACKAGE__) {
        PrefVote::Core::Exception->throw(description => "majority comparison type mismatch");
    }
    if ($swap) {
        return $other->mov() <=> $self->mov();
    }
    return $self->mov() <=> $other->mov();
}

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
