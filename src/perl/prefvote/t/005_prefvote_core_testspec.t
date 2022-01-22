#!/usr/bin/perl
# 005_prefvote_core_testspec.t - tests for PrefVote::Core::TestSpec
use Modern::Perl qw(2015); # require 5.20.0 or later

## no critic (Modules::ProhibitMultiplePackages)
package PrefVote::Core::TestSpec::UnitTest;

use autodie;
use Carp qw(croak);
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core::TestSpec;

#
# class definitions - this is a mock class just for testing
#
use Moo;
use MooX::TypeTiny;
use PrefVote::Core::Types qw(Set);
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
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, \%blackbox_spec);

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
use Carp qw(croak);
use Test::More tests => 54;
use Test::Exception;
use Readonly;
use Set::Tiny qw(set);
use Data::Dumper;

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
    'PrefVote::Core::TestSpec::UnitTest-boolean (bool)' => {
        'type' => 'cmp_ok',
        'value' => 1,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-boolean (bool)',
        'op' => '==',
        'expected' => 1
    },
    'PrefVote::Core::TestSpec::UnitTest-strset set size=3' => {
        'expected' => 3,
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset set size=3',
        'value' => 3,
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-a=a (str)' => {
        'expected' => 'a',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-a=a (str)',
        'value' => 'a',
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-b=b (str)' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-b=b (str)',
        'value' => 'b',
        'type' => 'is',
        'expected' => 'b'
    },
    'PrefVote::Core::TestSpec::UnitTest-strset-c=c (str)' => {
        'expected' => 'c',
        'type' => 'is',
        'value' => 'c',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strset-c=c (str)'
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
    'PrefVote::Core::TestSpec::UnitTest-strlist-0=g (str)' => {
        'expected' => 'g',
        'type' => 'is',
        'value' => 'g',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-0=g (str)'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-1=h (str)' => {
        'type' => 'is',
        'value' => 'h',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-1=h (str)',
        'expected' => 'h'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-2=i (str)' => {
        'expected' => 'i',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-2=i (str)',
        'value' => 'i',
        'type' => 'is'
    },
    'PrefVote::Core::TestSpec::UnitTest-strlist-3=j (str)' => {
        'type' => 'is',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-strlist-3=j (str)',
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
    'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-a=a (str)' => {
        'description' => 'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-a=a (str)',
        'type' => 'is',
        'value' => 'a',
        'expected' => 'a'
    },
    'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-b=b (str)' => {
        'expected' => 'b',
        'value' => 'b',
        'type' => 'is',
        'description' => 'PrefVote::Core::TestSpec::UnitTest-PrefVote::Core::TestSpec::UnitTest-strset-b=b (str)'
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

# perform a test returned from PrefVote::Core::TestSpec's check()
sub do_test_from_spec
{
    my $test = shift;

    # find the operation that was selected and call that test in Test::More
    ## no critic (ControlStructures::ProhibitCascadingIfElse ControlStructures::ProhibitDeepNests)
    if ($test->{type} eq "is") {
        is($test->{value}, $test->{expected}, $test->{description});
    } elsif ($test->{type} eq "cmp_ok") {
        cmp_ok($test->{value}, $test->{op}, $test->{expected}, $test->{description});
    } elsif ($test->{type} eq "ok") {
        ok($test->{value}, $test->{description});
    } elsif ($test->{type} eq "pass") {
        pass($test->{description});
    } elsif ($test->{type} eq "fail") {
        fail($test->{description});
    }
    return;    
}

# check if registry was loaded by register_blackbox_spec() call above
is(PrefVote::Core::TestSpec->get_blackbox_spec('PrefVote::Core::TestSpec::UnitTest'), \%blackbox_spec,
    "get_blackbox_spec");

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
        do_test_from_spec($result_item);
    };
}