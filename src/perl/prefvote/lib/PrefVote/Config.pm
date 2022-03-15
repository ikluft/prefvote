# PrefVote::Config
# ABSTRACT: configuration singleton class for PrefVote hierarchy
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
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

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

