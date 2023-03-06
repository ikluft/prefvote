# PrefVote::STV::Tally
# ABSTRACT: internal per-round candidate tally structure used by PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

#
# STV candidate record within each round
#
package PrefVote::STV::Tally;

use utf8;
use autodie;
use Readonly;
use PrefVote::Core::TestSpec;

# class definitions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Bool Str ArrayRef);
use Types::Common::Numeric qw(PositiveInt);
extends 'PrefVote';
use PrefVote::Core::Float qw(float_internal PVPositiveOrZeroNum);

# constants
Readonly::Hash my %blackbox_spec => (
    name       => [qw(string)],
    votes      => [qw(fp)],
    winner     => [qw(bool)],
    eliminated => [qw(bool)],
    place      => [qw(int)],
    transfer   => [qw(fp)],
    surplus    => [qw(fp)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__, spec => \%blackbox_spec );

# candidate name (identifier string)
has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# candidate vote total
has votes => (
    is      => 'rw',
    isa     => PVPositiveOrZeroNum,
    default => 0,
);
around votes => sub {
    my ( $orig, $self, $param ) = @_;
    return $orig->( $self, ( defined $param ? ( float_internal($param) ) : () ) );
};

# flag: winner of current or previous round (exclude from later rounds)
has winner => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# flag: eliminated in current or previous round (exclude from later rounds)
has eliminated => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# result: finished in nth place
has place => (
    is  => 'rw',
    isa => PositiveInt,
);

# total votes available for transfer
has transfer => (
    is  => 'rw',
    isa => PVPositiveOrZeroNum,
);
around transfer => sub {
    my ( $orig, $self, $param ) = @_;
    return $orig->( $self, ( defined $param ? ( float_internal($param) ) : () ) );
};

# fraction of votes which exceed the quota needed to win, and are available for transfer
has surplus => (
    is  => 'rw',
    isa => PVPositiveOrZeroNum,
);
around surplus => sub {
    my ( $orig, $self, $param ) = @_;
    return $orig->( $self, ( defined $param ? ( float_internal($param) ) : () ) );
};

# add to total votes
# use this instead of direct accessor since we only add to vote totals
sub add_votes
{
    my $self  = shift;
    my $votes = shift;

    PVPositiveOrZeroNum->validate($votes);
    if ( $votes < 0 ) {
        PrefVote::STV::Tally::NegativeIncrementException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'votes',
                description => "negative incrememnt is invalid",
            }
        );
    }
    my $new_votes = $self->votes() + $votes;
    $self->votes( float_internal($new_votes) );
    return $votes;
}

# mark candidate as a winner
# if there is a tie, call this once per winning candidate
sub mark_as_winner
{
    my ( $self, %opts ) = @_;

    #$self->debug_print("mark_as_winner(".$self->{name}."): opts = ".join(" ", %opts));
    $self->winner(1);
    foreach my $key (qw(place votes surplus transfer)) {
        if ( exists $opts{$key} ) {
            $self->$key( $opts{$key} );
        }
    }
    return;
}

# mark candidate as eliminated
sub mark_as_eliminated
{
    my $self = shift;

    #$self->debug_print("mark_as_eliminated(".$self->{name}.")");
    $self->eliminated(1);
    return;
}

## no critic (Modules::ProhibitMultiplePackages)

#
# exception classes
#

package PrefVote::STV::Tally::NegativeIncrementException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

  my $stv_tally_ref = PrefVote::STV::Tally->new(name => 'test1');
  my $stv_tally_ref2 = PrefVote::STV::Tally->new(name => 'test2');
  $stv_tally_ref->mark_as_winner(place => 1, votes => 42, surplus => 12, transfer => 10);
  my $votes1 = $stv_tally_ref->votes(); # 42
  $stv_tally_ref2->mark_as_eliminated();
  my $votes2 = $stv_tally_ref2->votes(); # 0

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

I<PrefVote::STV::Tally> holds the per-round voting tally for a candidate.
Each of these objects is held in a hash called 'tally' in L<PrefVote::STV::Round>,
keyed on the candidate ID string, to store that vote-counting round's totals.

=head1 ATTRIBUTES

=over 1

=item name

'Name' is the candidate ID string. It should match the key used to store it in L<PrefVote::STV::Round>'s
tally hash attribute. It can also be used to look up data about the candidate from L<PrefVote::STV>
and its parent class <PrefVote::Core>.

=item votes

'Votes' is the total votes received in the current round by the candidate.
It may differ from totals for the same candididate in earlier or later rounds, depending on votes
that transfer to voters' next choices when candidates are eliminated in any round.

=item winner

Winner is a boolean flag indicating the candidate is a winner of the current round.
In case of ties, more than one candidate may have this flag set.

=item eliminated

'Eliminated' is a boolean flag indicating the candidate was eliminated in the current round.
This happens in Single Transferable Vote counting when there is no winner of the round,
meaning that no candidate(s) reached the necessary fraction (quota) of votes to win.
Therefore the last place candidate, or all candidates tied for last place, are eliminated.
Eliminated candidates have their votes redistributed to voters' next-place choices.

=item place

'Place' is an integer number indicating the nth place that a winning candidate of the round qualified for.
Note that winning a round does not necessarily indicate winning an available seat in an election.
If available seats were already awarded in earlier rounds, then this only indicates the placement in the results.

=item transfer

'Transfer' is the fraction of votes that a round's winning candidate is above the quota necessary to win.
This fraction of votes is available to be transferred to voters' next choices in the same amount as the
candidate is above the quota.
In following rounds, votes may transfer in much smaller quantities as multiple transfer fractions are applied.

=item surplus

'Surplus' is the total of votes that a round's winning candidate is above the quota necessary to win.
This number of votes is available to be transferred to voters' next choices in the same fraction as the
amount above the quota, and used to compute the transfer fraction.

=back

=head1 METHODS

=over 1

=item add_votes ( float )

This is used in vote-counting, after applying possibly multiple transfer fractions, to add a total to
a candidate's tally for a round.

=item mark_as_winner ( place => int, votes => float, surplus => float, transfer => float )

This marks a candidate as a winner by setting the winner attribute to true.
It can also apply a place, vote total and transfer/surplus fractions to the candidate.
Parameters are given as key/value pairs. They may be given in any order, and will be used
to assign the attributes of the object.

=item mark_as_eliminated

This marks a candidate as eliminated in the current round by setting the eliminated attribute to true.

=back

=head1 SEE ALSO

L<PrefVote:STV>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
