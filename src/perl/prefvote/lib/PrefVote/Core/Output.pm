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
use Carp qw(croak);
use Config;
use Getopt::Long;
use YAML::XS;
use IPC::Run qw(run);

# launch external piped-input formatter script using this class as the mainline
sub do_output
{
    my ($format, $voting_method, $yaml_ref) = @_;
    $voting_method =~ s/^.*:://x; # voting method suffix only - this allows optionally providing whole class name
    
    # pipe the YAML to a subprocess running main() from this class
    my @output_cmd = ($Config{perlpath}, '-M'.__PACKAGE__, '-e main', "--", "--format=$format", "--method=$voting_method");
    run \@output_cmd, sub {if(my $line = shift @$yaml_ref){return $line}}, \*STDOUT;
    return;
}

# slurp input from pipe
# returns ref to scalar with file contents to avoid copying large memory block
sub pipeslurp
{
    my $pipefh = shift;
    my $str;
    local $/ = undef;
    $str = <$pipefh>;
    return \$str;
}

# mainline to launch appropriate formatter subclass and forward YAML data to it
sub main
{
    my ($debug, $format, $voting_method);
    GetOptions ("debug" => \$debug, "format=s" => \$format, "method=s" => \$voting_method)
        or croak "usage: $0 --format=output_format --method=voting_method";
    if ($debug) {
        __PACKAGE->debug(1);
    }

    # check if a class which can handle the requested format exists
    my $output_class = "PrefVote::".$voting_method."::Output::".ucfirst($format);
    eval {require $output_class}
        or PrefVote::Core::Exception->throw(description => "could not load $output_class");

    # slurp standard input
    my $yaml_textref = pipeslurp(\*STDIN);

    # format the output
    return $output_class->output($yaml_textref) ? 0 : 1; # invert boolean success code into program exit code
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::Output - output formatting base class for PrefVote

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

