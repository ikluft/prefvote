#!/usr/bin/perl
# 000_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
        PrefVote
        PrefVote::Config
        PrefVote::Debug
        PrefVote::Core::Ballot
        PrefVote::Core::Exception
        PrefVote::Core::Float
        PrefVote::Core::InternalDataException
        PrefVote::Core::Input
        PrefVote::Core::MethodMismatchException
        PrefVote::Core::Output
        PrefVote::Core::Output::HTML
        PrefVote::Core::Output::Markdown
        PrefVote::Core::Output::RawCapture
        PrefVote::Core::Output::Text
        PrefVote::Core::Result
        PrefVote::Core::Round
        PrefVote::Core::Set
        PrefVote::Core::TestSpec
        PrefVote::Core::TestNode
        PrefVote::Core::TestUtil
        PrefVote::Core
        PrefVote::Exception
        );
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

