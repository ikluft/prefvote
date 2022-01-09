# PrefVote::Core::TestSpec
# ABSTRACT: PrefVote blackbox testing checklist processing
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
 
# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::TestSpec;

use autodie;
use Carp qw(croak);
use Data::Dumper;
use PrefVote::Core::Exception;
use PrefVote::Core::InternalDataException;
use PrefVote::Core::TestNode;

# class defintions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(HashRef InstanceOf);
extends 'PrefVote';

# blackbox test checklist tree structure
# This defines the tests to perform
# loaded from YAML - must provide data expected by voting-method subclasses
has checklist => (
    is => 'ro',
    isa => HashRef,
    required => 1,
);

# this is a tree of tests performed, aggregating refs to the checklist tree, per-class test specs, and test values
# Nodes are created here upon navigation and aggregation of the data for each test
has testroot => (
    is => 'rw',
    isa => InstanceOf["PrefVote::Core::TestNode"],
    required => 0,
);

# top-level tree traversal for blackbox tests
sub check
{
    my ($self, $value) = @_;

    # check parameters
    if (not $value->can("blackbox_spec")) {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "value",
            description => "unrecognized object ".(ref $value));
    }

    # return list of tests collected from traversing the tree from the root node
    $self->debug_print("check(".(ref $value).")");
    my $root_node = PrefVote::Core::TestNode->new(name => ref $value, plan => $self->{checklist},
        objref => $value, objpath => [], parent => undef);
    $self->testroot($root_node); # save test tree for later inspection/troubleshooting if necessary
    __PACKAGE__->debug_print("root node: ".Dumper($root_node));
    return $root_node->check();    
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::TestSpec - PrefVote blackbox testing checklist processing

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut