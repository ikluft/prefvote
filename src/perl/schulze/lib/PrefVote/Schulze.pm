# PrefVote::Schulze
# ABSTRACT: Schulze Method vote counting module for PrefVote
# Copyright (c) 2022-2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Schulze;

use utf8;
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
use Types::Common       qw(Str ArrayRef HashRef InstanceOf);
use PrefVote::Core::Set qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners => [qw(list set string)],
    rounds  => [qw(list PrefVote::Schulze::Round)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);
__PACKAGE__->ballot_input_ties_policy(1);    # set flag for Core: this class allows input ballots to set A/B ties

# list of names of winners in order by place, ties shown by a set of the tied candidates
has winners => (
    is          => 'rw',
    isa         => ArrayRef [ Set [Str] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        winners_all   => 'all',
        winners_count => 'count',
        winners_push  => 'push',
    },
);

# list of rounds of Schulze vote counting
has rounds => (
    is          => 'rw',
    isa         => ArrayRef [ InstanceOf ["PrefVote::Schulze::Round"] ],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        rounds_count => 'count',
        rounds_get   => 'get',
        rounds_push  => 'push',
    },
);

# set up a new round
sub new_round
{
    my $self   = shift;
    my $number = $self->rounds_count() + 1;

    # pick arguments for first or later rounds
    my @args;
    if ( $number == 1 ) {

        # sort the list so results will be consistent for testing
        @args = ( candidates => [ sort $self->get_choices() ] );
    } else {
        @args = ( prev => $self->rounds_get(-1) );
    }

    # instantiate and save new round
    my $round = PrefVote::Schulze::Round->new( number => $number, @args );
    $round->init_round_candidates();    # initialization for PrefVote::Core::Round
    $self->rounds_push($round);

    return $round;
}

# count votes using Schulze method
sub count
{
    my $self = shift;

    # stop now if there are no votes
    return if $self->total_ballots() == 0;

    # loop forever until: no candidates are left to compare or a round fails to reach a result
    for ( ; ; ) {

        # start new round
        $self->debug_print("count: new round\n");
        my $round = $self->new_round();

        # done if we've exhausted the candidates
        $self->debug_print( "count: round->candidates -> " . Dumper( $round->{candidates} ) );
        if ( $round->candidates_empty() ) {
            $self->debug_print("count: no candidates remaining in new round\n");
            last;
        }

        # perform computations for the round to find the nth-place ranked choice/candidate
        $self->debug_print("count: begin computations\n");
        $round->do_computation($self);
        $self->debug_print("count: end computations\n");

        # save result
        my $round_result = $round->result();
        if ( defined $round_result ) {
            if ( $round_result->type() eq "winner" ) {
                $self->winners_push( set( $round_result->name_all() ) );
            }
        } else {

            # no result in this round? A new round can't have a different result without changing choices. Bail out.
            $self->debug_print("no result this round - bail out\n");
            last;
        }
    }

    # save per-candidate final results in PrefVote::Core's choice_to_result map
    $self->save_c2r( winners => $self->winners() );

    return;
}

# return short result list
sub results
{
    my $self = shift;
    return { ranked => $self->{winners} };
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    use PrefVote::Schulze;

    # count votes from a properly-formatted YAML file
    my $vote_obj = PrefVote::Schulze::file2vote($progname);
    $vote_obj->count();

    # get results in YAML
    print YAML::XS::Dump($vote_obj->result_yaml());

    # get results for your own handling
    my $results = $vote_obj->results();
    ... process $results contents ...


=head1 DESCRIPTION

=head1 ATTRIBUTES

These attributes are in addition to L<those inherited from PrefVote::Core|PrefVote::Core/ATTRIBUTES>.

=over 1

=item winners

=item pair

=item majority

=item graph

=back 

=head1 METHODS

These methods are in addition to L<those inherited from PrefVote::Core|PrefVote::Core/METHODS>.

=over 1

=item make_pair_node()

=item add_preference()

=item get_preference()

=item set_mov()

=item get_mov()

=item set_lock()

=item get_lock()

=item graph_add_link()

=item cand_total_wins()

=item cand_total_mov()

=item tally_preferences()

=item sort_pairs()

=item depth_first_search()

=item is_conflict()

=item lock_pairs()

=item graph_to_order()

=item count()

=back 

=head1 FUNCTIONS

=over 1

=item cmp_choice

=back

=head1 SEE ALSO

L<PrefVote::Core>

Schulze Method on Wikipedia L<https://en.wikipedia.org/wiki/Schulze_method>

Schulze Method paper L<https://arxiv.org/abs/1804.02973>

PrefVote on GitHub L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
