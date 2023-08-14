# PrefVote::Core::Input::CEF
# ABSTRACT: parse Condorcet Election Format (CEF) input files
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

#
# constants
#

# default vote title for CEF
# The format doesn't officially provide a way to set a title. PrefVote unofficially recognizes "Title" parameter
Readonly::Scalar my $cef_default_title => "Condorcet Election";

# default voting method for CEF
# PrefVote requires a method. But CEF doesn't require one. Use this to resolve the conflict.
Readonly::Scalar my $cef_default_method => "RankedPairs";

# required parameters for new objects
Readonly::Array my @required_params => ( qw(filepath) );

# map CEF keys to PrefVote::Core flag names
# initally these are conversion from capitalized words to snake-case string, but flexible for expansion
Readonly::Hash my %cef2flags => (
    'Implicit Ranking' => 'implicit_ranking',
    'Weight Allowed'   => 'weight_allowed',
);

# names for ballot operators
Readonly::Hash my %op_names => (
    '*' => 'quantifier',
    '^' => 'weight',
);

# CEF token regular expressions
Readonly::Hash my %CEF_TOKENS => (
    EMPTY_RANKING => qr(/EMPTY_RANKING/)x,
    TAGDELIM => qr([|][|])x,
    ',' => qr([,])x,
    '^' => qr([\^])x,
    '*' => qr([*])x,
    '=' => qr([=])x,
    '>' => qr([>])x,
    INT => qr(\d+)x,
    WORD => qr(\w+)x,
);

#
# class management functions
# In order to minimize dependencies so independent modules can parse CEF with this, we do not inherit 
# from PrefVote or use Moo. If others express interest, this can be spun off to a separate CPAN module.
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
    foreach my $key ( keys %args ) {
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
    if ( exists $self->{debug} and $self->{debug}) {
        say STDERR $class . ": " . join( " ", @args );
    }
    return;
}

#
# Condorcet Election Format (CEF) parser functions
#

# parse candidate preference order
# instance method
sub cef_fetch_prefs
{
    my ( $self, $line, $line_params ) = @_;
    my @pref_order;

    # filter out invalid empty ballot (use /EMPTY_RANKING/ for explicit empty ballot)
    if ( $line =~ /^ \s* $/x ) {
        $self->debug_print("cef_fetch_prefs: drop empty ballot");
        return;
    }

    # parse candidate preference order from string
    while ( length($line) > 0 ) {

        # handle line with no > or =
        if ( $line !~ /[>=]/x ) {
            if ( $line =~ qr(^ \s* ( \w+ ) \s* $)x ) {
                $self->debug_print("cef_fetch_prefs: record ballot for $1");
                push @pref_order, [$1];
                $line = "";
                last;
            } else {
                $self->debug_print("cef_fetch_prefs: drop non-empty misformatted ballot");
                return;    # parse error - drop ballot
            }
        }

        # handle line with > or =
        if ( $line =~ qr(^ ( ( \s* \w+ \s* = )* \s* \w+ \s* ) )x ) {
            # '=' operator marks equality
            my $match = $1;
            substr $line, 0, length $match, "";    # remove matched segment from line
            $match =~ s/^ \s* //x;                 # remove leading whitespace
            $match =~ s/ \s* $//x;                 # remove trailing whitespace
            my @cand = split qr( \s* = \s* )x, $match;
            push @pref_order, [@cand];
            $self->debug_print("cef_fetch_prefs: record ballot for: ".(join "=", @cand));
        }
        if ( $line =~ qr(^ ( \s* [>] \s* ) )x ) {
            # '>' operator marks preference
            my $match = $1;
            substr $line, 0, length $match, "";    # remove matched segment from line
            $match =~ s/^ \s* //x;                 # remove leading whitespace
            $match =~ s/ \s* $//x;                 # remove trailing whitespace
            # TODO
        }
    }

    # prepend line paremeters
    if ( ref $line_params eq "HASH" and scalar keys %$line_params > 0 ) {
        unshift @pref_order, $line_params;
    }
    return @pref_order;
}

# collect candidate list from ballots when no candidate list is provided
# note: this is not necessarily a good practice because erroneous candidates on ballots usually should be discarded
# instance method
sub enumerate_candidates
{
    my $self = shift;

    #my $params_ref = shift;
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
    my $params_ref = shift;

    # if a candidate list wasn't provided then collect them from ballots
    my @candidates;
    if ( exists $params_ref->{candidates} ) {
        $params_ref->{candidates} =~ s/^ \s+//x;    # remove whitespace at start of line
        $params_ref->{candidates} =~ s/\s+ $//x;    # remove whitespace at end of line
        @candidates = split /\s* ; \s*/x, $params_ref->{candidates};
    } else {
        @candidates = $self->enumerate_candidates($params_ref);
    }

    # convert CEF candidate list to PrefVote choices hash
    # note: CEF doesn't provide a separate abbreviation and full string - use candidate name for both
    my %choices;
    foreach my $candidate_name (@candidates) {
        $choices{$candidate_name} = $candidate_name;
    }
    $self->{vote_def}{params}{choices} = \%choices;

    # scan ballots for explicit /EMPTY_RANKING/ marker
    my $ballot_count = $self->ballot_count();
    for ( my $ballot_index = 0 ; $ballot_index < $ballot_count ; $ballot_index++ ) {
        my $ballot = $self->ballot_get($ballot_index);
        if ( ( scalar @$ballot ) == 1 and $ballot->[0] =~ qr(^ \s* \/EMPTY_RANKING\/ \s* $)x ) {
            $self->ballot_set( $ballot_index, [] );
        }
    }

    return;
}

# parse Condorcet Election Format (defined at https://github.com/CondorcetVote/CondorcetElectionFormat )
# $filepath parameter should already be checked for existence before calling
# instance method
sub parse
{
    my $self     = shift;
    my $filepath = $self->filepath();
    my %params;
    $self->debug_print("parse($filepath)");

    # initialize empty vote parameters, ballot list & test data
    $self->vote_def( { method => $cef_default_method, params => {} } );
    $self->ballots( [] );
    $self->test_data( [] );

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
            if ( not $self->ballot_empty() ) {
                croak( __PACKAGE__ . "->parse($filepath): can't define $param_name after first ballot line" );
            }
            if ( exists $params{$param_name} ) {
                croak( __PACKAGE__ . "->parse($filepath): can't redefine $param_name" );
            }
            $params{$param_name} = $param_value;
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

        # parse tags, remove from beginning of line
        my %line_params;
        my $tag_index = index $line, '||';
        if ( $tag_index != -1 ) {

            # keep tags and remove from the ballot line
            my $tag_str = substr $line, 0, $tag_index;
            $tag_str =~ s/^ \s+ //x;
            $tag_str =~ s/\s+ $//x;
            $line_params{tags} = split /\s* , \s*/x, $tag_str;
            $self->debug_print( "parse: tags=" . $line_params{tags} );
            substr $line, 0, $tag_index + 2, "";    # remove tags from beginning of line
        }

        # parse quantifier and weight, remove from end of line
        while ( $line =~ /(\s* ([*^]) \s* (\d+) \s* )$/x ) {

            # keep quantity and remove substring from the ballot line
            my $match    = $1;
            my $op       = $2;
            my $quantity = $3;
            if ( not exists $op_names{$op} ) {
                croak( __PACKAGE__ . "->parse(): should not happen: unrecognized operator $op" );
            }
            my $op_name = $op_names{$op};
            if ( exists $line_params{$op_name} ) {
                croak( __PACKAGE__ . "->parse(): error: $op_name specified more than once" );
            }
            $line_params{$op_name} = $quantity;
            $self->debug_print( "parse: $op_name=" . $line_params{$op_name} );
            substr $line, -length($match), length($match), "";    # remove matching substring from end of line
        }

        # process empty ranking
        if ( $line =~ qr(^ \s* /EMPTY_RANKING/ \s* $ )x ) {

            # save the empty ranking as-is initially
            # fill it in on second pass in case candidate names were not specified and are collected from ballots
            $self->ballot_push( ['/EMPTY_RANKING/'] );
            $self->debug_print("parse: got /EMPTY_RANKING/");
            next;
        }

        # parse candidate preference order
        my @pref_order = $self->cef_fetch_prefs( $line, \%line_params );
        $self->ballot_push( \@pref_order );
        $self->debug_print( "parse: pref_order=" . join( ",", @pref_order ) );
    }

    # clean up
    close $fh
        or croak( __PACKAGE__ . "->parse(): couldn't close $filepath: $!" );
    ## critic (RequireBriefOpen)

    # 2nd pass: enumerate candidates and handle empty rankings
    $self->cef_second_pass( \%params );

    #
    # save CEF data to PrefVote vote definition & ballot docs
    #

    # save title
    $self->{vote_def}{params}{name} = $params{'title'} // $cef_default_title;

    # save number of seats
    if ( exists $params{'number of seats'} ) {
        $self->{vote_def}{params}{seats} = int( $params{'number of seats'} );
    }

    # save voting method, overwrite default value
    foreach my $vmethod_key ( 'Voting Methods', 'Voting Method' ) {
        if ( exists $params{$vmethod_key} ) {
            $self->{vote_def}{method} = $params{$vmethod_key};
            last;
        }
    }

    # save flags
    foreach my $cef_key ( keys %cef2flags ) {
        if ( exists $params{$cef_key} ) {
            $self->{vote_def}{params}{$cef_key} = $params{$cef_key};
        }
    }

    return;
}

# transfer data to another object
# instance method
sub xfer
{
    my ($self, $recipient) = @_;
    my @skipped;
    foreach my $key (keys %$self) {
        if (exists $recipient->{$key}) {
            # do not overwrite data in the recipient object - warn about it
            push @skipped, $key
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

