# PrefVote::Core::Output::HTML
# ABSTRACT: result HTML output formatting for PrefVote
# derived from Vote::Core by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::HTML;

use autodie;
use HTML::Escape qw(escape_html);
use base qw(PrefVote);

# generate HTML table from an array
sub generate_html_table
{
    my %opts = @_;
    my $rows = $opts{rows};

    # table heading
    say "<table>";

    # generate header from first row
    if ($opts{header_row} // 0) {
        my $header = shift @$rows;
        say "<thead>";
        say "<tr>";
        foreach my $col_item (@$header) {
            say "<th>".escape_html($col_item)."</th>";
        }
        say "</tr>";
        say "</thead>";
    }

    # generate table from remainder of rows
    say "<tbody>";
    foreach my $row (@$rows) {
        say "<tr>";
        foreach my $col_item (@$row) {
            say "<td>".escape_html($col_item)."</td>";
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
    my ($class, $result_data) = @_;

    # vote result heading
    # scope limited to h2 level heading - assumes this will be inserted in a larger document
    my $seats = $result_data->{seats};
    my $title = "Results: ".$result_data->{name};
    say "<div id=\"prefvote\">";
    say "<h2>".escape_html($title)."</h2>";
    say "<p>".escape_html($seats)." seat".($seats>1 ? "s" : "")." available</p>";
    return;
}

# generate table of contents
sub do_toc
{
    my ($class, $result_data, $toc_rows) = @_;
    generate_html_table(rows => $toc_rows, header_row => 1);
    return;
}

# generate table
sub do_table
{
    my ($class, $result_data, $result_rows, $title, $subtitle) = @_;
    if (defined $title) {
        say "<h3>".$title."</h3>";
    }
    if (defined $subtitle) {
        say "<p>".$subtitle."</p>";
    }
    generate_html_table(rows => $result_rows, header_row => 1);
    return;
}

# generate footer
sub do_footer
{
    my ($class, $result_data) = @_;
    say "</div>";
    return;
}

# output() class method provided by parent class PrefVote::Core::Output

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::Output::HTML - result HTML output formatting for PrefVote

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

