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
Readonly::Scalar my $debug_mode          => ( ( $ENV{PREFVOTE_DEBUG} // 0 ) or ( $ENV{CEF_PARSER_DEBUG} // 0 ) ) and 1;
Readonly::Scalar my $input_dir           => getcwd() . "/t/test-inputs/" . basename( $0, ".t" );
Readonly::Scalar my $tests_per_good_file => 1;
Readonly::Scalar my $tests_per_bad_file  => 2;

# compute number of tests: (test case data are read from 000-test-metadata.yml)
# 1 test per good or bad file, but preserve option to change multipliers per type
sub count_tests
{
    my ( $metadata, @files ) = @_;

    # count files by good and bad CEF syntax
    my $good_total = 0;
    my $bad_total  = 0;
    foreach my $file (@files) {
        my $test_case = {};
        if ( $metadata and exists $metadata->{$file} ) {
            if ( ref $metadata->{$file} eq "HASH" ) {
                $test_case = $metadata->{$file};
            }
        }
        if ( exists $test_case->{error} ) {
            $bad_total++;
        } else {
            $good_total++;
        }
    }
    return $tests_per_bad_file * $bad_total + $tests_per_good_file * $good_total;
}

# run tests per CEF test file
sub cef_file_tests
{
    my $filepath  = shift;
    my $test_case = shift;
    my $test_group = shift;
    $debug_mode and say STDERR "debug: cef_file_tests($filepath)";

    # use file basename as test name
    my $test_name = basename($filepath);

    # stringify test case data for test name
    my $flag_str = join " ", sort keys %$test_case;

    # run tests
    my $input_doc;
    if ( not exists $test_case->{error} ) {
        lives_ok( sub { $input_doc = PrefVote::Core::Input->new( filepath => $filepath ); },
            "$test_group: $test_name / good as expected" );
    } else {
        my $err_regex = $test_case->{error};
        dies_ok( sub { $input_doc = PrefVote::Core::Input->new( filepath => $filepath ); },
            "$test_group: $test_name / bad as expected" );
        my $err_result = $@;
        $debug_mode and say STDERR "$test_group: $test_name / result: error $err_result";
        like( $err_result, qr($err_regex), "$test_group: $test_name / expected error: $err_regex" );
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

# declare test count
plan tests => count_tests( $metadata, @files );

# run cef_file_tests() for each file
my $test_group = 1;
foreach my $file (@files) {
    my $test_case = {};
    if ( $metadata and exists $metadata->{$file} ) {
        if ( ref $metadata->{$file} eq "HASH" ) {
            $test_case = $metadata->{$file};
        }
    }
    cef_file_tests( "$input_dir/$file", $test_case, $test_group );
    $test_group++;
}
