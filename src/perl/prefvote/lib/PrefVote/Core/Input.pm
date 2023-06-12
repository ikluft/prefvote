# PrefVote::Core::Input
# ABSTRACT: file input parsing for PrefVote
# Copyright (c) 1998-2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Input;

use utf8;
use feature qw(say fc);
use autodie;
use Carp qw(croak confess);
use File::Basename;
use YAML::XS;

#
# class definition via Moo
#
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard       qw(Str Int ArrayRef HashRef Map);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote';

# input file path
has filepath => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# vote definition
has vote_def => (
    is      => 'rw',
    isa => HashRef [ NonEmptySimpleStr | HashRef ],
    handles_via => 'Hash',
    handles     => {
        vote_def_exists => 'exists',
        vote_def_get    => 'get',
        vote_def_keys   => 'keys',
        vote_def_set    => 'set',
    },
);

# ballot list
has ballots => (
    is      => 'rw',
    isa     => ArrayRef [ ArrayRef [ NonEmptySimpleStr ]],
    handles_via => 'Array',
    handles => {
        ballot_all   => 'all',
        ballot_count => 'count',
        ballot_empty => 'is_empty',
        ballot_push  => 'push',
    },
);

# data for black box testing
has test_data => (
    is          => 'rw',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        test_data_all   => 'all',
        test_data_count => 'count',
        test_data_empty => 'is_empty',
    },
);

# Moo build routine is called by Moo-provided new() method after processing arguments
# use this to call read_vote_file()
sub BUILD
{
    my $self = shift;
    $self->read_vote_file();
    return;
}

#
# parser functions
#

# parse Condorcet Election Format (defined at https://github.com/CondorcetVote/CondorcetElectionFormat )
# $filepath parameter should already be checked for existence before calling
sub parse_cef
{
    my $self     = shift;
    my $filepath = $self->filepath();
    my %params;

    # read file and process lines
    ## no critic (RequireBriefOpen)
    open( my $fh, "<", $filepath )
        or PrefVote::Core::Exception->throw( description => "couldn't open $filepath: $!" );
    while ( my $line = <$fh> ) {
        chomp $line;

        # election definition parameters
        if ( $line =~ /^ \s* # \/ \s* ([\w ]+?) \s* : \s* (.*?) \s* $/x ) {
            my ( $param_name, $param_value ) = ( $1, $2 );
            if ( not $self->ballot_empty() ) {
                PrefVote::Core::Exception->throw(
                    description => "parse_cef($filepath): can't define $param_name after first ballot line" );
            }
            if ( exists $params{$param_name} ) {
                PrefVote::Core::Exception->throw( description => "parse_cef($filepath): can't redefine $param_name" );
            }
            $params{$param_name} = $param_value;
            next;
        }

        # remove comments from the end of each line, up to the whole line
        $line =~ s/\s* # .*//x;

        # skip empty lines, which may or may not have formerly been comments
        if ( $line =~ /^ \s* $/x ) {
            next;
        }

        # process ballot line
        my %line_params;
        if ( $line =~ /^ \s* ( .*? ) \s* \|\|/x ) {

            # keep tags and remove from the ballot line
            my $tag_str = $1;
            $line_params{tags} = split /\s* , \s*/x, $tag_str;
            substr $line, 0, length($tag_str), "";    # remove tags from beginning of line
        }
        if ( $line =~ /\s* \* \s* (\d+) \s* $/x ) {

            # keep quantifier and remove from the ballot line
            my $quantifier_str = $1;
            $line_params{quantifier} = $quantifier_str;
            substr $line, -length($quantifier_str), length($quantifier_str), "";    # remove quantifier from end of line
        }
        if ( $line =~ /\s* \^ \s* (\d+) \s* $/x ) {

            # keep weight and remove from the ballot line
            my $weight_str = $1;
            $line_params{weight} = $weight_str;
            substr $line, -length($weight_str), length($weight_str), "";            # remove weight from end of line
        }
        if ( $line =~ qr(^ \s* /EMPTY_RANKING/ \s* $ )x ) {

            # save the empty ranking as-is initially
            # fill it in on second pass in case candidate names were not specified and are collected from ballots
            $self->ballot_push( ['/EMPTY_RANKING/'] );
            next;
        }

        # parse candidate preference order
        my @pref_order = $self->cef_fetch_prefs( $line, \%line_params );
        $self->ballot_push( \@pref_order );
    }

    # clean up
    close $fh
        or PrefVote::Core::Exception->throw( description => "couldn't close $filepath: $!" );
    ## critic (RequireBriefOpen)

    # 2nd pass: enumerate candidates and handle empty rankings
    $self->handle_empty_rankings();

    # save CEF data to PrefVote vote definition & ballot docs
    if ( exists $params{'Number of Seats'} ) {
        $self->{vote_def}{seats} = int( $params{'Number of Seats'} );
    }
    return;
}

# read vote file input from YAML or Condorcet Election Format
sub read_vote_file
{
    my $self     = shift;
    my $filepath = $self->filepath();

    # verify input file exists
    ( -e $filepath ) or PrefVote::Core::Exception->throw( description => "$filepath not found" );
    ( -f $filepath )
        or PrefVote::Core::Exception->throw( description => "$filepath not a regular file" );

    # process file name
    my ( $basename, $dirs, $suffix ) = File::Basename::fileparse( $filepath, ".yaml", ".yml", ".cvotes" );

    # handle YAML or CEF files
    if ( $suffix eq ".yaml" or $suffix eq ".yml" ) {

        # parse YAML
        my @yaml_docs = eval { YAML::XS::LoadFile($filepath) };
        if ($@) {
            PrefVote::Core::Exception->throw( description => "$0: error reading $filepath: $@" );
        }
        if ( scalar @yaml_docs < 2 ) {
            PrefVote::Core::Exception->throw( description => "$0: error reading $filepath: not enough YAML sections" );
        }

        # save 1st YAML document as vote definition
        $self->vote_def( shift @yaml_docs );

        # save 2nd YAML document as ballot list
        $self->ballots( shift @yaml_docs );

        # save any additional YAML documents as test data
        $self->test_data( [@yaml_docs] );    # will be empty if no test data
    } elsif ( $suffix eq ".cvotes" ) {

        # parse Condorcet Election Format
        $self->parse_cef();
    } else {
        PrefVote::Core::Exception->throw( description => "$0: unrecognized vote file type" );
    }

    # if not already provided in primary file, read test data from *-test.yaml alongside primary input file
    if ( ( not exists $self->{test_data} ) or scalar @{ $self->{test_data} } == 0 ) {
        for my $test_suffix (qw(yml yaml)) {
            my $test_path = $dirs . $basename . "-test." . $test_suffix;
            if ( -f $test_path ) {
                $self->{test_data} = eval { YAML::XS::LoadFile($test_path) };
                if ($@) {
                    PrefVote::Core::Exception->throw( description => "$0: error reading test data in $test_path: $@" );
                }
                last;
            }
        }
    }
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

As called from PrefVote::Core:

    use PrefVote::Core::Input;

    # ...
    my %input_doc = PrefVote::Core::Input->new($filepath);


=head1 DESCRIPTION

=head1 SEE ALSO

L<PrefVote::Core>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
