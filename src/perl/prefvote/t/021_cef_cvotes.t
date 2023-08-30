#!/usr/bin/perl
# 021_cef_votes.t - tests for Condorcet Election Format (CEF) in PrefVote::Core::Input::CEF
use strict;
use warnings;
use autodie;
use feature qw(say);
use Carp    qw(croak);
use Test::More;
#use Test::More skip_all => "WIP";
use Test::Exception;
use Readonly;
use File::Basename qw(basename);
use Cwd            qw(getcwd);
use YAML::XS;
use Data::Dumper;
use PrefVote::Core::Input;

# constants for test fixtures
Readonly::Scalar my $input_dir           => getcwd() . "/t/test-inputs/" . basename( $0, ".t" );
Readonly::Scalar my $tests_per_good_file => 1;
Readonly::Scalar my $tests_per_bad_file  => 1;

# run tests per CEF test file
sub cef_file_tests
{
    my $filepath = shift;
    my $flags    = shift;

    # use file basename as test name
    my $test_name = basename($filepath);

    # check flags: if neither good or bad are set, default to good
    if ( not exists $flags->{bad} and not exists $flags->{good} ) {
        $flags->{good} = 1;    # if not bad, add good flag so it shows up on the flag summary string
    }
    my $flag_str = join " ", sort keys %$flags;

    # run tests
    my $input_doc;
    if ( $flags->{good} // 0 ) {
        lives_ok( sub { $input_doc = PrefVote::Core::Input->new( filepath => $filepath ); },
            "$test_name good as expected" );
    } else {
        dies_ok( sub { $input_doc = PrefVote::Core::Input->new( filepath => $filepath ); },
            "$test_name bad as expected" );
    }
}

# read list of test input files from subdirectory with same basename as this script
if ( !-d $input_dir ) {
    BAIL_OUT("can't find test inputs directory: expected $input_dir");
}
opendir( my $dh, $input_dir ) or BAIL_OUT("can't open $input_dir directory");
my @files = sort grep { /^[^.].*\.cvotes/ and -f "$input_dir/$_" } readdir($dh);
closedir $dh;

# load test metadata
my @test_metadata = YAML::XS::LoadFile("$input_dir/000-test-metadata.yml");
my $metadata;
if ( ref $test_metadata[0] eq "HASH" ) {
    $metadata = $test_metadata[0];
}

# count files by good and bad CEF syntax
my $good_total = 0;
my $bad_total  = 0;
foreach my $file (@files) {
    my $flags = {};
    if ( $metadata and exists $metadata->{$file} ) {
        if ( ref $metadata->{$file} eq "HASH" ) {
            $flags = $metadata->{$file};
        }
    }
    if ( exists $flags->{bad} ) {
        $bad_total++;
    } else {
        $good_total++;
    }
}

# compute number of tests: (flags are read from 000-test-metadata.yml)
# 1 test per good or bad file, but preserve option to change multipliers per type
plan tests => $tests_per_bad_file * $bad_total + $tests_per_good_file * $good_total;

# run cef_file_tests() for each file
foreach my $file (@files) {
    my $flags = {};
    if ( $metadata and exists $metadata->{$file} ) {
        if ( ref $metadata->{$file} eq "HASH" ) {
            $flags = $metadata->{$file};
        }
    }
    cef_file_tests( "$input_dir/$file", $flags );
}
