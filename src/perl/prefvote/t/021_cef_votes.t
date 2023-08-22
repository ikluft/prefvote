#!/usr/bin/perl
# 021_cef_votes.t - tests for PrefVote::Core

use strict;
use warnings;
use autodie;
use feature qw(say);
#use Test::More skip_all => "WIP TBD CYA TTFN";
use Test::More tests => 1;
use Test::Exception;
use File::Basename qw(basename);
use Readonly;
use Cwd qw(getcwd);
use Set::Tiny qw(set);
use YAML::XS;
use PrefVote::Core;
use PrefVote::Core::Ballot;
use PrefVote::Core::Input::CEF_Parser;

# temp
use Devel::Symdump;
my $symtab = Devel::Symdump->rnew( qw(PrefVote::Core::Input::CEF_Parser) );
say "functions:";
say "  " . join( "\n  ", sort $symtab->functions());
say;
say "isa_tree:";
say Devel::Symdump->isa_tree;

# input directory for CEF data files
Readonly::Scalar my $input_dir => getcwd() . "/t/test-inputs/" . basename( $0, ".t" );
# Readonly::Array my @ranking_tests => (
#   { in => "A = B > C = D > E = F", out => {} },
# );

# Condorcet Election Format (CEF) file tests
my $parser1 = PrefVote::Core::Input::CEF_Parser->new();
isa_ok( $parser1, "PrefVote::Core::Input::CEF_Parser", "parser1");

1;
