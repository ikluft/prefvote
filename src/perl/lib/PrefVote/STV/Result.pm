# PrefVote::STV::Result
# ABSTRACT: internal voting-result structure used by PrefVote::STV
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
# STV result record from each round
#
package PrefVote::STV::Result;

use autodie;

# class definitions
use Moo;
use Type::Tiny;
use Types::Standard qw(Bool Str Enum ArrayRef);
use Types::Common::String qw(NonEmptySimpleStr);
use Types::Common::Numeric qw(PositiveOrZeroNum);
extends 'PrefVote';

has name => (
    is => 'ro',
    isa => ArrayRef[NonEmptySimpleStr],
    required => 1,
);

has type => (
    is =>'ro',
    isa => Enum[qw(winner eliminated)],
    required => 1,
);

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Result - internal voting-result structure used by PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
