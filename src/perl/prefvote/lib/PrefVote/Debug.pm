# PrefVote::Debug
# ABSTRACT: debug flag singleton class for PrefVote hierarchy
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Debug;

use Moo;
use Types::Standard qw(Bool);
with 'MooX::Singleton';

has debug => (
    is => 'rw',
    isa => Bool,
    required => 1,
);

# print debug message
sub debug_print
{
    my ($self, @args) = @_;
    my %opts;
    if (ref $args[0] eq "HASH") {
        %opts = %{shift @args};
    }
    my $prefix = $opts{prefix} // caller; # caller package name
    $self->{debug} and say STDERR $prefix.": ".join(" ", @args);
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Debug - debug flag singleton class for PrefVote hierarchy

=head1 SYNOPSIS

    use PrefVote::Debug;

    my $debug_ref = PrefVote::Debug->instance(debug => (($ENV{PREFVOTE_DEBUG} // 0) ? 1 : 0));
    $debug_mode = $debug_ref->debug(); # read debug mode flag
    $debug_ref->debug($debug_flag); # write to debug mode flag
    $debug_ref->debug_print("debug message goes here");

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Debug maintains a singleton debug flag for the PrefVote class hierarchy.

Since the top-level PrefVote class provides this to the entire hierarchy, do not use this class directly.
Use any relevant subclass of PrefVote instead.

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
