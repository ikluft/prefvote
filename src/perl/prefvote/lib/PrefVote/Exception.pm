# PrefVote::Exception
# ABSTRACT: top-level exception class for PrefVote hierarchy
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Exception;

use overload ( '""' => 'stringify' );
use Moo;
use Types::Standard qw(Str);
with 'Throwable';
has classname   => ( is => 'ro', isa => Str );
has description => ( is => 'ro', isa => Str );

sub stringify
{
    my ($self) = @_;
    my $class = ref($self) || $self;

    return
          "$class exception: "
        . $self->{description} . " "
        . join( "",
        map { "\n$_: " . ( $self->{$_} // "undef" ) }
            ( sort grep { $_ ne "description" } ( keys %$self ) ) )
        . "\n";
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

Usage from CLI mainline:

    use Carp qw(confess);
    use PrefVote; # any subclass of PrefVote will load PrefVote::Exception

    sub main
    {
        # ...
        return 1;
    }

    if (not eval { main() }) {
        my $e = $@;
        if (ref $e and $e->isa("PrefVote::Exception")) {
            say $e;
            if ($e->can("retval")) {
                exit $e->retval();
            }
        } else {
            confess $e;
        }
        exit 1;
    }

Usage throwing an exception:

    PrefVote::Exception->throw({description => "error message", classname => __PACKAGE__});

=head1 DESCRIPTION

PrefVote::Exception uses L<Throwable> to serve as a class for excpetions in the PrefVote system.
It can be used directly, or subclassed to add more parameters or default values to existing parameters.

=head1 SEE ALSO

L<PrefVote>, L<Throwable>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
