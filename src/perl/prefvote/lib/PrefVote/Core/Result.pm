# PrefVote::Core::Result
# ABSTRACT: internal voting-result structure used by PrefVote::Core
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
# PrefVote::Core result record from each round, for voting methods which use rounds
#
package PrefVote::Core::Result;

use utf8;
use autodie;
use Readonly;

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common       qw(Enum NonEmptySimpleStr PositiveOrZeroNum);
use PrefVote::Core::Set qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote';

# constants
Readonly::Hash my %blackbox_spec => (
    name => [qw(set string)],
    type => [qw(string)],
);
PrefVote::Core::TestSpec->register_blackbox_spec( __PACKAGE__, spec => \%blackbox_spec );

has name => (
    is       => 'ro',
    isa      => Set [NonEmptySimpleStr],
    required => 1,
    handles  => {
        name_all   => 'elements',
        name_count => 'size',
        name_empty => 'is_empty',
    },
);

has type => (
    is       => 'ro',
    isa      => Enum [qw(winner eliminated)],
    required => 1,
);

1;

__END__

# POD documentation
=encoding utf8

=head1 SYNOPSIS

    use PrefVote::Core::Result;
    use Set::Tiny;

    $result = PrefVote::Core::Result->new(type => $type, name => set(@names);

    $count = $result->name_count();
    $empty = $result->name_empty();
    @cand = $result->name_all();
    $type = $result->type();

=head1 DESCRIPTION

⛔ This is for PrefVote internal use only.

PrefVote::Core::Result is used to store results from a single L<PrefVote::Core::Round> structure for voting methods which use rounds, including STV and Schulze.

The result of the round is recorded with the name field containing a L<Set::Tiny> of strings with candidate/choice names. The type parameter is an enumeration with either of the strings "winner" or "eliminated". A PrefVote::Core::Result shoild not be created in a PrefVote::Core::Round if there was no result in the round.

=head1 ATTRIBUTES

=over 1

=item name

'Name' is a L<Set::Tiny> containing the name(s) of candidates in the results of this round.
All candidates listed in the set are tied.
The type of result (win or elimination) is determined by the type attribute.

=item type

'Type' is a string containing either 'winner' or 'eliminated' to indicate the type of result.

=back

=head1 METHODS

=over 1

=item name_all()

returns a list of strings which are the candidate ID strings contained in the set from the 'name' attribute.

=item name_count()

returns an integer with the number of candidates contained in the set from the 'name' attribute.

=item name_empty()

returns a boolean value true if the 'name' attribute is empty, false otherwise.
Under normal circumstances this should be true when the I<PrefVote::Core::Result> object was instantiated at all.
When there are no results for a round, the round's result would be an undefined value.

=back

=head1 SEE ALSO

L<PrefVote::Core>, L<PrefVote::Core::Round>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
