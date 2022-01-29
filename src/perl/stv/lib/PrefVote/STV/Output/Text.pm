# PrefVote::STV::Output::Text
# ABSTRACT: text output formatting PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)


package PrefVote::STV::Output::Text;

use autodie;
use base qw(PrefVote::Core::Output);
use Carp qw(croak);
use Data::Dumper;
use Readonly;
use YAML::XS;
use Text::Table::Tiny 1.02 qw/ generate_table /;

# constants for output
Readonly::Hash my %symbols => {
    "winner" => "\N{CHECK MARK}",
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
    $result->{display} = $votes;
    foreach my $action (qw(eliminated winner)) {
        if ($round_data->{tally}{$cand}{$action}) {
            $result->{display} .= " ".$symbols{$action};
            $result->{save} = $action;
        }
    }
    return $result;
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

    # generate candidate table of contents
    my @toc_rows;
    push @toc_rows, ["Abbreviation", "Name/description"];
    foreach my $name (@candidates) {
        push @toc_rows, [$name, $result_data->{choices}{$name}];
    }
    say generate_table(rows => \@toc_rows, header_row => 1, style => 'boxrule');

    # generate output text table
    my @result_rows;
    my $seats = $result_data->{seats};
    my $rounds = $result_data->{rounds};
    my %col_status;
    push @result_rows, ['Round #', @candidates];
    for (my $round=0; $round < scalar @$rounds; $round++) {
        my @result_row = ($round);
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
    say generate_table(rows => \@result_rows, header_row => 1, style => 'boxrule');

    return 1;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Output::Text - text output formatting PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

