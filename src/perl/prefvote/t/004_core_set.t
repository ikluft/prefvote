#!/usr/bin/perl
# 004_core_types.t - tests for PrefVote::Core::Set
use Modern::Perl qw(2013); # require 5.16.0 or later
use autodie;
use Test::More tests => 12;
use Test::TypeTiny;
use Readonly;
use PrefVote::Core::Set qw(Set);
use Set::Tiny qw(set);
use Scalar::Util qw( refaddr );

# basic tests
{
    my $set0 = set();
    should_pass($set0, Set, "empty set");
}
{
    my $set1 = set(4);
    should_pass($set1, Set, "1-item set");
}
should_fail(undef, Set, "undef rejected as expected");
should_fail(1, Set, "integer rejected as expected");

# parameterizable tests
my $SetOfInt = Set->of( Types::Standard::Int );
isa_ok($SetOfInt, 'Type::Tiny', 'SetOfInt');
is($SetOfInt->display_name, 'Set[Int]', 'SetOfInt has display_name Set[Int]');
ok($SetOfInt->is_anon, 'SetOfInt has no name');
my $SetOfStr = Set->of( Types::Standard::Str );
isa_ok($SetOfStr, 'Type::Tiny', 'SetOfStr');
is($SetOfStr->display_name, 'Set[Str]', 'SetOfStr has display_name Set[Str]');
ok($SetOfStr->is_anon, 'SetOfStr has no name');
{
    my $plain  = Set;
    my $paramd = Set[];
    is( refaddr($plain), refaddr($paramd), 'parameterizing with [] has no effect');
} 
{
    my $p1 = Set[Types::Standard::Str];
    my $p2 = Set[Types::Standard::Str];
    is(refaddr($p1), refaddr($p2), 'parameterizing is cached');
}

# done
done_testing;
