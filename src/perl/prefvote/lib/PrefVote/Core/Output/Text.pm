# PrefVote::Core::Output::Text
# ABSTRACT: result text output formatting for PrefVote
# derived from Vote::Core by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::Text;

use autodie;
use base qw(PrefVote);
use Term::ANSIColor;
use IO::Interactive qw(is_interactive);
use Text::Table::Tiny 1.02 qw/ generate_table /;

# generate header
sub do_header
{
    my ($class, $result_data) = @_;

    # print title
    my $seats = $result_data->{seats};
    say "Results: ".$result_data->{name};
    say "$seats seat".($seats>1 ? "s" : "")." available";
    say "";
    return;
}

# generate table of contents
sub do_toc
{
    my ($class, $result_data, $toc_rows) = @_;
    say generate_table(rows => $toc_rows, header_row => 1, style => 'boxrule');
    return;
}

# generate table
sub do_table
{
    my ($class, $result_data, $result_rows, $title, $subtitle) = @_;
    if (defined $title) {
        say $title;
    }
    if (defined $subtitle) {
        say $subtitle;
    }
    say generate_table(rows => $result_rows, header_row => 1, style => 'boxrule');
    return;
}

# generate footer
sub do_footer
{
    my ($class, $result_data) = @_;
    # nothing to do
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Core::Output::Text - result text output formatting for PrefVote

=head1 SYNOPSIS

This should not be called externally - use L<PrefVote::Core::Output>

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Output::Text is used by L<PrefVote::Core::Output> when text is selected as the output format.
It provides functions for formatting output including tables in plain text.

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

