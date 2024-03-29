#!/usr/bin/env perl
# 990_author-critic.t
# test Perl::Critic against Perl source files, except those generated by programs we don't control
#
# This replaces the auto-generated author-critic.t which cannot be prevented from including Parse::Yapp-generated
# files. Perl::Critic doesn't honor instructions to disable checks on the included Parse::Yapp::Driver. This
# solves that Catch-22 by making our own Perl::Critic author tests.
#
# by Ian Kluft
#
use strict;
use warnings;
use utf8;
use autodie;
use feature qw(fc say);

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} // 0 ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use File::Basename qw(fileparse);
use Perl::Critic::Utils;
use Test::Perl::Critic ( -profile => "perlcritic.rc" ) x !!-e "perlcritic.rc";
use Readonly;

# file blacklist
Readonly::Array my @BLACKLIST => (qw( PrefVote/Core/Input/CEF_Parser.pm ));

# test if a file is generated by a program which will break Perl::Critic testing
sub is_generated
{
    my $filename = shift;
    my ( $base, $dir, $suffix ) = fileparse( $filename, qw(.pm) );

    # easy: if corresponding .yp file exists, it's generated
    if ( $suffix eq ".pm" and -f $dir . "/" . $base . ".yp" ) {
        return 1;
    }

    # use a blacklist so we won't have to open each file to look for Parse::Yapp::Driver inclusion
    foreach my $bl_item (@BLACKLIST) {
        if ( $filename eq $bl_item
            or substr( $filename, -length($bl_item), length($bl_item) ) eq $bl_item )
        {
            return 1;
        }
    }
    return 0;
}

# search for Perl sources, except for those generated by Parse::Yapp
my $search_dir = -e 'blib' ? 'blib' : 'lib';
my @all_files  = Perl::Critic::Utils::all_perl_files($search_dir);
my @filtered_files;
foreach my $filename (@all_files) {

    # exclude generated files
    if ( not is_generated($filename) ) {
        push @filtered_files, $filename;
    }
}

# debug: check file list
if ( $ENV{AUTHOR_DEBUG_CRITIC_FILES} // 0 ) {
    say STDERR "file list:";
    say STDERR join "\n", @filtered_files;
}

# run Perl::Critic tests on Perl sources
all_critic_ok(@filtered_files);
