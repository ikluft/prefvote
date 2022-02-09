# PrefVote::Schulze
# ABSTRACT: Schulze Method vote counting module for PrefVote
# Copyright (c) 2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Schulze;

use autodie;
use Carp qw(croak);
use Data::Dumper;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use PrefVote::Core::Set qw(Set);
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote::Core');

# 2-level hash of candidate-pair preference totals
# This shows total votes where 1st index candidate dominates (is favored over) 2nd index candidate.
# Totals are unidirectional and must be combined to determine which candidate has greater number either direction.
has dominates => (
    is => 'ro',
    isa => HashRef[HashRef[PositiveOrZeroInt]],
    default => sub { return {} },
);

# return a ballot item as a list, whether it was a single scalar or a tie-group set 
# internal-use only
sub item2list
{
    my $item = shift;
    if (ref $item eq 'Set::Tiny') {
        return ($item->elements());
    }
    return ($item);

}

# record a candidate-pair preference
# internal-use only
sub add_preference
{
    my ($self, $cand1, $cand2, $quantity) = @_;
    if (not exists $self->{dominates}{$cand1}) {
        $self->{dominates}{$cand1} = {};
    }
    if (not exists $self->{dominates}{$cand1}{$cand2}) {
        $self->{dominates}{$cand1}{$cand2} = 0;
    }
    $self->{dominates}{$cand1}{$cand2} += $quantity;
    return;
}

# compute candidate-pair preference totals
# each ballot ranks voter preferences in order - this totals preferences among each pair of candidates
# internal-use only
sub tally_preferences
{
    my $self = shift;

    # loop through votes tallying preferences
    foreach my $combo ($self->ballots_keys()) {
        # loop through choices
        my $ballot = $self->ballots_get($combo);
        my @ballot_items = $ballot->items_all();
        for (my $pos1=0; $pos1 < scalar @ballot_items - 1; $pos1++) {
            my @item1 = item2list($ballot_items[$pos1]);
            for (my $pos2=$pos1+1; $pos2 < scalar @ballot_items; $pos2++) {
                my @item2 = item2list($ballot_items[$pos2]);
                foreach my $cand1 (@item1) {
                    foreach my $cand2 (@item2) {
                        $self->add_preference($cand1, $cand2, $ballot->{quantity});
                    }
                }
            }
        }
    }
    return;
}

# compute the strongest paths
# internal-use only
sub compute_strongest_paths
{
    my $self = shift;

    # TODO
    return;
}


# count votes using Schulze method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # convert ballot preferences to candidate-pair preference totals
    $self->tally_preferences();

    # compute the strongest paths
    $self->compute_strongest_paths();

    # TODO
    # work in progress: dump object up to this point
    $self->debug_print("count: ".Dumper($self));

    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Schulze - Schulze Method vote counting module for PrefVote

=head1 SYNOPSIS

  use PrefVote::Schulze;
  %vote_params = ( "name" => "value", ... );
  $vote = new PrefVote::Schulze \%vote_params;

=head1 DESCRIPTION


=head1 SEE ALSO


=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
