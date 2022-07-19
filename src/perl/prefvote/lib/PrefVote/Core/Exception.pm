# PrefVote::Core::Exception
# ABSTRACT: general exception class for all voting methods
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Exception;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Exception';
has classname => (is => 'ro', isa =>Str, default => "PrefVote::Core");

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    if (@missing) {
        PrefVote::Core::Exception->throw(classname => __PACKAGE__,
            description => "missing parameter: ".join(" ", @missing));
    }

=head1 DESCRIPTION

PrefVote::Core::Exception is a subclass of L<PrefVote::Exception> and only differs in the default value for
the classname attribute. It serves as the top-level exception class for voting method classes, which are those
that derive from PrefVote::Core.

=head1 SEE ALSO

L<PrefVote::Exception>, L<Throwable>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
