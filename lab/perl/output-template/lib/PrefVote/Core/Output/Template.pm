# PrefVote::Core::Output::Template
# ABSTRACT: result output formatting via Template Toolkit for PrefVote
# derived from PrefVote::Core::Output::HTML
# Copyright (c) 2022-2026 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::Template;

use utf8;
use charnames qw(:loose);
use feature   qw(say);
use Carp      qw(croak);
use autodie;
use Template;
use parent       qw(PrefVote);

# parameters are accumulated here to be handed to the template
if ( not __PACKAGE__->config_exists("output-template")) {
    __PACKAGE__->config("output-template", {});
}
my $param = __PACKAGE__->config("output-template", {});

# method to generate header is skipped
sub do_header
{
    return;
}

# method to generate table of contents saves data for template
sub do_toc
{
    my ( $class, $result_data, $toc_rows ) = @_;
    $param->{class} = $class;
    $param->{result_data} = $result_data;
    $param->{toc_rows} = $toc_rows;
    return;
}

# method to generate table saves data for template
sub do_table
{
    my ( $class, $result_data, $result_rows, $title, $subtitle ) = @_;
    if ( not exists $param->{tables}) {
        $param->{tables} = [];
    }
    my %table_entry;
    $table_entry{result_rows} = $result_rows;
    $table_entry{title} = $title;
    $table_entry{subtitle} = $subtitle;
    push @{$param->{tables}}, \%table_entry;
    return;
}

# method to generate the footer is called last, used to process the template
sub do_footer
{
    my ( $class, $result_data ) = @_;

    # feed the accumulated data to the template
    my $template_obj = Template->new(
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 1,               # cleanup whitespace
        EVAL_PERL    => 0,               # for security best practices, do not evaluate Perl code blocks
    );
    my $template_path = $class->config("template");
    if ( not defined $template_path ) {
        croak( "template setting not found in configuration" );
    }
    $template_obj->process( $template_path, $param )
        or croak( $template_obj->error());

    return;
}

# output() class method provided by parent class PrefVote::Core::Output

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

This should not be called externally - use L<PrefVote::Core::Output>

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Output::Template is used by L<PrefVote::Core::Output> when Template is selected as the output format.
It provides functions for formatting output via Perl's Template Toolkit.

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

L<Template> - Perl Template Toolkit L<https://template-toolkit.org/>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

