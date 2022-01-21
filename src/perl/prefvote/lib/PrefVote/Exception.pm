# PrefVote::Exception
# ABSTRACT: top-level exception class for PrefVote hierarchy
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Exception;

use Moo;
use Types::Standard qw(Str);
with 'Throwable';
has classname => (is => 'ro', isa =>Str);
has description => (is => 'ro', isa =>Str);

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Exception - top-level exception class for PrefVote hierarchy

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
