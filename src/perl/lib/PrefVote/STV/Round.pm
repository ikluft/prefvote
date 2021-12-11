# PrefVote::STV::Round
# ABSTRACT: internal voting-round structure used by PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# STV voting round class
#
package PrefVote::STV::Round;

use autodie;

# class definitions
use Moo;
use Type::Tiny;
use Types::Standard qw(StrictNum ArrayRef);
use Types::Common::Numeric qw(PositiveOrZeroNum);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote';

has votes_used => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    default => 0,
);

has candidates => (
    is => 'rw',
    isa => ArrayRef[NonEmptySimpleStr],
);

has quota => (
    is => 'rw',
    isa => StrictNum,
    default => 0,
);

# add a candidate to a round
sub add_candidate
{
    my $self = shift;
    my $candidate = shift;
    my $candidates_ref = $self->candidates();
    push @$candidates_ref, $candidate;
    return;
}

# add to total votes found/used in the round
# this counts fractional votes for transfers above a winning candidate's quota
sub add_votes_used
{
    my $self = shift;
    my $votes = shift;
    if ($votes < 0) {
        PrefVote::STV::InvalidInternalData->throw({classname => __PACKAGE__,
            attribute => 'votes_used',
            description => "negative incrememnt is invalid",
        });
    }
    my $votes_used = $self->votes_used() + $votes;
    $self->votes_used($votes_used);
    return $votes_used;
}

# sort the round's candidates list
# this is done manually after adding last item so we don't waste time doing it more than once
sub sort_candidates
{
    my $self = shift;
    my $round_candidates = $self->candidates();
    @$round_candidates = sort {$round_candidates->{$b}->tally() <=> $round_candidates->{$a}->tally()}
        @$round_candidates;
    $self->debug_print("sorted round candidate list = ".join(" ", @$round_candidates)."\n");
    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::STV::Round - internal voting-round structure used by PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
