# PrefVote::Core::Output::HTML
# ABSTRACT: result HTML output formatting for PrefVote
# derived from Vote::Core by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::HTML;

use utf8;
use charnames qw(:loose);
use feature   qw(say);
use autodie;
use HTML::Escape qw(escape_html);
use parent       qw(PrefVote);

# HTML filters (escape and whitespace)
sub htmlify
{
    my $str = escape_html(shift);
    return $str;
}

# generate HTML table from an array
sub generate_html_table
{
    my %opts = @_;
    my $rows = $opts{rows};

    # table heading
    say '<table border=1>';

    # generate header from first row
    if ( $opts{header_row} // 0 ) {
        my $header = shift @$rows;
        say "<thead>";
        say "<tr>";
        foreach my $col_item (@$header) {
            say "<th>" . htmlify($col_item) . "</th>";
        }
        say "</tr>";
        say "</thead>";
    }

    # generate table from remainder of rows
    say "<tbody>";
    foreach my $row (@$rows) {
        say "<tr>";
        foreach my $col_item (@$row) {
            say "<td>" . htmlify($col_item) . "</td>";
        }
        say "</tr>";
    }
    say "</tbody>";
    say "</table>";
    return;
}

# generate header
sub do_header
{
    my ( $class, $result_data ) = @_;

    # vote result heading
    # scope limited to h2 level heading - assumes this will be inserted in a larger document
    my $seats         = $result_data->{seats};
    my $total_ballots = $result_data->{total_ballots};
    my $title         = "Results: " . $result_data->{name};
    say "<div id=\"prefvote\">";
    say "<h2>" . htmlify($title) . "</h2>";
    if ( $seats == 0 ) {
        say "<p>" . "ranking order " . "\N{BLACK CIRCLE} " . htmlify($total_ballots) . " ballots processed</p>";
    } else {
        say "<p>"
            . htmlify($seats) . " seat"
            . ( $seats != 1 ? "s" : "" )
            . " available "
            . "\N{BLACK CIRCLE} "
            . htmlify($total_ballots)
            . " ballots processed</p>";
    }
    return;
}

# generate table of contents
sub do_toc
{
    my ( $class, $result_data, $toc_rows ) = @_;
    generate_html_table( rows => $toc_rows, header_row => 1 );
    return;
}

# generate table
sub do_table
{
    my ( $class, $result_data, $result_rows, $title, $subtitle ) = @_;
    if ( defined $title ) {
        say "<h3>" . $title . "</h3>";
    }
    if ( defined $subtitle ) {
        say "<p>" . $subtitle . "</p>";
    }
    generate_html_table( rows => $result_rows, header_row => 1 );
    return;
}

# generate footer
sub do_footer
{
    say "</div>";
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

PrefVote::Core::Output::Text is used by L<PrefVote::Core::Output> when HTML is selected as the output format.
It provides functions for formatting output including tables in HTML.

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

