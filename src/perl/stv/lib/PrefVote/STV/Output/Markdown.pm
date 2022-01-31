# PrefVote::STV::Output::Markdown
# ABSTRACT: Markdown output formatting PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::STV::Output::Markdown;

use autodie;
use base qw(PrefVote::Core::Output);
use Carp qw(croak);
use Data::Dumper;
use Readonly;
use YAML::XS;
use PrefVote::Core::Float qw(float_external);

# constants for output
Readonly::Hash my %symbols => {
    "winner" => "\N{WHITE HEAVY CHECK MARK}",
    "eliminated" => "\N{CROSS MARK}",
};

# look up column/candidate result
sub get_col_result
{
    my ($result_data, $round, $cand) = @_;
    if (ref $result_data ne "HASH") {
        say STDERR "expected HASH ref, got ".Dumper($result_data);
        exit 1;
    }
    my $round_data = $result_data->{rounds}[$round];
    my $votes = $round_data->{tally}{$cand}{votes};
    my $result = {};
        $result->{display} = float_external($votes);
    foreach my $action (qw(eliminated winner)) {
        if ($round_data->{tally}{$cand}{$action}) {
            $result->{display} .= " ".$symbols{$action};
            $result->{save} = $action;
        }
    }
    return $result;
}

# generate Markdown table from an array
sub generate_md_table
{
    my %opts = @_;
    my $rows = $opts{rows};

    # generate header from first row
    if ($opts{header_row} // 0) {
        my $header = shift @$rows;
        say "| ".join(" | ", @$header)." |";
        say "|".("---|" x scalar @$header);
    }

    # generate table from remainder of rows
    foreach my $row (@$rows) {
        say "| ".join(" | ", @$row)." |";
    }
    return;
}

# output formatting class method (called by PrefVote::Core::format_output())
sub output
{
    my $class= shift;
    my $yamlref = shift;

    # decode results data from YAML
    #__PACKAGE__->debug_print("output() receieved YAML: ".Dumper($yamlref));
    my @yaml_docs = YAML::XS::Load($$yamlref);
    __PACKAGE__->debug_print("output() decoded YAML: ".Dumper(\@yaml_docs));
    my $result_data = $yaml_docs[0];

    # generate candidate names list
    my @candidates;
    foreach my $winner (@{$result_data->{winners}}) {
        push @candidates, sort @$winner;
    }
    foreach my $elim (reverse @{$result_data->{eliminated}}) {
        push @candidates, sort @$elim;
    }

    # set up for table generation
    binmode(STDOUT, ':encoding(UTF-8)');

    # print title
    my $seats = $result_data->{seats};
    my $title = "Results: ".$result_data->{name};
    say $title;
    say "-" x length $title;
    say "$seats seat".($seats>1 ? "s" : "")." available";
    say "";

    # generate candidate table of contents
    my @toc_rows;
    my $c2r = $result_data->{choice_to_result};
    push @toc_rows, ["Abbreviation", "Name/description", "Result"];
    foreach my $name (@candidates) {
        push @toc_rows, [$name, $result_data->{choices}{$name}, join("/",@{$c2r->{$name}})];
    }
    say generate_md_table(rows => \@toc_rows, header_row => 1);

    # generate output table
    my @result_rows;
    my $rounds = $result_data->{rounds};
    my %col_status;
    push @result_rows, ['Round #', 'Quota', @candidates];
    for (my $round=0; $round < scalar @$rounds; $round++) {
        my $quota = $result_data->{rounds}[$round]{quota};
        last if $quota <= 0;
        my @result_row = ($round+1, float_external($quota));
        foreach my $col_name (@candidates) {
            if (exists $col_status{$col_name}) {
               push @result_row, $symbols{$col_status{$col_name}};
               next;
            }
            my $status = get_col_result($result_data, $round, $col_name);
            push @result_row, $status->{display};
            if (exists $status->{save}) {
                $col_status{$col_name} = $status->{save};
            }
        }
        push @result_rows, \@result_row;
    }
    say generate_md_table(rows => \@result_rows, header_row => 1);

    return 1;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Output::Markdown - Markdown output formatting PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

