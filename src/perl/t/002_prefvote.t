#!/usr/bin/perl
# 002_prefvote.t - tests for top-level PrefVote class

use strict;
use warnings;
use autodie;

use Test::More tests => 8;
use Test::Exception;
use PrefVote;
use IO::Capture::Stderr;    # rpm: perl-IO-Capture, deb: libio-capture-perl

# test toggling debug flag
my $prefvote_obj = PrefVote->new();

# test debugging on or off
sub test_debug
{
    my $debug_flag = shift ? 1 : 0;

    # set up to capture STDERR
    my $capture = IO::Capture::Stderr->new();

    # set debugging on or off for test
    my $retval = PrefVote::debug($debug_flag);
    is($retval, $debug_flag, "return value matches parameter ($debug_flag)");
    is(PrefVote::debug(), $debug_flag, "debug mode is $debug_flag");
    $capture->start();
    $prefvote_obj->debug_print("testing");
    $capture->stop();
    my @lines = $capture->read();
    if ($debug_flag) {
        ok((scalar @lines) >= 1, "got STDERR output when debug is on");
    } else {
        ok((scalar @lines) == 0, "no STDERR output when debug is off");
    }
}

# test default value of debug - it's 0 unless set by PREFVOTE_DEBUG
# We're not bothering to make separate startup-time tests for the default.
# Just don't set PREFVOTE_DEBUG when you don't want it. This test adapts if it's set.
my $debug_env_set = exists $ENV{PREFVOTE_DEBUG};
my $debug_default = ($ENV{PREFVOTE_DEBUG} // 0) ? 1 : 0;
is(PrefVote::debug(), $debug_default, "debug defaults to $debug_default with PREFVOTE_DEBUG ".
    ($debug_env_set ? "set" : "unset"));

# test debug off and on
test_debug(0);
test_debug(1);

# test throwing PrefVote::Exception
throws_ok { PrefVote::Exception->throw({description => "test"})} "PrefVote::Exception", "throw PrefVote::Exception";
