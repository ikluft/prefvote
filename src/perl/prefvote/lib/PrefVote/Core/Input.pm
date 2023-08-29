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
use Carp qw(croak);
use Readonly;
use File::Basename;
use YAML::XS;
use PrefVote::Core::Exception;
use PrefVote::Core::Input::CEF;

#
# class definition via Moo
#
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common qw(Str Int ArrayRef HashRef Map NonEmptySimpleStr);
extends 'PrefVote';

# input file path
has filepath => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# vote definition
has vote_def => (
    is  => 'rw',
    isa => HashRef [ NonEmptySimpleStr | HashRef ],
);

# ballot list
has ballots => (
    is          => 'rw',
    isa         => ArrayRef [ ArrayRef [NonEmptySimpleStr] ],
    handles_via => 'Array',
    handles     => {
        ballot_all   => 'all',
        ballot_count => 'count',
        ballot_get   => 'get',
        ballot_empty => 'is_empty',
        ballot_push  => 'push',
        ballot_set   => 'set',
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
# YAML parser functions
#

# parse YAML
# $filepath parameter should already be checked for existence before calling
sub parse_yaml
{
    my $self     = shift;
    my $filepath = $self->filepath();

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

    return;
}

#
# Condorcet Election Format (CEF) parser functions
#

# parse Condorcet Election Format (defined at https://github.com/CondorcetVote/CondorcetElectionFormat )
# $filepath parameter should already be checked for existence before calling
sub parse_cef
{
    my $self     = shift;
    my $filepath = $self->filepath();

    # use PrefVote::Core::Input::CEF to parse the CEF file
    my $cef_data = PrefVote::Core::Input::CEF->new(filepath => $filepath);

    # copy data from PrefVote::Core::Input::CEF object into self
    $cef_data->xfer($self);
    return;
}

#
# common parser functions for YAML and CEF
#

# read vote file input from YAML or Condorcet Election Format (CEF)
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
        $self->parse_yaml()
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
    my %input_doc = PrefVote::Core::Input->new(filepath => $filepath);


=head1 DESCRIPTION

=head1 SEE ALSO

L<PrefVote::Core>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
