#!/usr/bin/perl
# 030_rankedpairs_pairdata.t - tests for PrefVote::RankedPairs::PairData
use Modern::Perl qw(2015); # require 5.20.0 or later
use autodie;
use Test::More tests => 25;
use Test::Exception;
use Readonly;
use PrefVote::RankedPairs::PairData;
use Set::Tiny qw(set);

# check type and default values (10 tests)
my $pairdata_ref = PrefVote::RankedPairs::PairData->new();
ok(defined $pairdata_ref, "new() returned a defined value");
ok(ref $pairdata_ref, "new() returned a reference");
isa_ok($pairdata_ref, "PrefVote::RankedPairs::PairData", "new() returned correct object");
is($pairdata_ref->{preference}, undef, "default direct: preference = undef");
is($pairdata_ref->preference(), undef, "default via accessor: preference = undef");
is($pairdata_ref->{mov}, undef, "default direct: mov = undef");
is($pairdata_ref->mov(), undef, "default via accessor: mov = undef");
is($pairdata_ref->{lock}, undef, "default direct: lock = undef");
is($pairdata_ref->lock(), undef, "default via accessor: lock = undef");
is($pairdata_ref->get_lock(), 0, "default via get_lock(): lock = 0");

# accessors (9 tests)
$pairdata_ref->preference(0);
is($pairdata_ref->{preference}, 0, "after accessor preference(0): preference = 0");
is($pairdata_ref->preference(), 0, "accessor preference(0) returns 0");
$pairdata_ref->mov(0);
is($pairdata_ref->{mov}, 0, "after accessor mov(0): preference = 0");
is($pairdata_ref->mov(), 0, "accessor mov(0) returns 0");
$pairdata_ref->mov(10);
is($pairdata_ref->{mov}, 10, "after accessor mov(10): preference = 10");
is($pairdata_ref->mov(), 10, "accessor mov(10) returns 10");
$pairdata_ref->set_lock();
is($pairdata_ref->{lock}, 1, "after accessor set_lock(): preference = 1");
is($pairdata_ref->lock(), 1, "accessor lock() returns 1");
is($pairdata_ref->get_lock(), 1, "get_lock() returns 1");

# run add_preference method and test effects (6 tests)
my $ret;
$ret = $pairdata_ref->add_preference(0);
is($pairdata_ref->preference(), 0, "after add_preference(0): preference = 0");
is($ret, 0, "after add_preference(0): return value 0");
$ret = $pairdata_ref->add_preference(1);
is($pairdata_ref->preference(), 1, "after add_preference(1): preference = 1");
is($ret, 1, "after add_preference(1): return value 1");
$ret = $pairdata_ref->add_preference(2);
is($pairdata_ref->preference(), 3, "after add_preference(2): preference = 3");
is($ret, 3, "after add_preference(2): return value 3");
