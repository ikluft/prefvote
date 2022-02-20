# PrefVote::STV::Output
# ABSTRACT: Gbase class for output formatting in PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::STV::Output;

use autodie;
use base qw(PrefVote::Core::Output);
use Data::Dumper;
use PrefVote::Core::Float qw(float_external);

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
            $result->{display} .= " ".PrefVote::Core::Output::symbol($action);
            $result->{save} = $action;
        }
    }
    return $result;
}

# output formatting class method (called by PrefVote::Core::format_output())
# requires subclass (::Text, ::Markdown, ::HTML, etc) implement functions: do_header, do_toc, do_table, do_footer
sub output
{
    my $class= shift;
    my $result_data = shift;

    # set symbol aliases in PrefVote::Core::Output so it accepts STV's "winner" and "eliminated" names
    PrefVote::Core::Output::set_symbol_alias("winner" => "win");
    PrefVote::Core::Output::set_symbol_alias("eliminated" => "lose");

    # generate candidate names list
    my @candidates;
    foreach my $winner (@{$result_data->{winners}}) {
        push @candidates, sort @$winner;
    }
    if (exists $result_data->{eliminated}) {
        foreach my $elim (reverse @{$result_data->{eliminated}}) {
            push @candidates, sort @$elim;
        }
    }

    # set up for table generation
    binmode(STDOUT, ':encoding(UTF-8)');

    # print heading
    $class->do_header($result_data);

    # generate candidate table of contents
    my @toc_rows;
    my $c2r = $result_data->{choice_to_result};
    push @toc_rows, ["Abbreviation", "Name/description", "Result"];
    foreach my $name (@candidates) {
        push @toc_rows, [$name, $result_data->{choices}{$name}, join("/",@{$c2r->{$name}})];
    }
    $class->do_toc($result_data, \@toc_rows);

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
               push @result_row, PrefVote::Core::Output::symbol($col_status{$col_name});
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
    $class->do_toc($result_data, \@result_rows);

    # generate footer (if needed)
    $class->do_footer($result_data);

    return 1;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Output - base class for output formatting in PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

