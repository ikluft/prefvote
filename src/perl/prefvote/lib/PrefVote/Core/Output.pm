# PrefVote::Core::Output
# ABSTRACT: output formatting base class for PrefVote
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)


package PrefVote::Core::Output;

use autodie;
use base qw(PrefVote);
use Carp qw(croak confess);
use Config;
use English;
use Getopt::Long;
use Data::Dumper;
use Readonly;
use YAML::XS;
use IPC::Run qw(run);
use PrefVote::Core;
use PrefVote::Core::Exception;

# constants for output
Readonly::Hash my %symbols => (
    "win" => "\N{WHITE HEAVY CHECK MARK}",
    "lose" => "\N{CROSS MARK}",
    "tie" => "\N{LARGE BLUE CIRCLE}",
    "n/a" => "\N{PROHIBITED SIGN}",
    "unknown" => "\N{WHITE QUESTION MARK ORNAMENT}",
);
my %symbol_alias;

# allow a string as mock stdin for testing
my $testing_mock_stdin;
sub set_mock_stdin
{
    $testing_mock_stdin = shift;
    return;
}

# launch external piped-input formatter script using this class as the mainline
sub do_output
{
    my ($format, $voting_method, $yaml_ref) = @_;
    $voting_method =~ s/^.*:://x; # voting method suffix only - this allows optionally providing whole class name
    
    # pipe the YAML to a subprocess running main() from this class
    my @output_cmd = ($Config{perlpath}, "-M".__PACKAGE__, "-e", __PACKAGE__."::main", "--", "--format=$format",
        "--method=$voting_method", (__PACKAGE__->debug()?"--debug":()));
    run \@output_cmd, sub {if(my $line = shift @$yaml_ref){return $line}}, \*STDOUT;
    return;
}

# access common Unicode symbols
sub symbol
{
    my $name = shift;
    return $symbols{$name} if (exists $symbols{$name});
    if (exists $symbol_alias{$name} and exists $symbols{$symbol_alias{$name}}) {
        return $symbols{$symbol_alias{$name}};
    }
    return $symbols{unknown};
}

# set aliases for use in symbol lookup
sub set_symbol_alias
{
    my ($alias, $name) = @_;
    $symbol_alias{$alias} = $name;
    return;
}

# slurp standard input to a scalar
# returns ref to scalar with file contents to avoid copying large memory block
sub stdinslurp
{
    my $str;
    if (defined $testing_mock_stdin) {
        $str = $testing_mock_stdin;
        undef $testing_mock_stdin;
    } else {
        local $/ = undef;
        ## no critic (InputOutput::ProhibitExplicitStdin)
        $str = <STDIN>;
    }
    return \$str;
}

# get list of candidates
sub candidates_list
{
    my ($class, $result_data) = @_;

    # get list of candidates ordered by choice_to_result list
    # list is sorted by 1: result place (ascending), 2: candidate key string (alphabetical)
    # the second sort factor keeps results in order for testing
    my $c2r = $result_data->{choice_to_result};
    my @candidates = sort {($c2r->{$a}[0]==$c2r->{$b}[0]) ? ($a cmp $b) : ($c2r->{$a}[0]<=>$c2r->{$b}[0])} keys %$c2r;
    return @candidates;
}

# output formatting class method (called by PrefVote::Core::format_output())
# requires $format_class (::Text, ::Markdown, ::HTML, etc) implement functions: do_header, do_toc, do_table, do_footer
sub output
{
    my ($class, $format_class, $method_class, $result_data) = @_;

    # generate candidate names list
    my @candidates = $class->candidates_list($result_data);

    # set up for table generation
    binmode(STDOUT, ':encoding(UTF-8)');

    # print heading
    $format_class->do_header($result_data);

    # generate candidate table of contents
    my @toc_rows;
    my $c2r = $result_data->{choice_to_result};
    push @toc_rows, ["Abbreviation", "Name/description", "Result"];
    foreach my $name (@candidates) {
        push @toc_rows, [$name, $result_data->{choices}{$name}, join("/",@{$c2r->{$name}})];
    }
    $format_class->do_toc($result_data, \@toc_rows);

    # generate output table
    $method_class->do_counting_table($format_class, $result_data);

    # generate footer (if needed)
    $format_class->do_footer($result_data);

    return 1;
}

# generate counting results table
# in PrefVote::Core::Output this is only for testing - voting methods must override it to process their result
sub do_counting_table
{
    my ($class, $format_class, $result_data) = @_;

    # do nothing - Core method has no results of its own
    return;
}

# find an available class for formatting or voting method
# this allows formatting or voting-method string parameters to be case-insensitive match to formatting class suffix
sub class_search
{
    my ($search, $type) = @_;

    # try the raw search string as a class first
    my $class_name = $search;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    if (eval "require $class_name") {
        __PACKAGE__->debug_print("class_search: $type = $class_name");
        return $search; # success
    }
    ## critic (BuiltinFunctions::ProhibitStringyEval)

    # search INC path for class if the string wasn't an exact match
    my @search_components = split('::', $search);
    my $search_filename = (pop @search_components).".pm";
    my $search_subpath = join('/', @search_components);
    __PACKAGE__->debug_print("search_filename=$search_filename search_subpath=$search_subpath");
    foreach my $inc_dir (@INC) {
        -d $inc_dir or next;
        my $inc_search_path = "$inc_dir/$search_subpath";
        -d $inc_search_path or next;
        opendir(my $dirhandle, $inc_search_path) or next;
        my @all_files = readdir($dirhandle);
        __PACKAGE__->debug_print("class_search: grepping files ".join(" ", @all_files));
        my @files = sort grep {(fc($_) eq fc($search_filename)) and -f "$inc_search_path/$_"}
            @all_files;
        foreach my $file (@files) {
            my $basename = (substr($file, -3) eq ".pm") ? substr($file, 0, -3) : $file;
            $class_name = join("::", @search_components, $basename);
            __PACKAGE__->debug_print("class_search: candidate $file -> $class_name");
            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            if (eval "require $class_name") {
                __PACKAGE__->debug_print("class_search: $type = $class_name");
                return $class_name; # success
            }
            ## critic (BuiltinFunctions::ProhibitStringyEval)
        }
    }

    # couldn't find it - throw exception
    PrefVote::Core::Exception->throw(description => "could not load $type class $search");
}

# mainline to launch appropriate formatter subclass and forward YAML data to it
sub main
{
    my ($debug, $format, $method);
    __PACKAGE__->debug_print("main()");

    # exception-catching wrapper
    my ($exitcode, $evalcode);
    $evalcode = eval {
        # process command line
        GetOptions ("debug" => \$debug, "format=s" => \$format, "method=s" => \$method);
        if (not defined $format or not defined $method) {
            croak "usage: $0 --format=output_format --method=voting_method";
        }
        if ($debug) {
            $Data::Dumper::Sortkeys = 1;
            $Data::Dumper::Indent = 1;
            PrefVote::Core::Output->debug(1);
        }

        # check if a class which can handle the requested format exists
        my $format_class = class_search("PrefVote::Core::Output::$format", "formatting");

        # check if a class which can handle the requested voting method exists
        my $voting_method = PrefVote::Core::supported_method($method);
        if (not defined $voting_method) {
            croak "$method is not a supported voting method";
        }
        my $method_class = class_search("PrefVote::".$voting_method."::Output", "voting method");

        # slurp standard input
        my $yaml_textref = stdinslurp();

        # decode results data from YAML
        #__PACKAGE__->debug_print("output() receieved YAML: ".Dumper($yaml_textref));
        my @yaml_docs = YAML::XS::Load($$yaml_textref);
        __PACKAGE__->debug_print("output() decoded YAML: ".Dumper(\@yaml_docs));
        my $result_data_root = $yaml_docs[0];

        # double check proper formatting and voting method from received data
        # top level hash should be named for votring method
        if (not exists $result_data_root->{$voting_method}) {
            croak "voting method $voting_method data not found in input";
        }
        if (ref $result_data_root->{$voting_method} ne "HASH") {
            croak "voting method $voting_method data not formatted correctly";
        }

        # format the output
        # invert boolean success code into program exit code
        $exitcode = __PACKAGE__->output($format_class, $method_class, $result_data_root->{$voting_method}) ? 0 : 1;
        return 1; # eval completed
    };

    # process exceptions
    if (not $evalcode) {
        my $e = $EVAL_ERROR;
        if (ref $e and $e->isa("PrefVote::Exception")) {
            say "exception: ".$e->{description};
            #say $e->stack_trace();
            say Dumper($e);
        } else {
            confess $e;
        }
        return 1;
    }
    return $exitcode;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Core::Output - output formatting base class for PrefVote

=head1 SYNOPSIS

As called from PrefVote::Core:

    require PrefVote::Core::Output;
    PrefVote::Core::Output::do_output($format, ref $self, [YAML::XS::Dump($self->result_yaml())]);

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Output is called by PrefVote::Core to format results from a vote after counting.
It should not be called directly from user code.

This is the place that calls the output() method of any voting method classes derived from PrefVote::Core.
PrefVote::Core::Output launches a subprocess with itself as the program mainline, receiving the YAML results
via its standard input pipe and calling the subclass' output() method to format it.

=head1 SEE ALSO

L<PrefVote::Core>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

