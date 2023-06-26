#!/usr/bin/perl
# 005_core_testspec.t - tests for PrefVote::Core::TestSpec
use strict;
use warnings;

## no critic (Modules::ProhibitMultiplePackages)
package PrefVote::Core::TestSpec::UnitTest;

use autodie;
use Readonly;
use PrefVote::Core::TestSpec;

#
# class definitions - this is a mock class just for testing
#
use Moo;
use MooX::TypeTiny;
use PrefVote::Core::Set qw(Set);
use Types::Standard qw(Bool Str Int StrictNum ArrayRef HashRef InstanceOf);
extends 'PrefVote';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    strset => [qw(set string)],
    strhash => [qw(hash string)],
    strlist => [qw(list string)],
    integer => [qw(int)],
    float => [qw(fp)],
    boolean => [qw(bool)],
    tsut => [qw(PrefVote::Core::TestSpec::UnitTest)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec);

# variety of attributes to allow testing the data types
has strset => (
    is => 'rw',
    isa => Set[Str],
);
has strhash => (
    is => 'rw',
    isa => HashRef[Str],
);
has strlist => (
    is => 'rw',
    isa => ArrayRef[Str],
);
has integer => (
    is => 'rw',
    isa => Int,
);
has float => (
    is => 'rw',
    isa => StrictNum,
);
has boolean => (
    is => 'rw',
    isa => Bool,
);
has tsut => (
    is => 'rw',
    isa => InstanceOf['PrefVote::Core::TestSpec::UnitTest'],
);

# unit tests
package main;

use autodie;
use Readonly;
use Set::Tiny qw(set);
use Data::Dumper;
use Test::More tests => 58;
use Test::Exception;
use PrefVote::Core::TestUtil;

# test fixtures: basic
Readonly::Hash my %basic_checklist => (
    strset => [qw(a b c)],
    strhash => { d => 1, e => 2, f => 3},
    strlist => [qw(g h i j)],
    integer => 1,
    float => 1.0000000000001,
    boolean => 1,
);
Readonly::Array my @basic_value => (
    strset => set(qw(a b c)),
    strhash => { d => 1, e => 2, f => 3},
    strlist => [qw(g h i j)],
    integer => 1,
    float => 1.0000000000001,
    boolean => 1,
    
);
Readonly::Hash my %basic_result => (
    'PrefVote::Core::TestSpec::UnitTest-boolean=1 (bool)' => {
        'type' => 'cmp_ok',
        'value' => 1,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-boolean=1 (bool)',
        'op' => '==',
        'expected' => 1
    },
    'PrefVote::Core::TestSpec::UnitTest-strset set size=3' => {
        'expected' => 3,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset set size=3',
        'value' => 3,
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-a=a (string)' => {
        'expected' => 'a',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-a=a (string)',
        'value' => 'a',
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-b=b (string)' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-b=b (string)',
        'value' => 'b',
        'type' => 'is',
        'expected' => 'b'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-c=c (string)' => {
        'expected' => 'c',
        'type' => 'is',
        'value' => 'c',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-c=c (string)'
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-d exists' => {
        'type' => 'ok',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-d exists',
        'value' => 1
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-d=1' => {
        'expected' => 1,
        'type' => 'is',
        'value' => 1,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-d=1'
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-e exists' => {
        'value' => 1,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-e exists',
        'type' => 'ok'
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-e=2' => {
        'expected' => 2,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-e=2',
        'value' => 2,
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-f exists' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-f exists',
        'value' => 1,
        'type' => 'ok'
    },
    'PrefVote::Core::TestSpec::UnitTest-strhash-f=3' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strhash-f=3',
        'value' => 3,
        'type' => 'is',
        'expected' => 3
    },
    'PrefVote::Core::TestSpec::UnitTest-float=1.0000000000001 (fp)' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-float=1.0000000000001 (fp)',
        'value' => 1,
        'type' => 'ok'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist list length=4' => {
        'expected' => 4,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist list length=4',
        'value' => 4,
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-0=g (string)' => {
        'expected' => 'g',
        'type' => 'is',
        'value' => 'g',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-0=g (string)'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-1=h (string)' => {
        'type' => 'is',
        'value' => 'h',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-1=h (string)',
        'expected' => 'h'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-2=i (string)' => {
        'expected' => 'i',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-2=i (string)',
        'value' => 'i',
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-3=j (string)' => {
        'type' => 'is',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-3=j (string)',
        'value' => 'j',
        'expected' => 'j'
    },
    'PrefVote::Core::TestSpec::UnitTest-integer=1 (int)' => {
        'type' => 'cmp_ok',
        'op' => '==',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-integer=1 (int)',
        'value' => 1,
        'expected' => 1
    }
);

# test fixtures: complex
Readonly::Hash my %complex_checklist => (
    tsut => {strset => [qw(a b)]},
);
Readonly::Array my @complex_value => (
    tsut => PrefVote::Core::TestSpec::UnitTest->new(strset => set(qw(a b))),
);
Readonly::Hash my %complex_result => (
    'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset set size=2' => {
        'expected' => 2,
        'value' => 2,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset set size=2',
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-a=a (string)' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-a=a (string)',
        'type' => 'is',
        'value' => 'a',
        'expected' => 'a'
    },
    'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-b=b (string)' => {
        'expected' => 'b',
        'value' => 'b',
        'type' => 'is',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-b=b (string)'
    }
);

# test order
Readonly::Array my @tests => (
    {checklist => undef, new_exception => 'Error::TypeTiny::Assertion', desc => "checklist undef"},
    {checklist => 1, new_exception => 'Error::TypeTiny::Assertion', desc => "checklist 1"},
    {checklist => {}, check_value => PrefVote::Core::TestSpec::UnitTest->new(),
        result => [], desc => "checklist empty hash, value empty"},
    {checklist => \%basic_checklist, check_value => PrefVote::Core::TestSpec::UnitTest->new(@basic_value),
        result => \%basic_result, desc => "basic test"},
    {checklist => \%complex_checklist, check_value => PrefVote::Core::TestSpec::UnitTest->new(@complex_value),
        result => \%complex_result, desc => "complex test"},
);

# check if registry was loaded by register_blackbox_spec() call above
is_deeply(PrefVote::Core::TestSpec->get_blackbox_spec('PrefVote::Core::TestSpec::UnitTest'), \%blackbox_spec,
    "get_blackbox_spec");
my $spec_registry = PrefVote::Core::TestSpec::get_spec_registry();
ok(exists $spec_registry->{'PrefVote::Core::TestSpec::UnitTest'}, "registry entry exists");
isa_ok($spec_registry->{'PrefVote::Core::TestSpec::UnitTest'}, "HASH", "registry entry is a HASH");
ok((exists $spec_registry->{'PrefVote::Core::TestSpec::UnitTest'}{spec}), "registry entry has a spec");
ok((not exists $spec_registry->{'PrefVote::Core::TestSpec::UnitTest'}{parent}),
    "registry entry does not have a parent");

# loop through test fixtures
foreach my $test (@tests) {
    my $testspec_obj;
    if (exists $test->{new_exception}) {
        throws_ok(sub { $testspec_obj = PrefVote::Core::TestSpec->new(checklist => $test->{checklist})},
            $test->{new_exception}, "exception expected (new): ".$test->{desc});
        next;
    }
    lives_ok(sub { $testspec_obj = PrefVote::Core::TestSpec->new(checklist => $test->{checklist})},
        "no exception expected (new): ".$test->{desc});
    if (exists $test->{check_exception}) {
        throws_ok(sub { $testspec_obj->check($test->{check_value})},
            $test->{check_exception}, "exception expected (check): ".$test->{desc});
        next;
    }
    my @result;
    lives_ok(sub {@result = $testspec_obj->check($test->{check_value})},
        "no exception expected (check): ".$test->{desc});
    #say STDERR "result (".$test->{desc}."): result = ".Dumper(\@result);
    isa_ok($testspec_obj->testroot(), "PrefVote::Core::TestNode", "root node: ".$test->{desc});
    foreach my $result_item (@result) {
        #say STDERR "result_item ".Dumper($result_item);
        is_deeply($result_item, $test->{result}{$result_item->{description}},
            "test content: ".$result_item->{description});
        PrefVote::Core::TestUtil::do_test($result_item);
    };
}
