# PrefVote::Core::Round
# ABSTRACT: internal voting-round structure provided by PrefVote::Core for voting methods
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
# PrefVote::Core voting round class
#
package PrefVote::Core::Round;

use utf8;
use charnames qw(:loose);
use autodie;
use Readonly;
use Set::Tiny qw(set);
use PrefVote::Core::Result;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard        qw(ArrayRef HashRef InstanceOf Map);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String  qw(NonEmptySimpleStr);
extends 'PrefVote';

# constants
Readonly::Hash my %blackbox_spec => (
    number     => [qw(int)],
    candidates => [qw(list string)],
    result     => [qw(PrefVote::Core::Result)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__, spec => \%blackbox_spec );

# round number (1=1st, etc)
has number => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

# link to previous round - makes it available here without access to PrefVote::Core's data
# If not set, it indicates the object is for the first round and therefore there is no previous round.
has prev => (
    is  => 'ro',
    isa => InstanceOf ["PrefVote::Core::Round"],
);

# active candidates in the current round (which this object tracks)
has candidates => (
    is          => 'rw',
    isa         => ArrayRef [NonEmptySimpleStr],
    default     => sub { return [] },
    handles_via => 'Array',
    handles     => {
        candidates_all           => 'all',
        candidates_count         => 'count',
        candidates_empty         => 'is_empty',
        candidates_join          => 'join',
        candidates_push          => 'push',
        candidates_sort_in_place => 'sort_in_place',
    },
);

# result of the current round lists either winners or eliminated candidates
has result => (
    is       => 'rw',
    isa      => InstanceOf ["PrefVote::Core::Result"],
    required => 0,
);

# initialize candidate list for the round
sub init_round_candidates
{
    my $self = shift;

    # throw exception if there is no candidate list and no previous round link
    if ( $self->candidates_empty() and ( not exists $self->{prev} ) ) {

        # The object wasn't provided with enough info to get started.
        # This needs new() to get a candidate list on the first round and a link to previous rounds after that.
        PrefVote::Core::Round::PrevMissingException->throw(
            {
                classname   => __PACKAGE__,
                description => "prev must be set if candidates list wasn't provided to new()",
            }
        );
    }

    # collect candidates from previous round for this round
    # this occurs every round except the first, when the initial candidate list must be established by new()
    if ( exists $self->{prev} ) {
        my $prev = $self->{prev};
    CAND_LOOP: foreach my $cand_key ( $prev->candidates_all() ) {

            # candidate is available for current round's list if they didn't win or get eliminated in previous round
            if ( exists $prev->{result} ) {
                foreach my $result_cand ( $prev->{result}->name_all() ) {
                    if ( $result_cand eq $cand_key ) {
                        next CAND_LOOP;    # found in previous round's results - skip adding candidate to current round
                    }
                }
            }

            # add candidate to the current round
            $self->candidates_push($cand_key);
        }
        $self->debug_print( "init_round_candidates: candidates " . $self->candidates_join(" ") . "\n" );
    }

    return;
}

# instantiate a result for current round
sub set_result
{
    my ( $self, %opts ) = @_;

    # verify candidates in result are valid in this round
    if ( not exists $opts{type} ) {
        PrefVote::Core::Round::TypeMissingException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'type',
                description => "type parameter not provided",
            }
        );
    }
    if ( not exists $opts{name} ) {
        PrefVote::Core::Round::NameMissingException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'name',
                description => "name parameter not provided",
            }
        );
    }
    if ( ref $opts{name} ne "ARRAY" ) {
        PrefVote::Core::Round::NameNotArrayException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'name',
                description => "name parameter is not an array: got "
                    . ( ref $opts{name} ? ref $opts{name} : "scalar" ),
            }
        );
    }
    my @invalid_candidates;
    foreach my $candidate_name ( @{ $opts{name} } ) {
        my $found = 0;
        foreach ( my $i = 0 ; $i < $self->candidates_count() ; $i++ ) {
            if ( $self->{candidates}[$i] eq $candidate_name ) {
                $found = 1;
                last;
            }
        }
        if ( not $found ) {
            push @invalid_candidates, $candidate_name;
        }
    }
    if (@invalid_candidates) {
        PrefVote::Core::Round::InvalidCandidateException->throw(
            {
                classname   => __PACKAGE__,
                attribute   => 'name',
                description => "invalid candidate name ($opts{type}): " . join( " ", @invalid_candidates ),
            }
        );
    }

    # instantiate and save result object
    $self->result( PrefVote::Core::Result->new( type => $opts{type}, name => set( @{ $opts{name} } ) ) );
    return;
}

## no critic (Modules::ProhibitMultiplePackages)

#
# exception classes
#

package PrefVote::Core::Round::TypeMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::Core::Round::PrevMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::Core::Round::NameMissingException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::Core::Round::NameNotArrayException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

package PrefVote::Core::Round::InvalidCandidateException;

use Moo;
use Types::Standard qw(Str);
extends 'PrefVote::Core::InternalDataException';

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION

I<PrefVote::Core::Round> contains data in common among L<PrefVote> voting methods which use multiple rounds of
vote counting. It serves as a superclass providing data and methods used by L<PrefVote::STV::Round>
and L<PrefVote::Schulze::Round>.

=head1 ATTRIBUTES

=over 1

=item number

'Number' is the integer number of the current voting round, starting from 1 so it can be used in displaying results.

=item prev

'Prev' is a reference to the I<PrefVote::Core::Round> object for the previous voting round.

=item candidates

'Candidates' is an array reference containing the candidate ID strings of the candidates who are active in this round.
Candidates are considered active based on the specific voting method, which is defined by a subclass,
but always omits candidates which won previous rounds.
In voting methods which eliminate candidates from the bottom of the results,
those are also omitted from following rounds.

=item result

'Result' is an array of L<PrefVote::Core::Result> objects indicating the results of the round.
Resuls will list any candidates who won the round.
For voting methods which allow elimination of candidates, those would be indicated here too.

=back

=head1 METHODS

=over 1

=item init_round_candidates ()

This performs initialization of the round data. It must be called once before other processing of the round.

=item set_result (...result instatiation parameters...)

Set the results for the round. The parameters are passed directly to the new() method of L<PrefVote::Core::Result>.

=back

=head1 SEE ALSO

L<PrefVote:Core>

L<https://github.com/ikluft/prefvote>


=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
