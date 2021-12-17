# PrefVote
# ABSTRACT: base class for PrefVote preference voting system
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote;

use autodie;
use Carp qw(croak);
use Moo;
use Type::Tiny;
use Types::Standard qw(InstanceOf);
use PrefVote::Exception;  # pre-load in case exception is thrown

has debug_flag => (
    is => 'rw',
    isa => InstanceOf["PrefVote::Debug"],
    handles => [qw(debug debug_print)],
    default => sub{ PrefVote::debug_instance() },
);

# class function to get debug class/object instance
sub debug_instance
{
    return PrefVote::Debug->instance();
}

## no critic (Modules::ProhibitMultiplePackages)

#
# debug flag class - singleton object shared by all objects in the PrefVote class hierarchy
#
package PrefVote::Debug;

use Moo;
use Types::Standard qw(Bool);
with 'MooX::Singleton';

has debug => (
    is => 'rw',
    isa => Bool,
    default => sub { return ($ENV{PREFVOTE_DEBUG} // 0) ? 1 : 0 },
);

# print debug message
sub debug_print
{
    my ($self, @strs) = @_;
    my @caller = caller;
    my $prefix = $caller[0]; # caller package name
    $self->{debug} and say STDERR $prefix.": ".join(" ", @strs);
    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote - Preference voting system

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
