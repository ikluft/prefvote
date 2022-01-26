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
use base 'PrefVote';
use Carp qw(croak);
use Config;
use Getopt::Long;
use YAML::XS;
use IPC::Run qw(run);

# launch external piped-input formatter script using this class as the mainline
sub do_output
{
    my ($format, $voting_method, $yaml_text) = @_;
    $voting_method =~ s/^.*:://x; # voting method suffix only - this allows providing whole class name
    
    # pipe the YAML to a subprocess running main() from this class
    my @output_cmd = ($Config{perl5}, -M.__PACKAGE__, -e 'main', "--format=$format", "--method=$method");
    run \@output_cmd, \$yaml_text, \*STDOUT; #TODO not done
}

# mainline to launch appropriate formatter subclass and forward YAML data to it
sub main
{
    my ($format, $voting_method);
    GetOptions ("format=s" => \$format, "method=s" => \$voting_methodl)
        or croak "usage: $0 --format=output_format --method=voting_method";

    # check if a class which can handle the requested format exists
    my $output_class = "PrefVote::".$voting_method."::Output::".ucfirst($format);
    eval {require $output_class}; # throws exception if class doesn't exist

    # slurp standard input
    my $yaml_text = 

    # format the output
    $output_class->format();
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

