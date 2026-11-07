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
use autodie;
use charnames qw(:loose);
use feature   qw(say);
use parent    qw(PrefVote);
use Carp      qw(croak);
use HTML::Escape qw(escape_html);
use Template;
use Readonly;
use Data::Dumper;

# constants
Readonly::Hash my %rating_bound_desc => (
    "_support2" => "strong support (above)",
    "_support1" => "support (above)",
    "_support" => "support (above)",
    "_neutral" => "neutral",
    "_oppose" => "oppose (below)",
    "_oppose1" => "oppose (below)",
    "_oppose2" => "strong oppose (below)",
);

# parameters are accumulated here to be handed to the template
if ( not __PACKAGE__->config_exists("output-template")) {
    __PACKAGE__->config("output-template", {});
}
my $param = __PACKAGE__->config("output-template");

# HTML filters (escape and whitespace)
sub htmlify
{
    my $str = escape_html(shift);
    return $str;
}

# generate HTML table from an array
sub html_table
{
    my %opts = @_;
    my $rows = $opts{rows};
    my $header_row = $opts{header_row} // 0;
    my $rating_bounds = $opts{rating_bounds} // 0;

    # result list
    my @out;

    # table heading
    push @out, '<table>';

    # generate header from first row
    if ( $header_row ) {
        my $header = shift @$rows;
        push @out, "<thead>";
        push @out, "<tr>";
        foreach my $col_item (@$header) {
            push @out, "<th>" . htmlify($col_item) . "</th>";
        }
        push @out, "</tr>";
        push @out, "</thead>";
    }

    # generate table from remainder of rows
    push @out, "<tbody>";
    foreach my $row (@$rows) {
        push @out, "<tr>";
        if ( $rating_bounds and substr($row->[0], 0, 1) eq "_" ) {
            my $bound_desc = $rating_bound_desc{$row->[0]};
            push @out, "<td colspan=\"" . ( scalar @$row ) . "\"><i>rating boundary: $bound_desc</i></td>";
        } else {
            foreach my $col_item (@$row) {
                push @out, "<td>" . htmlify($col_item) . "</td>";
            }
        }
        push @out, "</tr>";
    }
    push @out, "</tbody>";
    push @out, "</table>";
    return join( "\n", @out );
}

# method to generate header is skipped
sub do_header
{
    return;
}

# method to generate table of contents saves data for template
sub do_toc
{
    my ( $class, $result_data, $toc_rows ) = @_;
    if ( __PACKAGE__->debug()) {
        my @keys = __PACKAGE__->config_keys();
        say STDERR "$class config keys -> ".join(" ", @keys);
        foreach my $key ( sort @keys ) {
            say STDERR "$class config[$key] -> ".((not ref $key) ? $key : Dumper(__PACKAGE__->config($key)));
        }
    }
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
    my $config_args = $class->config("config");
    if ( not exists $config_args->{template} ) {
        croak( "template setting not found in configuration" );
    }
    my $template_path = $config_args->{template};
    my %template_vars = (
        html_table => \&html_table,
        results => $result_data,
        param => $param,
        config => $config_args,
    );
    $template_obj->process( $template_path, \%template_vars )
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

