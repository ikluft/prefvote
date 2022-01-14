# PrefVote::Core::Types
# ABSTRACT: PrefVote core data types which extend Types::Standard
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
 
# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Types;

use autodie;
use Type::Library -base, -declare => qw(Set);
use Types::Standard qw(Undef Value ArrayRef assert_Value);
use Types::TypeTiny ();
use Type::Tiny::Class;
use Type::Utils qw(assert);
use Set::Tiny qw(set);

# define Set type to use Set::Tiny under the umbrella of Type::Tiny & Type::Library
__PACKAGE__->add_type(
    Type::Tiny::Class->new(
        name => "Set",
        class => "Set::Tiny",

        constraint_generator => sub {
            my $param = shift;
            if (not defined $param) {
                return Set;
            }
            Types::TypeTiny::assert_TypeTiny($param);
            return sub {
                return 0 unless ref $_;
                return 0 unless $_->isa(Set);
                foreach my $value ($_->elements()) {
                    $param->check($value) or return 0;
                };
                return 1;
            };
        },

        type_coercion_map => [
            Undef, q{ set() },
            Value, q{ set($_) },
            ArrayRef, q{ set(@$_) },
        ],
    )
);

# make the package immutable so Type::Tiny knows it won't be changed further
__PACKAGE__->make_immutable;

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::Types - PrefVote core data types which extend Types::Standard

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
