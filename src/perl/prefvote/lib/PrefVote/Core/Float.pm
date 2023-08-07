# PrefVote::Core::Float
# ABSTRACT: floating point utilities for PrefVote subclasses
# derived from Vote::STV by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Float;

use utf8;
use feature qw(say);
use autodie;
use Readonly;
use Math::Round qw(nearest);
use Exporter    qw(import);
our @EXPORT_OK = qw(fp_equal fp_cmp float_limit float_external float_internal PVNum PVPositiveOrZeroNum);

# class definitions
use Type::Library -base, -declare => qw(PVNum PVPositiveOrZeroNum);
use Types::Common   qw(Num);
use Types::TypeTiny ();
use Type::Tiny;
use Type::Utils -all;
use Type::Coercion ();
BEGIN { extends "Types::Standard" }

# constants
Readonly::Scalar my $fp_external_precision => 5;         # 5 digits max past decimal point
Readonly::Scalar my $fp_internal_precision => 10;        # 10 digits max past decimal point
Readonly::Scalar my $fp_epsilon            => 2**-24;    # fp epsilon for fp_equal() based on 32-bit floats

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal
{
    my ( $x, $y ) = @_;
    return ( abs( $x - $y ) < $fp_epsilon ) ? 1 : 0;
}

# floating point comparison using fp_equal() for equality
sub fp_cmp
{
    my ( $x, $y ) = @_;
    if ( fp_equal( $x, $y ) ) {
        return 0;
    }
    if ( $x > $y ) {
        return 1;
    }
    return -1;
}

# format floating point numbers to limit display precision
sub float_limit
{
    my $num    = shift;
    my $digits = shift;
    return nearest( 10**-$digits, $num );
}

# internal and external floating point precision
sub float_external { return float_limit( shift, $fp_external_precision ); }
sub float_internal { return float_limit( shift, $fp_internal_precision ); }

# PVNum type for Type::Tiny ecosystem - PrefVote floating point number limited to 10-digit internal precision
declare "PVNum", as "Num", message { Num->validate() or "$_ is not a number" };
coerce "PVNum", from "Num", via { float_internal($_) };
declare "PVPositiveOrZeroNum", as "PVNum",
    where { $_ >= 0 },
    message { "Must be a number greater than or equal to zero" };
1;

__END__

# POD documentation

=encoding utf8

=head1 SYNOPSIS

floating point equality comparison utility function:

    use PrefVote::Core::Float qw(fp_equal);

    my $fp_eq = fp_equal($plan, $value);
    say "the numbers are".($fp_eq ? "" :" not")." equal";

floating point data types using PrefVote precision limits (for consistent fp results):

    use Moo;
    extends 'PrefVote';
    use PrefVote::Core::Float qw(float_internal PVPositiveOrZeroNum);

    # candidate vote total
    has votes => (
        is => 'rw',
        isa => PVPositiveOrZeroNum,
        default => 0,
    );
    around votes => sub {
        my ($orig, $self, $param) = @_;
        return $orig->($self, (defined $param ? (float_internal($param)) : ()));
    };    

=head1 DESCRIPTION

This provides floating point utility functions and data types for PrefVote.

=head1 FUNCTIONS

=over 1

=item fp_equal ( fp_a, fp_b )

Returns true if two floating point number parameters are close enough to be considered equal. 

In most programming languages the numeric equality operator (== in Perl) works for integers, but is not
appropriate for use with floating point numbers. Comparison of floating point numbers for equality needs to
check that the difference between the numbers is less than a small number "epsilon" value which depends on
the number of bits of floating point precision.

PrefVote sets a uniform epsilon value of 2^-23 so that tests can get consistent results. It is more than precise
enough for our voting needs, where internal fractional votes are limited to half that precision at 10^-10.

=item float_limit ( fp_num, digits )

Return a floating point number limited to the number of digits of precision beyond the decimal point.

=item float_external

Return a floating point number limited to PrefVote's systemwide standard for external precision,
5 decimal digits beyond the decimal point.

=item float_internal

Return a floating point number limited to PrefVote's systemwide standard for internal precision,
10 decimal digits beyond the decimal point.

=back

=head1 DATA TYPES

=over 1

=item PVNum

L<Types::Standard> compatible floating point number, except limited in precision to float_internal().

=item PVPositiveOrZeroNum

Same as PVNum except limited to non-negative numers, a.k.a. positive or zero.

=back

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

