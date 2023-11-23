# PrefVote::KR2
# ABSTRACT: Kluft Rank-Rate (KR2) vote counting module for PrefVote
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package PrefVote::KR2;

use utf8;
use autodie;
use Data::Dumper;
use Readonly;
use Set::Tiny qw(set);

# class definitions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Common         qw(Str ArrayRef HashRef InstanceOf PositiveOrZeroInt NonEmptySimpleStr);
use PrefVote::Core::Float qw(fp_equal fp_cmp);
use PrefVote::Core::Set   qw(Set);
use PrefVote::Core::TestSpec;
extends 'PrefVote::Core';

# blackbox testing structure
Readonly::Hash my %blackbox_spec => (
    winners  => [qw(list set string)],
    pair     => [qw(hash hash PrefVote::KR2::PairData)],
);
PrefVote::Core::TestSpec->register_blackbox_spec(
    __PACKAGE__,
    spec   => \%blackbox_spec,
    parent => 'PrefVote::Core'
);
__PACKAGE__->ballot_input_ties_policy(1);    # set flag for Core: this class allows input ballots to set A/B ties

# TODO to be continued...
