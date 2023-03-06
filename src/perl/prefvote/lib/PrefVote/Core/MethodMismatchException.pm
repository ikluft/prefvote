# PrefVote::Core::MethodMismatchException
# ABSTRACT: voting method mismatch exception
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::MethodMismatchException;

use utf8;
use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::Exception';
has attribute => ( is => 'ro', isa => Str );

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

Throwing this exception directly:

    if (not ref $value) {
        PrefVote::Core::MethodMismatchException->throw(classname => __PACKAGE__, attribute => "value",
            description => "scalar value received, object ref expected");
    }

=head1 DESCRIPTION

PrefVote::Core::MethodMismatchException is a subclass of L<PrefVote::Core::Exception>.
It doesn't add any attributes. It is only separated from other types of exceptions so that it can be
recognized in cases where black-box testing scripts should exit without error.
Black-box tests loop through all the voting methods and only want to run tests where data files
declare they are applicable to that method.
In other cases it's safe to skip it.

=head1 SEE ALSO

L<PrefVote::Core::Exception>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
