# PrefVote::STV::Tally
# ABSTRACT: internal per-round candidate tally structure used by PrefVote::STV
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

#
# STV candidate record within each round
#
package PrefVote::STV::Tally;

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
    name => [qw(string)],
    votes => [qw(fp)],
    winner => [qw(bool)],
    eliminated => [qw(bool)],
    place => [qw(int)],
    transfer => [qw(fp)],
    surplus => [qw(fp)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec);

# candidate name (identifier string)
has 'name' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# candidate vote total
has votes => (
    is => 'rw',
    isa => PVPositiveOrZeroNum,
    default => 0,
);
around votes => sub {
    my ($orig, $self, $param) = @_;
    return $orig->($self, (defined $param ? (float_internal($param)) : ()));
};

# flag: winner of current or previous round (exclude from later rounds)
has winner => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

# flag: eliminated in current or previous round (exclude from later rounds)
has eliminated => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

# result: finished in nth place
has place => (
    is => 'rw',
    isa => PositiveInt,
);

# total votes available for transfer
has transfer => (
    is => 'rw',
    isa => PVPositiveOrZeroNum,
);
around transfer => sub {
    my ($orig, $self, $param) = @_;
    return $orig->($self, (defined $param ? (float_internal($param)) : ()));
};

# fraction of votes which exceed the quota needed to win, and are available for transfer
has surplus => (
    is => 'rw',
    isa => PVPositiveOrZeroNum,
);
around surplus => sub {
    my ($orig, $self, $param) = @_;
    return $orig->($self, (defined $param ? (float_internal($param)) : ()));
};

# add to total votes
# use this instead of direct accessor since we only add to vote totals
sub add_votes
{
    my $self = shift;
    my $votes = shift;

    PVPositiveOrZeroNum->validate($votes);
    if ($votes < 0) {
        PrefVote::STV::Tally::NegativeIncrementException->throw({classname => __PACKAGE__,
            attribute => 'votes',
            description => "negative incrememnt is invalid",
        });
    }
    my $new_votes = $self->votes() + $votes;
    $self->votes(float_internal($new_votes));
    return $votes;
}

# mark candidate as a winner
# if there is a tie, call this once per winning candidate
sub mark_as_winner
{
    my ($self, %opts) = @_;
    #$self->debug_print("mark_as_winner(".$self->{name}."): opts = ".join(" ", %opts));
    $self->winner(1);
    my @keys_set;
    foreach my $key (qw(place votes surplus transfer)) {
        if (exists $opts{$key}) {
            $self->$key($opts{$key});
            push @keys_set, $key;
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

=head1 NAME

PrefVote::STV::Tally - internal per-round candidate tally structure used by PrefVote::STV

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
