# PrefVote::Core::Output::Markdown
# ABSTRACT: result Markdown output formatting for PrefVote
# derived from Vote::Core by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::Markdown;

use autodie;
use base qw(PrefVote);

# generate Markdown table from an array
sub generate_md_table
{
    my %opts = @_;
    my $rows = $opts{rows};

    # generate header from first row
    if ( $opts{header_row} // 0 ) {
        my $header = shift @$rows;
        say "| " . join( " | ", @$header ) . " |";
        say "|" . ( "---|" x scalar @$header );
    }

    # generate table from remainder of rows
    foreach my $row (@$rows) {
        say "| " . join( " | ", @$row ) . " |";
    }
    say;
    return;
}

# generate header
sub do_header
{
    my ( $class, $result_data ) = @_;
    my $seats         = $result_data->{seats};
    my $total_ballots = $result_data->{total_ballots};
    my $title         = "Results: " . $result_data->{name};
    say $title;
    say "-" x length $title;
    say "$seats seat" . ( $seats > 1 ? "s" : "" ) . " available " . "\N{VERTICAL LINE} $total_ballots ballots";
    say;
    return;
}

# generate table of contents
sub do_toc
{
    my ( $class, $result_data, $toc_rows ) = @_;
    generate_md_table( rows => $toc_rows, header_row => 1 );
    return;
}

# generate table
sub do_table
{
    my ( $class, $result_data, $result_rows, $title, $subtitle ) = @_;
    if ( defined $title ) {
        say "## " . $title;
    }
    if ( defined $subtitle ) {
        say $subtitle;
    }
    generate_md_table( rows => $result_rows, header_row => 1 );
    return;
}

# generate footer
sub do_footer
{
    # nothing to do
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

PrefVote::Core::Output::Text is used by L<PrefVote::Core::Output> when Markdown is selected as the output format.
It provides functions for formatting output including tables in Markdown.

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

