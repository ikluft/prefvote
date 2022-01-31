# PrefVote::Core::Float
# ABSTRACT: floating point utilities for PrefVote subclasses
# derived from Vote::STV by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Float;

use autodie;
use Config;
use Readonly;
use Math::Round qw(nearest);
use Exporter qw(import);
our @EXPORT_OK = qw(fp_equal float_limit float_external float_internal PVNum PVPositiveOrZeroNum);

# class definitions
use Type::Library -base, -declare => qw(PVNum PVPositiveOrZeroNum);
use Types::Standard qw(Num);
use Types::TypeTiny ();
use Type::Tiny;
use Type::Utils -all;
use Type::Coercion ();
BEGIN { extends "Types::Standard" };

# constants
Readonly::Scalar my $fp_external_precision => 5; # 5 digits max past decimal
Readonly::Scalar my $fp_internal_precision => 10; # 10 digits max past decimal
Readonly::Scalar my $fp_epsilon => (($Config{doublesize} >= 8) ? 2**-52 : 2**-23); # fp epsilon for fp_equal()

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal {
    my ($x, $y) = @_;
    return ($x-$y > -$fp_epsilon and $x-$y < $fp_epsilon);
}

# format floating point numbers to limit display precision
sub float_limit
{
    my $num = shift;
    my $digits = shift;
    return nearest(10**-$digits, $num);
}

# internal and external floating point precision
sub float_external { return float_limit(shift, $fp_external_precision); }
sub float_internal { return float_limit(shift, $fp_internal_precision); }

# PVNum type for Type::Tiny ecosystem - PrefVote floating point number limited to 10-digit internal precision
#my $pvnum_type = Type::Tiny->new(
#    name => "PVNum",
#    parent => Num,
#    constraint => sub { looks_like_number($_) },
#    message    => sub { "$_ is not a number" },
#    type_coercion_map => [
#        Num, sub { float_internal($_) },
#    ],
#);
declare "PVNum",
    as "Num",
    message { Num->validate() or "$_ is not a number"};
coerce "PVNum",
    from "Num", via { float_internal($_) };
#my $pvpznum_type = Type::Tiny->new(
#    name       => 'PVPositiveOrZeroNum',
#    parent     => $pvnum_type,
#    constraint => sub { $_ >= 0 },
#    message    => sub { "Must be a number greater than or equal to zero" },
#);
declare "PVPositiveOrZeroNum",
    as "PVNum",
    where { $_ >= 0 },
    message { "Must be a number greater than or equal to zero" };
1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::Float - floating point utilities for PrefVote subclasses

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

