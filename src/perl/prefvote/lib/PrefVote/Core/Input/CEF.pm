# PrefVote::Core::Input::CEF
# ABSTRACT: PrefVote interface to Condorcet Election Format (CEF) parser
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Input::CEF;

use utf8;
use feature qw(say fc);
use autodie;
use Carp qw(carp croak confess);
use Readonly;
use PrefVote::Core::Input::CEF_Parser;

#
# PrefVote::Core::Input::CEF parses Condorcet Election Format. CEF is defined at
# https://github.com/CondorcetVote/CondorcetElectionFormat
#

#
# constants
#

# debug mode from environment variable
Readonly::Scalar my $debug_mode => ( ( $ENV{PREFVOTE_DEBUG} // 0 ) or ( $ENV{CEF_PARSER_DEBUG} // 0 ) ) and 1;

# default vote title for CEF
# The format doesn't officially provide a way to set a title. PrefVote unofficially recognizes "Title" parameter
Readonly::Scalar my $cef_default_title => "Condorcet Election";

# default voting method for CEF
# PrefVote requires a method. But CEF doesn't require one. Use this to resolve the conflict.
Readonly::Scalar my $cef_default_method => "RankedPairs";

# required parameters for new objects
Readonly::Array my @required_params => ( qw(filepath) );

# map CEF parameter names to PrefVote::Core parameter names
Readonly::Hash my %cef2pv => (
    'title' => 'name',
    'number of seats' => 'seats',
    'voting method' => 'method',
    'voting methods' => 'method',
);

# map CEF keys to PrefVote::Core flag names
# initally these are conversion from capitalized words to snake-case string, but flexible for expansion
Readonly::Hash my %cef2flags => (
    'implicit ranking' => 'implicit_ranking',
    'weight allowed'   => 'weight_allowed',
);

# names for ballot operators
Readonly::Hash my %op_names => (
    '*' => 'quantifier',
    '^' => 'weight',
);

#
# class management functions
# In order to minimize dependencies so independent modules can parse CEF with this, we do not inherit 
# from PrefVote or use Moo where this functionality would have been provided.
# If others express interest, PrefVote::Core::Input::CEF can be spun off to a separate CPAN module.
#

# instantiate a new object
# class method
sub new
{
    my ( $in_class, @args ) = @_;
    my $class = ref($in_class) || $in_class;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->new() prohibited for unrelated class $class";
    }

    # instantiate and initialize object
    my $self = {};
    bless $self, $class;
    $self->init(@args);
    return $self;
}

# initialize object
sub init
{
    my ( $self, %args ) = @_;
    my $class = ref $self;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->new() prohibited for unrelated class $class";
    }
    
    # initialize parameters
    $self->{_in_keys} = [ keys %args ];
    foreach my $key ( @{$self->{_in_keys}} ) {
        $self->{$key} = $args{$key};
    }

    # chack for missing required parameters
    my @missing;
    foreach my $required ( @required_params ) {
        exists $self->{$required} or push @missing, $required;
    }
    if (@missing) {
        confess $class. "->init() missing required parameters: " . join( " ", @missing );
    }

    # parse the CEF file and collect its data
    $self->parse();
    return $self;
}

# debugging output
# instance method
sub debug_print
{
    my ( $self, @args ) = @_;
    my $class = ref $self;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->debug_print() prohibited for unrelated class $class";
    }

    # print only if object has debug flag and it is set
    if ( $debug_mode or ( exists $self->{debug} and $self->{debug})) {
        say STDERR $class . ": " . join( " ", @args );
    }
    return;
}

# for testing/debugging: convert vote definition structure into a string
# recursive function to return a string for a vote definition structure or a portion within one
sub _votedef2str
{
    my $vote_def = shift;

    # if we got a scalar, treat it as a leaf node and return it
    if ( not ref $vote_def ) {
        return $vote_def;
    }

    # handle array
    if ( ref $vote_def eq "ARRAY" ) {
        return '[' . join(",", map( _votedef2str($_), @$vote_def)) . ']';
    }

    # handle hash
    if ( ref $vote_def eq "HASH" ) {
        return '{' . join(",", map($_ . "=>" . _votedef2str($vote_def->{$_}), sort keys %$vote_def)) . '}';
    }

    # otherwise stringify it
    return "" . $vote_def;
}

# convert string to boolean flag
sub _str2bool
{
    my $str_in = shift;
    if ( $str_in eq "1" or $str_in eq "true" or $str_in eq "yes") {
        return 1;
    }
    if ( $str_in eq "0" or $str_in eq "false" or $str_in eq "no") {
        return 0;
    }
    croak "_str2bool: unrecognized boolean value '$str_in'";
}

#
# Condorcet Election Format (CEF) parser functions
#

# collect candidate list from ballots when no candidate list is provided
# note: this is not necessarily a good practice because erroneous candidates on ballots usually should be discarded
# instance method
sub enumerate_candidates
{
    my $self = shift;

    my %candidates_seen;

    # find all the unique candidates from the ballots
    foreach my $ballot ( $self->ballot_all() ) {
        foreach my $item (@$ballot) {
            my $item_no_ws = $item;
            $item_no_ws =~ s/^ \s+ //x;
            $item_no_ws =~ s/\s+ $//x;
            foreach my $subitem ( split qr(\s* [/=] \s*)x, $item_no_ws ) {
                if ( not exists $candidates_seen{$subitem} ) {
                    $candidates_seen{$subitem} = 1;
                }
            }
        }
    }

    return keys %candidates_seen;
}

# 2nd pass: enumerate candidates and handle empty rankings
# instance method
sub cef_second_pass
{
    my $self       = shift;

    # if a candidate list wasn't provided then collect them from ballots
    my @candidates;
    if ( exists $self->{_cef_param}{candidates} ) {
        $self->{_cef_param}{candidates} =~ s/^ \s+//x;    # remove whitespace at start of line
        $self->{_cef_param}{candidates} =~ s/\s+ $//x;    # remove whitespace at end of line
        @candidates = split /\s* ; \s*/x, $self->{_cef_param}{candidates};
    } else {
        @candidates = $self->enumerate_candidates();
    }

    # convert CEF candidate list to PrefVote choices hash
    # note: CEF doesn't provide a separate abbreviation and full string - use candidate name for both
    my %choices;
    foreach my $candidate_name (@candidates) {
        $choices{$candidate_name} = $candidate_name;
    }
    if ( not exists $self->{vote_def}{params}) {
        $self->{vote_def}{params} = {};
    }
    $self->{vote_def}{params}{choices} = \%choices;

    # scan ballots for explicit /EMPTY_RANKING/ marker
    my $ballot_count = scalar @{$self->{ballots}};
    for ( my $ballot_index = 0 ; $ballot_index < $ballot_count ; $ballot_index++ ) {
        my $ballot = $self->{ballots}[$ballot_index];
        if ( ( scalar @$ballot ) == 1 and $ballot->[0] =~ qr(^ \s* \/EMPTY_RANKING\/ \s* $)x ) {
            $self->ballot_set( $ballot_index, [] );
        }
    }

    return;
}

# save a CEF parameter
# save as PrefVote vote_def data
# mark the CEF param original name as seen to catch duplicates
sub set_cef_param
{
    my ( $self, $cef_param_name, $value ) = @_;

    # record CEF parameters already seen
    if ( not exists $self->{_cef_param}) {
        $self->{_cef_param} = {};
    }
    if ( $self->{_cef_param}{$cef_param_name} // 0 ) {
        croak( __PACKAGE__ . ": can't redefine $cef_param_name" );
    }
    $self->{_cef_param}{$cef_param_name} = 1;

    # save parameter under PrefVote name
    if ( exists $cef2pv{$cef_param_name}) {
        $self->{vote_def}{$cef2pv{$cef_param_name}} = $value;
    } elsif ( exists $cef2flags{$cef_param_name}) {
        if ( not exists $self->{vote_def}{params}) {
            $self->{vote_def}{params} = {};
        }
        $self->{vote_def}{params}{$cef2flags{$cef_param_name}} = _str2bool( $value );
    } else {
        #carp( __PACKAGE__ . ":unrecognized CEF parameter $cef_param_name" );
    }
    return;
}

# read a CEF parameter
sub get_cef_param
{
    my ( $self, $cef_param_name ) = @_;
    return if not exists $self->{_cef_param}{$cef_param_name};
    return $self->{_cef_param}{$cef_param_name};
}

# check if a CEF parameter was already set
sub seen_cef_param
{
    my ( $self, $cef_param_name ) = @_;
    return exists $self->{_cef_param}{$cef_param_name};
}

# parse Condorcet Election Format (defined at https://github.com/CondorcetVote/CondorcetElectionFormat )
# $filepath parameter should already be checked for existence before calling
# instance method
sub parse
{
    my $self     = shift;
    my $filepath = $self->get("filepath");
    $self->debug_print("parse($filepath)");

    # initialize empty vote parameters, ballot list & test data
    $self->{vote_def} = { method => $cef_default_method, params => {} };
    $self->{ballots} = [];
    $self->{test_data} = [];

    # instantiate a parser
    my $parser = PrefVote::Core::Input::CEF_Parser->new();

    # read file and process lines
    ## no critic (RequireBriefOpen)
    open( my $fh, "<", $filepath )
        or croak( __PACKAGE__ . "->parse() couldn't open $filepath: $!" );
    while ( my $line = <$fh> ) {
        chomp $line;
        $self->debug_print("parse: line=$line");

        # election definition parameters
        if ( $line =~ qr(^ \s* \#/ \s* ([\w\s]+?) \s* : \s* (.*?) \s* $)x ) {
            $self->debug_print("CEF definition line: $1 - $2");
            my ( $param_name, $param_value ) = ( fc $1, $2 );
            if ( scalar @{$self->{ballots}} > 0 ) {
                croak( __PACKAGE__ . "->parse($filepath): can't define $param_name after first ballot line" );
            }
            if ( $self->seen_cef_param( $param_name )) {
                croak( __PACKAGE__ . "->parse($filepath): can't redefine $param_name" );
            }
            $self->set_cef_param( $param_name, $param_value );
            next;
        }

        # remove comments from the end of each line, up to the whole line
        $line =~ s/\s* \# .*//x;

        # skip empty lines, which may or may not have formerly been comments
        if ( $line =~ /^ \s* $/x ) {
            next;
        }

        #
        # process ballot line
        #

        # parse candidate preference order from line
        my @pref_order = $parser->parse( $line, $self->{vote_def} );
        push @{$self->{ballots}}, \@pref_order;
        $self->debug_print( "parse: pref_order=" . _votedef2str( @pref_order ) );
    }

    # clean up
    close $fh
        or croak( __PACKAGE__ . "->parse(): couldn't close $filepath: $!" );
    ## critic (RequireBriefOpen)

    # 2nd pass: enumerate candidates and handle empty rankings
    $self->cef_second_pass();

    #
    # save CEF data to PrefVote vote definition & ballot docs
    #

    # use default title if not set
    if ( not exists $self->{vote_def}{params}{name}) {
        if ( not exists $self->{vote_def}{params}) {
            $self->{vote_def}{params} = {};
        }
        $self->{vote_def}{params}{name} = $cef_default_title;
    }

    return;
}

# get list of data keys
# instance method
sub get_keys
{
    my $self = shift;
    return keys %$self;
}

# read accessor for data
# instance method
sub get
{
    my ($self, $key) = @_;
    return if not exists $self->{$key};
    return $self->{$key};
}

# transfer data to another object
# instance method
sub xfer
{
    my ($self, $recipient) = @_;
    my @skipped;

    # hashify list of input parameter keys so we know not to warn since they usually exist in destination
    my %in_keys = grep { return ($_ => 1) } @{$self->{_in_keys}};
    
    # transfer object fields to destination, except internal-only or those already existing in desetination
    foreach my $key (keys %$self) {
        if (substr($key, 0, 1) eq "_") {
            # skip transfer for internal-only data prefixed with underscore "_"
            next;
        }
        if (exists $recipient->{$key}) {
            # only warn about a field conflict if it wasn't in the input paramerters
            if (not exists $in_keys{$key}) {
                # do not overwrite data in the recipient object - warn about it
                push @skipped, $key;
            }
        } else {
            # copy item
            $recipient->{$key} = $self->{$key};
        }
    }
    if (@skipped) {
        carp "warning: skipped transfer of CEF data in conflict with existing data ".join(" ", @skipped);
    }
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<PrefVote::Core>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

