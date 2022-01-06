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
use MooX::TypeTiny;
use PrefVote::Debug;
use PrefVote::Exception;  # pre-load in case exception is thrown

# cache a class-scoped reference to the debug instance
my $debug_ref = PrefVote::Debug->instance(debug => (($ENV{PREFVOTE_DEBUG} // 0) ? 1 : 0));

# wrapper for PrefVote::Debug's debug method
sub debug
{
    my ($self, $value) = @_;
    return defined $value ? $debug_ref->debug($value) : $debug_ref->debug();
}

# wrapper for PrefVote::Debug's debug_print method
sub debug_print
{
    my ($self_or_class, @args) = @_;
    my $prefix = (ref $self_or_class) ? ref $self_or_class : $self_or_class;
    return $debug_ref->debug_print({prefix => $prefix}, @args);
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
