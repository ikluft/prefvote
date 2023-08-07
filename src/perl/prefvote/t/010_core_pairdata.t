#!/usr/bin/perl
# 010_core_pairdata.t - tests for PrefVote::Core::PairData
use strict;
use warnings;
use autodie;
use Test::More tests => 13;
use Test::Exception;
use Readonly;
use PrefVote::Core::PairData;
use Set::Tiny qw(set);

# check type and default values (5 tests)
my $pairdata_ref = PrefVote::Core::PairData->new();
ok( defined $pairdata_ref, "new() returned a defined value" );
ok( ref $pairdata_ref,     "new() returned a reference" );
isa_ok( $pairdata_ref, "PrefVote::Core::PairData", "new() returned correct object" );
is( $pairdata_ref->{preference}, undef, "default direct: preference = undef" );
is( $pairdata_ref->preference(), undef, "default via accessor: preference = undef" );

# accessors (2 tests)
$pairdata_ref->preference(0);
is( $pairdata_ref->{preference}, 0, "after accessor preference(0): preference = 0" );
is( $pairdata_ref->preference(), 0, "accessor preference(0) returns 0" );

# run add_preference method and test effects (6 tests)
my $ret;
$ret = $pairdata_ref->add_preference(0);
is( $pairdata_ref->preference(), 0, "after add_preference(0): preference = 0" );
is( $ret,                        0, "after add_preference(0): return value 0" );
$ret = $pairdata_ref->add_preference(1);
is( $pairdata_ref->preference(), 1, "after add_preference(1): preference = 1" );
is( $ret,                        1, "after add_preference(1): return value 1" );
$ret = $pairdata_ref->add_preference(2);
is( $pairdata_ref->preference(), 3, "after add_preference(2): preference = 3" );
is( $ret,                        3, "after add_preference(2): return value 3" );
