# PrefVote::Core::PairMatrix
# ABSTRACT: candidate pair matrix class for Condorcet voting methods (all methods except STV)
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::PairMatrix;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;
use PrefVote::Core::PairData;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard        qw(Str HashRef InstanceOf);
use Types::Common::String  qw(NonEmptySimpleStr);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    pair     => [qw(hash hash PrefVote::RankedPairs::PairData)],
    pairclass => [qw(string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);

# 2-level hash matrix of choice/candidate-pair preference totals
# This shows total votes where a 1st index choice/candidate is preferred over a 2nd index choice/candidate.
# Totals are unidirectional and must be combined with their corresponding opposite pair to determine which
# choice/candidate is actually more favored.
has pair => (
    is      => 'rw',
    isa     => HashRef [ HashRef [ InstanceOf ['PrefVote::Core::PairData'] ] ],
    default => sub { return {} },
);

# name of class to use for each pair data node
has pairclass => (
    is      => "ro",
    isa     => NonEmptySimpleStr,
    default => "PrefVote::Core::PairData",
);

# create candidate pair node if it didn't exist
sub make_pair_node
{
    my ( $self, $cand_i, $cand_j ) = @_;
    if ( not exists $self->{pair}{$cand_i} ) {
        $self->{pair}{$cand_i} = {};
    }
    if ( not exists $self->{pair}{$cand_i}{$cand_j} ) {
        $self->{pair}{$cand_i}{$cand_j} = ($self->pairclass())->new();
    }
    return;
}

# record a candidate-pair preference
# This adds to a total of votes favoring candidate cand1 over cand2. Note: cand2 over cand1 is a separate table entry.
sub add_preference
{
    my ( $self, $cand_i, $cand_j, $quantity ) = @_;
    $self->make_pair_node( $cand_i, $cand_j );
    return $self->{pair}{$cand_i}{$cand_j}->add_preference($quantity);
}

# get preference in matrix entry
sub get_preference
{
    my ( $self, $cand_i, $cand_j ) = @_;
    return 0 if not exists $self->{pair}{$cand_i};               # use zero if the node doesn't exist
    return 0 if not exists $self->{pair}{$cand_i}{$cand_j};      # use zero if the node doesn't exist
    return $self->{pair}{$cand_i}{$cand_j}->preference() // 0;   # return preference, or zero if the node didn't have it
}

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    use PrefVote::Core::PairMatrix;
    my $pairmatrix = PrefVote::Core::PairMatrix->new( pairclass => "PrefVote::RankedPairs::PairData" );

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.


=head1 SEE ALSO

L<PrefVote::Core>, L{PrefVote::Core::PairData>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
