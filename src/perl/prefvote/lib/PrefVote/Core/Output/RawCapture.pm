# PrefVote::Core::Output::RawCapture
# ABSTRACT: PrefVote result output capture, for testing purposes only
# derived from Vote::Core by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013); # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::Output::RawCapture;

use autodie;
use base qw(PrefVote);

# output capture and access for testing
my @output;

sub push_output
{
    my @args = @_;
    push @output, @args;
    return;
}

sub get_output
{
    return \@output;
}

sub clear_output
{
    @output = ();
    return;
}

# generate header
sub do_header
{
    my ($class, $result_data) = @_;

    # save title and other heading info as if printing it
    my %out_rec;
    foreach my $key (qw(seats name total_ballots)) {
        if (exists $result_data->{$key}) {
            $out_rec{$key} = $result_data->{$key};
        }
    }
    push_output(\%out_rec);
    return;
}

# generate table of contents
sub do_toc
{
    my ($class, $result_data, $toc_rows) = @_;

    # save table of contents data as if printing it
    my %out_rec;
    $out_rec{rows} = $toc_rows;
    push_output(\%out_rec);
    return;
}

# generate table
sub do_table
{
    my ($class, $result_data, $result_rows, $title, $subtitle) = @_;

    # save table data as if printing it
    my %out_rec;

    if (defined $title) {
        $out_rec{title} = $title;
    }
    if (defined $subtitle) {
        $out_rec{subtitle} = $subtitle;
    }
    $out_rec{rows} = $result_rows;
    push_output(\%out_rec);
    return;
}

# generate footer
sub do_footer
{
    # nothing to do
    return;
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

This should not be called externally - use L<PrefVote::Core::Output>

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Output::RawCapture is used by L<PrefVote::Core::Output> as an output format for testing purposes.
It provides functions as if it was formatting output but captures the data for test result inspection.
It is used for unit testing of L<PrefVote::Core::Output>, L<PrefVote::STV::Output>, L<PrefVote::Schulze::Output> and
L<PrefVote::RankedPairs::Output>.

=head1 SEE ALSO

L<PrefVote::Core::Output>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

