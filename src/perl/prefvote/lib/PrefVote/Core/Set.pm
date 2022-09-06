# PrefVote::Core::Set
# ABSTRACT: Set data type which extends Types::Standard
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Set;

use autodie;
use Data::Dumper;
use Scalar::Util qw(reftype);
use Type::Library -base, -declare => qw(Set);
use Types::Standard qw(Undef Value ArrayRef assert_Value);
use Types::TypeTiny ();
use Type::Tiny::Class;
use Type::Utils qw(assert);
use Type::Coercion ();
use Set::Tiny qw(set);

# define Set type to use Set::Tiny under the umbrella of Type::Tiny & Type::Library
my $set_type = Type::Tiny::Class->new(
    name  => "Set",
    class => "Set::Tiny",

    constraint_generator => sub {
        my $param = shift;
        if ( not defined $param ) {
            ## no critic (Variables::ProhibitPackageVars)
            return $Type::Tiny::parameterize_type;
        }
        Types::TypeTiny::assert_TypeTiny($param);
        return sub {
            return unless ref $_;
            return unless $_->isa("Set::Tiny");
            foreach my $value ( $_->elements() ) {
                $param->check($value) or return;
            }
            return !!1;
        };
    },

    coercion_generator => sub {
        my ( $parent, $child, $param ) = @_;
        Types::TypeTiny::assert_TypeTiny($parent);
        Types::TypeTiny::assert_TypeTiny($child);
        Types::TypeTiny::assert_TypeTiny($param);
        if ( not $param->has_coercion ) {
            return;
        }

        my $coercion = Type::Coercion->new( type_constraint => $child );
        $coercion->add_type_coercions(
            $parent => sub {
                my $value = @_ ? $_[0] : $_;

                my $new_set = set();
                if ( reftype $value eq "ARRAY" ) {
                    for my $item (@$value) {
                        $new_set->insert( $param->coerce($item) );
                    }
                } else {
                    $new_set->insert( $param->coerce($value) );
                }
                return $new_set;
            },
        );
        return $coercion;
    },
);
$set_type->coercion->add_type_coercions(
    Undef,    sub { return set() },
    Value,    sub { return set($_) },
    ArrayRef, sub { return set(@$_) },
);

__PACKAGE__->add_type($set_type);

# make the package immutable so Type::Tiny knows it won't be changed further
__PACKAGE__->make_immutable;

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

In class containing a set:

    package Some::Classname;
    use Moo;
    use MooX::TypeTiny;
    use Set::Tiny qw(set);
    use PrefVote::Core::Set qw(Set);

    has name => (
        is => 'ro',
        isa => Set[NonEmptySimpleStr],
    );

In code using Some::Classname's name set from above:

    sub new_names { return Some::Classname->new(name => set(@_); }

    my $abc_set = new_names(qw(a b c d e f));
    if ($abc_set->name()->is_empty()) {
        say "empty set";
        exit 0;
    }
    say "elements: ".join(" ", $self->name()->elements());

=head1 DESCRIPTION

PrefVote::Core::Set is a set data type based on L<Set::Tiny>, which provides an unordered list of unique strings.
It is compatible with L<Standard::Types> and the L<Moo> object system.
If used as the name "Set" it is a set of strings.

It is a parameterized type so that it can be a set of any scalar string type.
So "Set[NonEmptySimpleStr]" in the synopsis is a set of strings which are constrained to be non-empty.

Data elements are of type L<Set::Tiny>. So it is used for access to the data.

The PrefVote system uses this for lists of candidates when they should be unordered, such as before votes are counted
or within results among a group of candidates who are tied.

=head1 SEE ALSO

L<PrefVote>, L<Set::Tiny>, L<Moo>, L<Standard::Types>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
