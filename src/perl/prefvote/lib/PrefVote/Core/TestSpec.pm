# PrefVote::Core::TestSpec
# ABSTRACT: PrefVote blackbox testing checklist processing
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2013);    # require 5.16.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::TestSpec;

use autodie;
use Data::Dumper;
use PrefVote::Core::Exception;
use PrefVote::Core::InternalDataException;
use PrefVote::Core::TestNode;

# class defintions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(HashRef InstanceOf);
extends 'PrefVote';

# per-class registry of blackbox test specs
# this is package-scoped so accessible only by class functions
my %spec_registry;

sub register_blackbox_spec
{
    my @args = @_;
    if ( $args[0] eq __PACKAGE__ ) {

        # omit this class from first argument so we can call this as a class method
        shift @args;
    }
    my $client_class = shift @args;
    my %args         = @args;
    $spec_registry{$client_class} = {};
    foreach my $key ( keys %args ) {
        $spec_registry{$client_class}{$key} = $args{$key};
    }
    return;
}

# get the entire spec registry - for testing only
sub get_spec_registry
{
    return \%spec_registry;
}

# read blackbox test spec by client class name
sub get_blackbox_spec
{
    my @args = @_;
    if ( $args[0] eq __PACKAGE__ ) {

        # omit this class from first argument so we can call this as a class method
        shift @args;
    }
    my $client_class = $args[0];
    my %result;
    my $class = $client_class;
    while ($class) {
        foreach my $key ( keys %{ $spec_registry{$class}{spec} } ) {
            if ( exists $spec_registry{$class}{spec}{$key} and not exists( $result{$key} ) ) {
                $result{$key} = $spec_registry{$class}{spec}{$key};
            }
        }
        $class = $spec_registry{$class}{parent} // undef;
    }
    return \%result;
}

# blackbox test checklist tree structure
# This defines the tests to perform
# loaded from YAML - includes tests to examine data structures of the currently-loaded voting-method subclass
has checklist => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

# this is a tree of tests performed, aggregating refs to the checklist tree, per-class test specs, and test values
# Nodes are created here upon navigation and aggregation of the data for each test
has testroot => (
    is       => 'rw',
    isa      => InstanceOf ["PrefVote::Core::TestNode"],
    required => 0,
);

# top-level tree traversal for blackbox tests
sub check
{
    my ( $self, $value ) = @_;

    # check parameters
    my $value_ref = ref $value;
    if ( not $value_ref ) {
        PrefVote::Core::InternalDataException->throw(
            classname   => __PACKAGE__,
            attribute   => "value",
            description => "scalar value received, object ref expected"
        );
    }
    if ( not exists $spec_registry{$value_ref} ) {
        PrefVote::Core::InternalDataException->throw(
            classname   => __PACKAGE__,
            attribute   => "value",
            description => "unrecognized object $value_ref"
        );
    }

    # return list of tests collected from traversing the tree from the root node
    $self->debug_print("check($value_ref)");
    my $root_node = PrefVote::Core::TestNode->new(
        name    => $value_ref,
        plan    => $self->{checklist},
        objref  => $value,
        objpath => [],
        parent  => undef
    );
    $self->testroot($root_node);    # save test tree for later inspection/troubleshooting if necessary
    __PACKAGE__->debug_print( "root node: " . Dumper($root_node) );
    return $root_node->check();
}

1;

__END__

# POD documentation
=encoding utf8

=head1 NAME

PrefVote::Core::TestSpec - PrefVote blackbox testing checklist processing

=head1 SYNOPSIS

  # blackbox testing structure
  # example from PrefVote::STV, used this way by classes with data for black-box testing
  Readonly::Hash my %blackbox_spec => (
      winners => [qw(list set string)],
      eliminated => [qw(list set string)],
      rounds => [qw(list PrefVote::STV::Round)],
  );
  PrefVote::Core::TestSpec->register_blackbox_spec(__PACKAGE__, spec => \%blackbox_spec, parent => 'PrefVote::Core');

  # PrefVote::Core::blackbox_check method calls PrefVote::Core::TestSpec::check()
  # example from PrefVote::Core's bin/vote-count
  my @tests = $vote_obj->blackbox_check();
  PrefVote::Core::TestUtil::do_tests(@tests);

=head1 DESCRIPTION

The TestSpec class contains a testing checklist for a class.
Each class in PrefVote must define one if it contains data for inspection in blackbox testing.
The test checklist contains a hash of the attributes and their data types for the client class which is to be tested.

=head1 ATTRIBUTES

=over 1

=item checklist

This hashref contains the testing checklist representing a client class for blackbox testing.
Each key matches the name of an attribute of the client class, and contains data type info for testing that attribute.
The data type info is an arrayref containing strings indicating either a container data type
(I<hash>, I<list> or I<set>) or value type (I<string>, I<bool>, I<int> or I<fp>).

=over 1

=item hash

a hash using a string as a key, containing nodes of the data type specified next in the array from the checklist,
which may include another layer of container

=item list

an array of nodes of the data type specified next in the array from the checklist,
which may include another layer of container

=item set

an unordered set of nodes of the data type specified next in the array from the checklist, which cannot be a container

=item string

string value

=item bool

boolean value expressed as integer 0 (false) or 1 (true)

=item int

integer value

=item fp

floating point value - precision will be limited to the internal storage precision limit of PrefVote
which is 10 digits past the decimal point

=back

=item testroot

This is a reference to a L<PrefVote::Core::TestNode> object which is the root of this TestSpec's client class' instance
being tested.
It is the root of a tree, and so may contain references to subnodes of L<PrefVote::Core::TestNode>.

=back

=head1 METHODS

=over 1

=item register_blackbox_spec

This is called by classes to declare the structure of data for black-box testing.
The first parameter is the name of the client class, which should just be provided by using __PACKAGE__.
Parameters after that are key/value pairs.
Currently I<spec> and I<parent> are recognized.

The I<spec> parameter is required. It is a hashref which will be used to initialize the I<checklist> attribute above.

The I<parent> parameter is optional. If provided it must be a string with the name of the parent class
for black-box testing. With this info, the parent class' test spec will be inherited by the current client class.
So its attributes should not be duplicated in the checklist data for this client class.

=item get_spec_registry

⛔ This is only used for testing.

This returns the internal spec registry, which is a hashref mapping class names to their test checklist structures.

=item get_blackbox_spec

⛔ This is for PrefVote internal use only.

This is called by L<PrefVote::Core::TestNode> to look up black-box test structure metadata.

=item check

This is called by L<PrefVote::Core> to generate a list of black-box tests.
It should not be called directly - instead use L<PrefVote::Core>'s blackbox_check() method.
That list can then be provided to PrefVote::Core::TestUtil::do_tests() to run the tests and generate TAP results.

=back

=head1 SEE ALSO

L<PrefVote>
L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
