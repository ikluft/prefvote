# PrefVote::Core::TestNode
# ABSTRACT: PrefVote blackbox testing internal tree-node structure aggregating refs to testing data
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
 
# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::TestNode;

use autodie;
use Carp qw(croak);
use Data::Dumper;
use Config;
use Readonly;
use Scalar::Util 'reftype';

# class defintions
use Moo;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(Any Value Str Ref ScalarRef ArrayRef InstanceOf Maybe);
use Types::Common::Numeric qw(PositiveOrZeroInt);
extends 'PrefVote';

# constants
Readonly::Scalar my $fp_epsilon => (($Config{doublesize} >= 8) ? 2**-53 : 2**-24); # fp epsilon for fp_equal()

#
# data in each node is an aggregation of links to a specific point in the blackbox testing tree
#

# name for displaying path element
has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# checklist/plan item reference - this data comes from a test script such as in a YAML file
has plan => (
    is => 'ro',
    isa => Any,
    required => 1,
);

# reference to containing object
has objref => (
    is => 'ro',
    isa => InstanceOf["PrefVote"],
    required => 1,
);

# name of attribute and keys/indices path within containing object - empty means the top level of the object
has objpath => (
    is => 'ro',
    isa => ArrayRef[Value],
    required => 1,
    handles_via => 'Array',
    handles => {
        objpath_all => 'all',
        objpath_count => 'count',
        objpath_empty => 'is_empty',
        objpath_get => 'get',
        objpath_join => 'join',
    },
);

# tree navigation references: parent node, child nodes
# uses Maybe because it's undef for root node
has parent => (
    is => 'ro',
    isa => Maybe[InstanceOf["PrefVote::Core::TestNode"]],
    required => 1,
);
has child => (
    is => 'rw',
    isa => ArrayRef[InstanceOf["PrefVote::Core::TestNode"]],
    default => sub { return [] },
    required => 0,
    handles_via => 'Array',
    handles => {
        children => 'all',
        add_child => 'push',
        search_child => 'first',
    },
);

# utility function to get basename of a class
sub baseclass
{
    my $class_or_obj = shift;
    my $classname = (ref $class_or_obj) ? ref $class_or_obj : $class_or_obj;
    my $base = $classname;
    $base =~ s/^.*:://x;
    return $base;
}

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal {
    my ($x, $y) = @_;
    return ($x-$y > -$fp_epsilon and $x-$y < $fp_epsilon);
}

# get a child node by name/index
sub child_by_name
{
    my ($self, $name) = @_;
    return $self->search_child(sub{ $_->{name} eq $name });
}

sub in_hierarchy
{
    my $str = shift;
    return (($str =~ /^PrefVote/x) and ($str->isa("PrefVote")));
}

# lookup value based on the node's position within an object
sub value
{
    my $self = shift;

    # to start, the value is the object itself - then descend into it
    my $objpos = $self->objref();

    # traverse object spec from top level to find value
    my @path = $self->objpath_all();
    $self->debug_print("value path=".join("-", @path));
    while (scalar @path > 0) {
        my $key = shift @path;
        if (reftype $objpos eq "HASH") {
            $objpos = $objpos->{$key};
        } elsif (reftype $objpos eq "ARRAY") {
            $objpos = $objpos->[$key];
        } else {
            PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => $key,
                description => "value: attempt to descend into non-container at "
                .(ref $self->objref())."-".$self->objpath_join("-"));
        }
    }
    $self->debug_print("value result=".($objpos // "undef"));
    return $objpos;
}

# lookup test spec (data type) based on the node's position within an object
# optional $lookahead parameter can query children of current node, since no other data links exist
sub spectype
{
    my ($self, $lookahead) = @_;

    # traverse object spec from top level to find spec type
    # get object path
    my @path = ($self->objpath_all(), (defined $lookahead ? ($lookahead) : ()));
    $self->debug_print("spectype path=".join("-", @path));
    my %spec = %{$self->objref()->blackbox_spec()};
    my $spectype = ref $self->objref();
    my $specindex = 0;
    #$self->debug_print("spectype spec=".Dumper(\%spec));

    # special treatment for first item in path it's the attribute name used in hash lookup
    my $attr = shift @path;
    my $objpos = $self->objref()->{$attr};
    $spectype = $spec{$attr}[$specindex++];

    # descend in spec to find data type of current node
    while (scalar @path > 0) {
        my $key = shift @path;
        my $objtype = ref $objpos;
        $self->debug_print("spectype attr=$attr key=$key spectype=$spectype");
        if ($objtype eq "HASH") {
            $objpos = $objpos->{$key};
        } elsif ($objtype eq "ARRAY") {
            $objpos = $objpos->[$key];
        } else {
            PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => $attr,
                description => "spectype: attempt to descend into non-container at "
                .$spectype."-".$self->objpath_join("-"));
        }
        $spectype = $spec{$attr}[$specindex++];
    }
    $self->debug_print("spectype result=".($spectype // "undef"));
    return $spectype;
}

# get tree-path of current node from names of node up from here to the root
sub path
{
    my $self = shift;
    my @path;
    my $node = $self;
    while (defined $node) {
        unshift @path, $node->name();
        $node = $node->parent();
    }
    return @path;
}

# create new sub-node and return the blackbox tests from it
sub subnode
{
    my ($self, %opts) = @_;
    my %params; # only pass expected params to new()

    # check for required options
    $self->debug_print("subnode ".Dumper(\%opts));
    {
        my @missing;
        foreach my $param (qw(name plan objref objpath)) {
            if (exists $opts{$param}) {
                $params{$param} = $opts{$param};
            } else {
                push @missing, $param;
            }
        }
        if (@missing) {
            PrefVote::Core::Exception->throw(classname => __PACKAGE__,
                description => "missing parameter: ".join(" ", @missing));
        }
    }

    # intercept parameters which point to a new object with its own testspec structure
    my $value = $self->value();
    if ((scalar @{$opts{objpath}} > 0) and not in_hierarchy($opts{name})
        and (reftype $value eq "HASH" or reftype $value eq "ARRAY"))
    {
        # get the value of the child node
        my $subvalue;
        if (reftype $value eq "HASH") {
            # check hash node's child node
            if (not exists $value->{$opts{name}}) {
                PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "name",
                    description => "hash node does not contain ".$value->{$opts{name}}." at "
                        .join("-", $self->path()));
            }
            $subvalue = $value->{$opts{name}};
        } else {
            # check array node's child node
            if ($opts{name} !~ /^[0-9]+$/) {
                PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "name",
                    description => "array node node index is not numeric ".$value->[$opts{name}]." at "
                        .join("-", $self->path()));
            }
            if (not exists $value->[$opts{name}]) {
                PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "name",
                    description => "array node does not contain ".$value->[$opts{name}]." at "
                        .join("-", $self->path()));
            }
            $subvalue = $value->[$opts{name}];
        }

        # verify the type of the child node and if it's in PrefVote hierarchy, enter its test spec tree
        my $subvalue_type = ref $subvalue;
        if (in_hierarchy($subvalue_type)) {
            my $lookahead_spec = $self->spectype($opts{name});
            if ($subvalue_type ne $lookahead_spec) {
                PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "name",
                    description => "node type mismatch $subvalue_type vs $lookahead_spec at "
                        .join("-", $self->path(), $opts{name}));
            }
            return $self->subnode(name => $subvalue_type, plan => $opts{plan},
                objref => $subvalue, objpath => []);
        }
    }

    # instantiate new node
    my $subnode = $self->new(%params, parent => $self);

    # save the sub-node under this node
    $self->add_child($subnode);

    # collect and return the blackbox tests from the new node (and any sub-tree it creates in the process)
    return $subnode->check();
}

# process blackbox test spec for an object reference
sub node_obj
{
    my $self = shift;
    my @tests;

    $self->debug_print("node_obj(".(ref $self->objref())."-".$self->objpath_join("-").")");
    my $spec = $self->{objref}->blackbox_spec();
    foreach my $attr (keys %$spec) {
        if (exists $self->{plan}{$attr}) {
            push @tests, $self->subnode(name => $attr, plan => $self->{plan}{$attr},
                objref => $self->{objref}, objpath => [$attr]);
        }
    }
    return @tests;
}

# process blackbox test spec for a hash
sub node_hash
{
    my $self = shift;
    my @tests;

    $self->debug_print("node_hash: plan=".Dumper($self->{plan}));
    foreach my $key (sort keys %{$self->{plan}}) {
        push @tests, {type => "ok", value => (exists $self->value()->{$key}),
            description => join("-", $self->path(), $key)." exists"};
        if (ref $self->value()->{$key}) {
            push @tests, $self->subnode(name => $key, plan => $self->{plan}{$key}, objref => $self->{objref},
                objpath => [$self->objpath_all(), $key]);
        } else {
            push @tests, {type => "is", expected => $self->{plan}{$key}, value => $self->value()->{$key},
                description => join("-", $self->path(), $key)."=".$self->{plan}{$key}};
        }
    }
    return @tests;
}

# process blackbox test spec for a list
sub node_list
{
    my $self = shift;
    my @tests;

    # generate tests for list comparison
    my $value = $self->value();
    if (reftype $value ne "ARRAY") {
        # throw exception for incorrect data type (should be a list)
        $self->debug_print("node_hash(".join(" ", sort keys %{$self->{plan}}).")");
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "value",
            description => "node_list expected a list value (got ".((ref $value) ? ref $value : "scalar").") at "
                .join("-", $self->path()));
    }
    $self->debug_print("node_list(".join(" ", @$value).")");
    my $cl_count = scalar @{$self->{plan}};
    my $value_count = scalar @$value;
    my $count_cmp = $cl_count <=> $value_count;
    push @tests, {type => "is", expected => $cl_count, value => $value_count,
        description => join("-", $self->path())." list length=$cl_count"};
    if ($cl_count==1) {
        # short-circuit the search if there's only one item in the list
        push @tests, $self->subnode(name => 0, plan => $self->{plan}[0], objref => $self->{objref},
            objpath => [$self->objpath_all(), 0]);
        return @tests;
    }
    for (my $i=0; $i<$cl_count; $i++) {
        # process sub-lists recursively
        if (ref $self->{plan}[$i] eq "ARRAY") {
            push @tests, $self->subnode(name => $i, plan => $self->{plan}[$i], objref => $self->{objref},
            objpath => [$self->objpath_all(), $i]);
            next;
        }

        # create description text for test
        my $description = join("-", $self->path(), $i)." matches ".$self->{plan}[$i];
        $self->debug_print("node_list compare): $description from ".join(" ",@{$self->{plan}}));

        # if it's an unordered list, look for the same value anywhere in the list
        if ($self->spectype() eq "unordered") {
            # on sub-lists, lists indicate ties so matches don't necessarily have to be at the same index
            my $index;
            for (my $pos=0; $pos<scalar @$value; $pos++) {
                if ($value->[$pos] eq $self->{plan}[$i]) {
                    $index = $pos;
                    last;
                }
            }
            if (defined $index) {
                # list item comparison
                push @tests, $self->subnode(name => $i, plan => $self->{plan}[$index], objref => $self->{objref},
                    objpath => [$self->objpath_all(), $i]);
            } else {
                push @tests, {type => "fail", expected => $self->{plan}[$i], value => undef,
                    description => $description};
            }
        } else {
            # list item comparison
            push @tests, $self->subnode(name => $i, plan => $self->{plan}[$i], objref => $self->{objref},
                objpath => [$self->objpath_all(), $i]);
        }
    }
    return @tests;
}

# generate test cases from nodes in blackbox test spec tree
# this generates a tree of tests as necessary and returns all the tests from the tree
sub check
{
    my $self = shift;
    #$self->debug_print("check: ".Dumper($self));

    # handle checklists for subclasses with their own blackbox test specs
    if ($self->objpath_empty()) {
        return $self->node_obj();
    }

    # select specification entry for the current test
    $self->debug_print("check(path=".join('-',$self->path()));
    my $spec = $self->spectype();
    $self->debug_print("check(spec=".($spec // "undef"));

    # short-circuit the search if the expected value is a scalar
    if ($spec eq "string") {
        # return a string comparison test
        return ({type => "is", expected => $self->{plan}, value => $self->value(),
            description => join("-", $self->path())."=".$self->{plan}." (str)"});
    }
    if ($spec eq "bool" ) {
        # return a simple boolean test
        return ({type => "ok", value => $self->value(),
            description => join("-", $self->path())." (bool)"});
    }
    if ($spec eq "int" ) {
        # return integer comparison test
        return ({type => "cmp_ok", expected => $self->{plan}, op => "==", value => $self->value(),
            description => join("-", $self->path())."=".$self->{plan}." (int)"});
    }
    if ($spec eq "fp" ) {
        # return floating point comparison test - use fp_equal() since == operator doesn't work right for fp
        return ({type => "ok", value => fp_equal($self->value(), $self->{plan}),
            description => join("-", $self->path())."=".$self->{plan}." (fp)"});
    }

    # generate tests for hashes
    if ($spec eq "hash") {
        return $self->node_hash();
    }

    # generate tests for ordered or unordered lists
    if ($spec eq "ordered" or $spec eq "unordered") {
        return $self->node_list();
    }

    # throw exception for unrecognized spec
    PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "spec",
        description => "unrecognized test spec '$spec' for ".join("-", $self->path()));
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::TestNode - PrefVote blackbox testing internal tree-node structure aggregating refs to testing data

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut
