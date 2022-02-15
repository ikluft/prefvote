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
use YAML::XS;
use IPC::Run qw(run);
use PrefVote::Core::Exception;

# launch external piped-input formatter script using this class as the mainline
sub do_output
{
    my ($format, $voting_method, $yaml_ref) = @_;
    $voting_method =~ s/^.*:://x; # voting method suffix only - this allows optionally providing whole class name
    
    # pipe the YAML to a subprocess running main() from this class
    my @output_cmd = ($Config{perlpath}, "-M".__PACKAGE__, "-e", __PACKAGE__."::main", "--", "--format=$format", "--method=$voting_method");
    run \@output_cmd, sub {if(my $line = shift @$yaml_ref){return $line}}, \*STDOUT;
    return;
}

# slurp standard input to a scalar
# returns ref to scalar with file contents to avoid copying large memory block
sub stdinslurp
{
    my $str;
    local $/ = undef;
    ## no critic (InputOutput::ProhibitExplicitStdin)
    $str = <STDIN>;
    return \$str;
}

# mainline to launch appropriate formatter subclass and forward YAML data to it
sub main
{
    my ($debug, $format, $voting_method);
    __PACKAGE__->debug_print("main()");

    # exception-catching wrapper
    my ($exitcode, $evalcode);
    $evalcode = eval {
        # process command line
        GetOptions ("debug" => \$debug, "format=s" => \$format, "method=s" => \$voting_method)
            or croak "usage: $0 --format=output_format --method=voting_method";
        if ($debug) {
            $Data::Dumper::Sortkeys = 1;
            $Data::Dumper::Indent = 1;
            PrefVote::Core::Output->debug(1);
        }

        # check if a class which can handle the requested format exists
        my $output_class = "PrefVote::".$voting_method."::Output::".ucfirst($format);
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        if (not eval "require $output_class") {
            PrefVote::Core::Exception->throw(description => "could not load $output_class");
        }
        ## critic (BuiltinFunctions::ProhibitStringyEval)

        # slurp standard input
        my $yaml_textref = stdinslurp();

        # format the output
        $exitcode = $output_class->output($yaml_textref) ? 0 : 1; # invert boolean success code into program exit code
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

