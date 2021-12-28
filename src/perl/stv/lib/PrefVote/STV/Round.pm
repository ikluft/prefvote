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
use Types::Standard qw(StrictNum ArrayRef HashRef InstanceOf Map);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroNum);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote';
use PrefVote::Core;
use PrefVote::STV::Tally;
use PrefVote::STV::Result;

# round number (1=1st, etc)
has number => (
    is => 'ro',
    isa => PositiveInt,
    required => 1,
);

# link to previous round - makes it available here without access to PrefVote::STV's data
# If not set, it indicates the object is for the first round and therefore there is no previous round.
has prev => (
    is => 'ro',
    isa => InstanceOf["PrefVote::STV::Round"],
);

# count of votes used/consumed in counting so far
has votes_used => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    default => 0,
);

# active candidates in the current round (which this object tracks)
has candidates => (
    is => 'rw',
    isa => ArrayRef[NonEmptySimpleStr],
    default => sub { return [] },
);

# STV quota is the threshold to win the round as a function of seats available and candidates running
has quota => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    default => 0,
);

# candidate vote counts in the current round
has tally => (
    is => 'rw',
    isa => Map[NonEmptySimpleStr, InstanceOf["PrefVote::STV::Tally"]],
    default => sub { return {} },
);

# result of the current round lists either winners or eliminated candidates
has result => (
    is => 'rw',
    isa => InstanceOf["PrefVote::STV::Result"],
    required => 0,
);

# set candidate tallies
# candidates must be provided by new() for first round, later rounds this populates it from previous round
sub init_candidate_tally
{
    my $self = shift;

    # throw exception if there is no candidate list and no previous round link
    if ((not scalar @{$self->{candidates}}) and (not exists $self->{prev})) {
        # the object wasn't provided with enough info to get started
        PrefVote::STV::Round::PrevMissingException->throw({classname => __PACKAGE__,
            description => "prev must be set if candidates list wasn't provided to new()",
        });
    }

    # collect candidates from previous round for this round
    # this occurs every round except the first, when the initial candidate list must be established by new()
    if (exists $self->{prev}) {
        my $prev = $self->{prev};
        foreach my $cand_key (keys %{$prev->{tally}}) {
            # candidate is not available for current list if they won or were eliminated
            if (not $prev->{tally}{$cand_key}->winner() and not $prev->{tally}{$cand_key}->eliminated()) {
                $self->debug_print("(round ".$self->{number}.") add $cand_key to candidate list\n");
                push @{$self->{candidates}}, $cand_key;
            }
        }
        $self->debug_print("init_candidate_tally: candidates ".join(" ", @{$self->{candidates}})."\n");
    }

    # initialize candidate tally structures
    foreach my $cand_name (@{$self->{candidates}}) {
        $self->{tally}{$cand_name} = PrefVote::STV::Tally->new(name => $cand_name);
    }
    $self->debug_print("init_candidate_tally: tally structs ".join(" ", keys %{$self->{tally}})."\n");
    return;
}

# add to total votes found/used in the round
# this counts fractional votes for transfers above a winning candidate's quota
sub add_votes_used
{
    my $self = shift;
    my $votes = shift;
    if ($votes < 0) {
        PrefVote::STV::Round::NegativeIncrementException->throw({classname => __PACKAGE__,
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
    my ($self, $sort_fn) = @_;
    my $round_candidates = $self->candidates(); # names of candidates
    if (ref $sort_fn ne "CODE") {
        PrefVote::STV::Round::BadSortingFnException->throw({classname => __PACKAGE__,
            attribute => 'sort_fn',
            description => "sorting function parameter is not a CODE reference: got ".(ref $sort_fn),
        });
    }
    @$round_candidates = sort $sort_fn (@$round_candidates);
    $self->debug_print("sorted round candidate list = ".join(" ", @$round_candidates)."\n");
    return @$round_candidates;
}

# instantiate a result for current round
sub set_result
{
    my ($self, %opts) = @_;

    # verify candidates in result are valid in this round
    if (not exists $opts{type}) {
        PrefVote::STV::Round::TypeMissingException->throw({classname => __PACKAGE__,
            attribute => 'type',
            description => "type parameter not provided",
        });
    }
    if (not exists $opts{name}) {
        PrefVote::STV::Round::NameMissingException->throw({classname => __PACKAGE__,
            attribute => 'name',
            description => "name parameter not provided",
        });
    }
    if (ref $opts{name} ne "ARRAY") {
        PrefVote::STV::Round::NameNotArrayException->throw({classname => __PACKAGE__,
            attribute => 'name',
            description => "name parameter is not an array: got ".(ref $opts{name} ? ref $opts{name} : "scalar"),
        });
    }
    my @invalid_candidates;
    foreach my $candidate_name (@{$opts{name}}) {
        my $found=0;
        foreach (my $i=0; $i<scalar @{$self->{candidates}}; $i++) {
            if ($self->{candidates}[$i] eq $candidate_name) {
                $found=1;
                last;
            }
        }
        if (not $found) {
            push @invalid_candidates, $candidate_name;
        }
    }
    if (@invalid_candidates) {
        PrefVote::STV::Round::InvalidCandidateException->throw({classname => __PACKAGE__,
            attribute => 'name',
            description => "invalid candidate name ($opts{type}):".join(" ", @invalid_candidates),
        });
    }

    # instantiate and save result object
    $self->result(PrefVote::STV::Result->new(%opts));
    return;
}

## no critic (Modules::ProhibitMultiplePackages)

#
# exception classes
#

package PrefVote::STV::Round::NegativeIncrementException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::BadSortingFnException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::TypeMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::PrevMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::NameMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::NameNotArrayException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::STV::Round::InvalidCandidateException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

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
