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
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Schulze::PairData;
use PrefVote::Schulze::Round;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(ArrayRef HashRef InstanceOf);
use PrefVote::Core::Set qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote::Core');

# return a ballot item as a list, whether it was a single scalar or a tie-group set 
sub item2list
{
    my $item = shift;
    if (ref $item eq 'Set::Tiny') {
        return ($item->elements());
    }
    return ($item);
}

# set up a new round
sub new_round
{
    my $self = shift;
    my $number = $self->rounds_count()+1;

    # pick arguments for first or later rounds
    my @args;
    if ($number == 1) {
        @args = (candidates => [$self->get_choices()]);
    } else {
        @args = (prev => $self->rounds_get(-1));
    }

    # instantiate and save new round
    my $round = PrefVote::Schulze::Round->new(number => $number, @args);
    $round->init_round_candidates(); # initialization for PrefVote::Core::Round
    $self->rounds_push($round);

    return $round;
}

# save per-candidate final results in PrefVote::Core's choice_to_result map
sub save_c2r
{
    # TODO

    return;
}

# count votes using Schulze method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # loop forever until a valid result is established
    for ( ;; ) {
        # start new round
        $self->debug_print("new round\n");
        my $round = $self->new_round();

        # perform computations for the round to find the nth-place ranked choice/candidate
        $round->do_computation($self);
    }    

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r();

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

Schulze Method on Wikipedia L<https://en.wikipedia.org/wiki/Schulze_method>

Schulze Method paper L<https://arxiv.org/abs/1804.02973>

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
