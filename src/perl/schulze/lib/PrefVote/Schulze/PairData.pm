
# PrefVote::Schulze::PairData
# ABSTRACT: internal candidate-pair data for Schulze method
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Schulze::PairData;

use autodie;
use Data::Dumper;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Bool Int Str ArrayRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Common::String qw(NonEmptySimpleStr);
use PrefVote::Core::TestSpec;
extends 'PrefVote';


# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    preference => [qw(int)],
    predecessor => [qw(string)],
    strength => [qw(int)],
    win_order => [qw(bool)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote');

# preference: total votes showing preference of candidate i over j
# optional - use 0 is nonexistent
has preference => (
    is => 'rw',
    isa => PositiveOrZeroInt,
);

# predecessor: link in building strongest paths
# optional - only exists if after computation if candidates i and j have preferences cast
has predecessor => (
    is => 'rw',
    isa => NonEmptySimpleStr,
);

# strength of strongest path from candidate i to j
has strength => (
    is => 'rw',
    isa => Int,
);

# flag: this ordering of the pair is the winning direction, part of the ranking order set 𝚶 
has win_order => (
    is => 'rw',
    isa => Bool,
    default => 0,
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

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Schulze:PairData - internal candidate-pair data for Schulze method

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut