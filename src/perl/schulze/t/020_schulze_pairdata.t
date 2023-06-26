#!/usr/bin/perl
# 020_schulze_pairdata.t - tests for PrefVote::Schulze::PairData
use strict;
use warnings;
use autodie;
use Test::More tests => 38;
use Test::Exception;
use Readonly;
use PrefVote::Schulze::PairData;
use Set::Tiny qw(set);

# check type and default values (15 tests)
my $schulze_pairdata_ref = PrefVote::Schulze::PairData->new();
ok(defined $schulze_pairdata_ref, "new() returned a defined value");
ok(ref $schulze_pairdata_ref, "new() returned a reference");
isa_ok($schulze_pairdata_ref, "PrefVote::Schulze::PairData", "new() returned correct object");
is($schulze_pairdata_ref->{preference}, undef, "default direct: preference = undef");
is($schulze_pairdata_ref->preference(), undef, "default via accessor: preference = undef");
is($schulze_pairdata_ref->{predecessor}, undef, "default direct: predecessor = undef");
is($schulze_pairdata_ref->predecessor(), undef, "default via accessor: predecessor = undef");
is($schulze_pairdata_ref->{strength}, undef, "default direct: strength = undef");
is($schulze_pairdata_ref->strength(), undef, "default via accessor: strength = undef");
is($schulze_pairdata_ref->{win_order}, 0, "default direct: win_order = 0");
is($schulze_pairdata_ref->win_order(), 0, "default via accessor: win_order = 0");
is($schulze_pairdata_ref->{forbidden}, undef, "default direct: forbidden = undef");
is($schulze_pairdata_ref->forbidden(), undef, "default via accessor: forbidden = undef");
is($schulze_pairdata_ref->{path_history}, undef, "default direct: path_history = undef");
is($schulze_pairdata_ref->path_history(), undef, "default via accessor: path_history = undef");

# accessors (17 tests)
$schulze_pairdata_ref->preference(0);
is($schulze_pairdata_ref->{preference}, 0, "after accessor preference(0): preference = 0");
is($schulze_pairdata_ref->preference(), 0, "accessor preference(0) returns 0");
$schulze_pairdata_ref->predecessor("test1");
is($schulze_pairdata_ref->{predecessor}, "test1", "after accessor predecessor(test1): preference = test1");
is($schulze_pairdata_ref->predecessor(), "test1", "accessor predecessor(test1) returns test1");
$schulze_pairdata_ref->strength(0);
is($schulze_pairdata_ref->{strength}, 0, "after accessor strength(0): preference = 0");
is($schulze_pairdata_ref->strength(), 0, "accessor strength(0) returns 0");
$schulze_pairdata_ref->strength(10);
is($schulze_pairdata_ref->{strength}, 10, "after accessor strength(10): preference = 10");
is($schulze_pairdata_ref->strength(), 10, "accessor strength(10) returns 10");
$schulze_pairdata_ref->win_order(1);
is($schulze_pairdata_ref->{win_order}, 1, "after accessor win_order(1): preference = 1");
is($schulze_pairdata_ref->win_order(), 1, "accessor win_order(1) returns 1");
$schulze_pairdata_ref->forbidden(set(qw(test1 test2)));
is_deeply($schulze_pairdata_ref->{forbidden}, set(qw(test1 test2)),
    "after accessor forbidden(set of test1 test2): forbidden = set of test1 test2");
is_deeply($schulze_pairdata_ref->forbidden(), set(qw(test1 test2)),
    "accessor forbidden(set of test1 test2) returns set of test1 test2");
dies_ok( sub{$schulze_pairdata_ref->forbidden([[qw(test1 test2)]]);},
    "accessor forbidden() dies as expected: given array where set wanted");
$schulze_pairdata_ref->path_history([[qw(test1 test2)]]);
is_deeply($schulze_pairdata_ref->{path_history}, [[qw(test1 test2)]],
    "after accessor path_history(set of test1 test2): path_history = array of array of test1 test2");
is_deeply($schulze_pairdata_ref->path_history(), [[qw(test1 test2)]],
    "accessor path_history(set of test1 test2) returns array of array of test1 test2");
dies_ok( sub{$schulze_pairdata_ref->path_history(set(qw(test1 test2)));},
    "accessor path_history() dies as expected: given set where array of array expected");
dies_ok( sub{$schulze_pairdata_ref->path_history([qw(test1 test2)]);},
    "accessor path_history() dies as expected: given array of string where array of array expected");

# run add_preference method and test effects (6 tests)
my $ret;
$ret = $schulze_pairdata_ref->add_preference(0);
is($schulze_pairdata_ref->preference(), 0, "after add_preference(0): preference = 0");
is($ret, 0, "after add_preference(0): return value 0");
$ret = $schulze_pairdata_ref->add_preference(1);
is($schulze_pairdata_ref->preference(), 1, "after add_preference(1): preference = 1");
is($ret, 1, "after add_preference(1): return value 1");
$ret = $schulze_pairdata_ref->add_preference(2);
is($schulze_pairdata_ref->preference(), 3, "after add_preference(2): preference = 3");
is($ret, 3, "after add_preference(2): return value 3");
