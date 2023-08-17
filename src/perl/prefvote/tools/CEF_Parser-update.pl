#!/usr/bin/env perl
# CEF_Parser-update.pl - use Parse::Yapp to update CEF_Parser.pm from CEF_Parser.yp & CEF_Parser-template
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
#
# Run this to update the generated parser code after modifications to the CEF grammar.
use strict;
use warnings;
use utf8;
use autodie;
use feature qw(say);
use v5.10.0;
use Carp qw(carp croak);
use Readonly;
use FindBin        qw($Bin $Script);
use File::Basename qw(dirname);
use File::Slurp    qw(read_file);
use Try::Tiny;

# constants
Readonly::Scalar my $TOOLS_PATH    => $Bin;
Readonly::Scalar my $PROG_PATH     => $TOOLS_PATH . "/" . $Script;
Readonly::Scalar my $SOURCE_ROOT   => dirname($TOOLS_PATH);
Readonly::Scalar my $UPDATE_PATH   => $SOURCE_ROOT . "/lib/PrefVote/Core/Input/";
Readonly::Scalar my $CLASS_PREFIX  => "PrefVote::Core::Input::";
Readonly::Scalar my $CEF_BASE      => "CEF_Parser";
Readonly::Scalar my $CEF_GRAMMAR   => $UPDATE_PATH . "/" . $CEF_BASE . ".yp";
Readonly::Scalar my $PM_OUT_PATH   => $UPDATE_PATH . "/" . $CEF_BASE . ".pm";
Readonly::Scalar my $PACKAGE       => $CLASS_PREFIX . $CEF_BASE;
Readonly::Scalar my $TEMPLATE_PATH => $TOOLS_PATH . "/CEF_Parser-template";
Readonly::Hash my %REQUIRED_FILES => (
    $CEF_GRAMMAR   => "CEF grammar input",
    $TEMPLATE_PATH => "Parse::Yapp template",
);

# verify we found files to work with
my @missing;
foreach my $req_file ( keys %REQUIRED_FILES ) {
    if ( not -f $req_file ) {
        push @missing, $req_file;
    }
}
if (@missing) {
    say STDERR "missing required files - expected paths based on script location:";
    foreach my $file (@missing) {
        say STDERR "   " . $REQUIRED_FILES{$file} . " " . $file;
    }
    exit 1;
}

# check dependencies - skip if update not needed
if ( -f $PM_OUT_PATH
        and -M $PROG_PATH > -M $PM_OUT_PATH
        and -M $CEF_GRAMMAR > -M $PM_OUT_PATH
        and -M $TEMPLATE_PATH > -M $PM_OUT_PATH )
{
    exit 0;
}

# load Parse::Yapp or report that it's missing
try {
    require Parse::Yapp;
} catch {
    croak "failed to load Parse::Yapp module: $_";
};

# run Parse::Yapp to build CEF parser
my $template_text = read_file($TEMPLATE_PATH);
my $parser        = Parse::Yapp->new( inputfile => $CEF_GRAMMAR );
open my $out, ">", $PM_OUT_PATH
    or croak "cannot open $PM_OUT_PATH for writing: $!";
print $out $parser->Output(
    classname   => $PACKAGE,
    standalone  => 1,
    linenumbers => 1,
    template    => $template_text,
);
close $out
    or croak "cannot close $PM_OUT_PATH: $!";

