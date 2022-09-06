# PrefVote::STV::Round
# ABSTRACT: internal voting-round structure used by PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# STV voting round class
#
package PrefVote::STV::Round;

use autodie;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core;
use PrefVote::STV::Tally;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(ArrayRef HashRef InstanceOf Map);
use Types::Common::String qw(NonEmptySimpleStr);
extends 'PrefVote::Core::Round';
use PrefVote::Core::Float qw(float_internal PVPositiveOrZeroNum);

# constants
Readonly::Hash my %blackbox_spec => (
    votes_used => [qw(fp)],
    quota      => [qw(fp)],
    tally      => [qw(hash PrefVote::STV::Tally)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core::Round'
);

# count of votes used/consumed in counting so far
has votes_used => (
    is      => 'rw',
    isa     => PVPositiveOrZeroNum,
    default => 0,
);
around votes_used => sub {
    my ( $orig, $self, $param ) = @_;
    return $orig->( $self, ( defined $param ? ( float_internal($param) ) : () ) );
};

# STV quota is the threshold to win the round as a function of seats available and candidates running
has quota => (
    is      => 'rw',
    isa     => PVPositiveOrZeroNum,
    default => 0,
);
around quota => sub {
    my ( $orig, $self, $param ) = @_;
    return $orig->( $self, ( defined $param ? ( float_internal($param) ) : () ) );
};

# candidate vote counts in the current round
has tally => (
    is          => 'rw',
    isa         => Map [ NonEmptySimpleStr, InstanceOf ["PrefVote::STV::Tally"] ],
    default     => sub { return {} },
    handles_via => 'Hash',
    handles     => {
        tally_exists => 'exists',
        tally_get    => 'get',
        tally_keys   => 'keys',
        tally_set    => 'set',
    },
);

# set candidate tallies
# candidates must be provided by new() for first round, later rounds this populates it from previous round
sub init_candidate_tally
{
    my $self = shift;

    # initialization for parent class PrefVote::Core::Round
    $self->init_round_candidates();

    # initialize candidate tally structures
    foreach my $cand_name ( @{ $self->{candidates} } ) {
        $self->tally_set( $cand_name, PrefVote::STV::Tally->new( name => $cand_name ) );
    }
    $self->debug_print( "init_candidate_tally: tally structs " . join( " ", $self->tally_keys() ) . "\n" );
    return;
}

# add to total votes found/used in the round
# this counts fractional votes for transfers above a winning candidate's quota
sub add_votes_used
{
    my $self  = shift;
    my $votes = shift;

    PVPositiveOrZeroNum->validate($votes);
    if ( $votes < 0 ) {
        PrefVote::STV::Round::NegativeIncrementException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'votes_used',
                description => "negative incrememnt is invalid",
            }
        );
    }
    my $votes_used = $self->votes_used() + $votes;
    $self->votes_used( float_internal($votes_used) );
    return $votes_used;
}

# sort the round's candidates list
# this is called after adding last item so we don't waste time sorting it more than once
sub sort_candidates
{
    my ( $self, $sort_fn ) = @_;
    if ( not defined $sort_fn ) {

        # default sorting function is descending order by vote tally
        # alternative sort functions are for testing (i.e. alphabetical sort allows testing without using votes)
        my $tally_ref = $self->tally();
        $sort_fn = sub {

            # 1st/primary comparison: votes for candidate in descending order
            my $votes0 = $tally_ref->{ $_[0] }->votes();
            my $votes1 = $tally_ref->{ $_[1] }->votes();
            if ( $votes0 != $votes1 ) {
                return $votes1 <=> $votes0;
            }

            # 2nd comparison: alphabetical (so ties in testing comparisons are consistent)
            return $_[0] cmp $_[1];
        };
    } elsif ( ref $sort_fn ne "CODE" ) {
        PrefVote::STV::Round::BadSortingFnException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'sort_fn',
                description => "sorting function parameter is not a CODE reference: got " . ( ref $sort_fn ),
            }
        );
    }
    $self->candidates_sort_in_place($sort_fn);
    $self->debug_print( "sorted round candidate list = " . $self->candidates_join(" ") . "\n" );
    return $self->candidates_all();
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

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

  # from unit test code - not a full example
  my @candidate_names = qw(ABNORMAL BORING CHAOTIC DYSFUNCTIONAL EVIL FACTIOUS);
  my $stv_round_ref = PrefVote::STV::Round->new(number => 1, candidates => @candidate_names);
  $stv_round_ref->init_candidate_tally();
  $stv_round_ref->add_votes_used(10);
  $stv_round_ref->sort_candidates(sub{ return $_[1] cmp $_[0] });

=head1 DESCRIPTION

I<PrefVote::STV::Round> keeps the data for a voting round in L<PrefVote::STV>.

It is a subclass of L<PrefVote::Core::Round>, and therefore contains the data and methods of that class as well.

=head1 ATTRIBUTES

=over 1

=item votes_used

'votes_used' is a floating point number of the total votes consumed by counting.
During the count it's a running total. Afterward, it's the final total.

=item quota

'Quota' is a floating point number with the threshold of votes required to win the round, expressed as a fraction.
It is a function of seats available and candidates running.

=item tally

'Tally' is a hash keyed by candidate names which each contain that candidate's tally in the round's count,
as a L<PrefVote::STV::Tally> object.

=back

=head1 METHODS

=over 1

=item init_candidate_tally ()

This must be called once for each I<PrefVote::STV::Round> object to initialize the candidates and set votes to zero.
It calls init_round_candidates() in L<PrefVote::Core::Round> to initialize the superclass' data.

=item add_votes_used ( int votes )

This adds to the total votes used, or consumed, in the current round's vote-counting.

=item sort_candidates ( [coderef sort_fn] )

This should be called once after votes have been counted, to sort the candidates in result order.
It takes an optional code reference parameter as a sorting function, which can be used for testing purposes
if full vote totals have not been added to the object.
By default the sort order is descending by vote totals in the current round.

=back

=head1 SEE ALSO

L<PrefVote:STV>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
