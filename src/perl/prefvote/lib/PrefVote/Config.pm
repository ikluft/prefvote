# PrefVote::Config
# ABSTRACT: configuration singleton class for PrefVote hierarchy
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Config;
use Getopt::Long;

use autodie;
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Defined HashRef);
use Types::Common::String qw(SimpleStr);
with 'MooX::Singleton';

has config => (
    is => 'rw',
    isa => HashRef[Defined],
    default => sub { return {} },
    handles_via => 'Hash',
    handles => {
        accessor => 'accessor',
        count => 'count',
        exists => 'exists',
        get => 'get',
        keys => 'keys',
        set => 'set',
    },
);

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Config - configuration singleton class for PrefVote hierarchy

=head1 SYNOPSIS

    use PrefVote::Config;

    my $config_ref = PrefVote::Config->instance());

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Config maintains a singleton configuration for the PrefVote class hierarchy.

Since the top-level PrefVote class provides this to the entire hierarchy, do not use this class directly.
Use any relevant subclass of PrefVote instead.

=head2 RECOGNIZED CONFIGURATIONS

The following configutation strings are recognized. Subclasses may define more of their own.
All configuration entries default to non-existent and undefined.

=over 1

=item no-tiebreak

If defined, this contains a boolean flag that inhibits the PrefVote system's use of L<PrefVote::Core>
"average choice rank" (ACR) data for tie-breaking. This is recognized by L<PrefVote::STV>, L<PrefVote::Schulze> and
L<PrefVote::RankedPairs>.

=item input-ties

(experimental)
If defined, this contains a boolean flag that enables input ties in the format of "A/B" to indicate a voter cast
an equal tied vote between two choices.
This is recognized by L<PrefVote::Core> and inherited by all other voting methods.
It does not affect L<PrefVote::Schulze> which sets input ties on by its definition.
The STV and RankedPairs code currently does not expect input ties to occur, and currently will fail when it is set
and any input-tied votes are received.

=back

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

