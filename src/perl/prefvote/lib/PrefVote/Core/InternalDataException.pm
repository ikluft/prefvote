# PrefVote::Core::InternalDataException
# ABSTRACT: invalid internal data exception
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::InternalDataException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::Exception';
has attribute => (is => 'ro', isa =>Str);

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

Throwing this exception directly:

    if (not ref $value) {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "value",
            description => "scalar value received, object ref expected");
    }

Deriving a subclass from this exception:

    package Some::Class::NegativeIncrementException;

    use Moo;
    use Types::Standard qw(Str);
    extends 'PrefVote::Core::InternalDataException';
    # optionally add exception data attributes here

=head1 DESCRIPTION

PrefVote::Core::InternalDataException is a subclass of L<PrefVote::Core::Exception>.
It extends it with an attribute called 'attribute' which contains the name of a variable which had an error.

It can be meaningful to derive a subclass which doesn't add any new attributes.
The name of the subclass can give an indication of which class or group of classes an error occurred,
where that error would be thrown.
It can also be named for a more specific kind of error as an indicator of what went wrong when that
exception is thrown.

=head1 SEE ALSO

L<PrefVote::Core::Exception>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
