#!/usr/bin/perl
# 001_config.t - tests for low-level PrefVote::Config configuration data store

use Modern::Perl qw(2013); # require 5.16.0 or later
use utf8;
use autodie;
use open ':std', ':encoding(utf8)';

use Test::More;
use Test::Exception;
use PrefVote::Config;

# test data
my %samples = (
    "foo" => "bar",
    "🙈" => "see no evil",
    "🙉" => "hear no evil",
    "🙊" => "speak no evil",
);

# count test cases
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");
plan tests => 8 + int(keys %samples) * 6;

# test instantiation
is(PrefVote::Config->_has_instance(), undef, "no instance before initialization");
my $instance;
lives_ok(sub {$instance = PrefVote::Config->instance();}, 'instantiation runs without throwing exception');
ok(ref $instance, "instance is a ref after initialization");
isa_ok($instance, "PrefVote::Config", '$instance');
ok($instance->DOES("MooX::Singleton"), 'instance uses role MooX::Singleton');
ok($instance == PrefVote::Config->instance(), "2nd call to instance() returns same instance");

# test reading and writing configuration data

# insert and verify samples by instance methods
foreach my $key (sort keys %samples) {
    is($instance->contains($key), '', "by instance method: entry '$key' should not exist prior to add");
    my $value = $samples{$key};
    lives_ok(sub {$instance->accessor($key, $value);}, "by instance method: insert '$key' -> '$value'");
    is($instance->contains($key), 1, "by instance method: entry '$key' should exist after add");
    is($instance->accessor($key), $value, "by instance method: verify '$key' -> '$value'");
}
is_deeply([sort keys %{$instance->{config}}], [sort keys %samples],
    "by instance method: verify instance keys from samples after insertion");

# delete and verify config entries by instance methods
foreach my $key (sort keys %samples) {
    lives_ok(sub {$instance->del($key);}, "by instance method: delete '$key'");
    is($instance->contains($key), '', "by instance method: entry '$key' should not exist after delete");
}
is_deeply([sort keys %{$instance->{config}}], [], "by instance method: verify instance keys empty after deletion");


