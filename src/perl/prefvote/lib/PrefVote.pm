# PrefVote
# ABSTRACT: base class for PrefVote preference voting system
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote;

use autodie;
use Moo;
use MooX::TypeTiny;
use PrefVote::Config;
use PrefVote::Debug;
use PrefVote::Exception;  # pre-load in case exception is thrown

# cache a class-scoped reference to the config & debug instances
my $config_ref = PrefVote::Config->instance();
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

# accessor for PrefVote::Config hash of config items
sub config
{
    my ($self_or_class, @args) = @_;
    return $config_ref->accessor(@args);
}

# check if a config entry exists
sub config_exists
{
    my ($self_or_class, $key) = @_;
    return $config_ref->exists($key);
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote - Preference voting system

=head1 SYNOPSIS

In standard Perl5:

    use base "PrefVote";
    #...
    PrefVote->debug($debug_flag);
    #...
    PrefVote->debug_print("debug message goes here");

In Moo object environment:

    use Moo;
    #...
    extends 'PrefVote';
    #...
    PrefVote->debug($debug_flag);
    #...
    PrefVote->debug_print("debug message goes here");

=head1 DESCRIPTION

PrefVote is the top-level class of the PrefVote voting system. By itself the class serves as the top level of the
class hierarchy. It only provides a global debug flag. It loads L<PrefVote::Exception> in case any subclasses throw
an exception. Voting functionality is under L<PrefVote::Core>.

=head1 SEE ALSO

L<PrefVote::Core>. L<PrefVote::STV>, L<PrefVote::Schulze>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
