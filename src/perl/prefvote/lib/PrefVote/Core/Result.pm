# PrefVote::Core::Result
# ABSTRACT: internal voting-result structure used by PrefVote::Core
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# PrefVote::Core result record from each round, for voting methods which use rounds
#
package PrefVote::Core::Result;

use autodie;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Enum);
use Types::Common::String qw(NonEmptySimpleStr);
use Types::Common::Numeric qw(PositiveOrZeroNum);
use PrefVote::Core::Set qw(Set);
extends 'PrefVote';

# constants
Readonly::Hash my %blackbox_spec => (
    name => [qw(set string)],
    type => [qw(string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec);

has name => (
    is => 'ro',
    isa => Set[NonEmptySimpleStr],
    required => 1,
    handles => {
        name_all => 'elements',
        name_count => 'size',
        name_empty => 'is_empty',
    },
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

PrefVote::Core::Result - internal voting-result structure used by PrefVote::Core

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut