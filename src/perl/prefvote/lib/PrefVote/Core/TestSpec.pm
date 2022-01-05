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
use Config;
use Scalar::Util 'reftype';
use Readonly;
use Data::Dumper;
use PrefVote::Core::Exception;
use PrefVote::Core::InternalDataException;

# class defintions
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(HashRef);
extends 'PrefVote';

# constants
Readonly::Scalar my $fp_epsilon => (($Config{doublesize} >= 8) ? 2**-53 : 2**-24); # fp epsilon for fp_equal()

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
has testtree => (
    is => 'rw',
    isa => HashRef,
    default => sub { return {} },
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

# process blackbox test spec for an object reference
sub node_obj
{
    my %opts = @_;
    my @tests;

    __PACKAGE__->debug_print("node_obj(".(ref $opts{value}).")");
    my $spec = Readonly::Clone $opts{value}->blackbox_spec();
    my $node_path = baseclass($opts{value});
    foreach my $attr (keys %$spec) {
        if (exists $opts{list}{$attr}) {
            push @tests, node(path => [@{$opts{path}}, $node_path, $attr], list => $opts{list}{$attr},
                value => $opts{value}{$attr}, level => $opts{level}+1, spec => $spec->{$attr});
        }
    }
    return @tests;
}

# process blackbox test spec for a hash
sub node_hash
{
    my %opts = @_;
    my @tests;

    __PACKAGE__->debug_print("node_hash(".join(" ", sort keys %{$opts{list}}).")");
    foreach my $key (sort keys %{$opts{list}}) {
        push @tests, {type => "ok", value => (exists $opts{value}{$key}),
            description => join("-", @{$opts{path}}, $key)." exists"};
        if (ref $opts{value}{$key}) {
            push @tests, node(path => [@{$opts{path}}, $key], list => $opts{list}{$key},
                value => $opts{value}{$key}, level => $opts{level}+1, spec => $opts{spec});
        } else {
            push @tests, {type => "is", expected => $opts{list}{$key}, value => $opts{value}{$key},
                description => join("-", @{$opts{path}}, $key)."=".$opts{list}{$key}};
        }
    }
    return @tests;
}

# process blackbox test spec for a list
sub node_list
{
    my %opts = @_;
    my @tests;

    # generate tests for list comparison
    __PACKAGE__->debug_print("node_list(".join(" ", @{$opts{value}}).")");
    my $cl_count = scalar @{$opts{list}};
    my $value_count = scalar @{$opts{value}};
    my $count_cmp = $cl_count <=> $value_count;
    push @tests, {type => "is", expected => $cl_count, value => $value_count,
        description => join("-", @{$opts{path}})." list length=$cl_count"};
    if ($cl_count==1) {
        # short-circuit the search if there's only one item in the list
        push @tests, node(path => [@{$opts{path}}, 0], list => $opts{list}[0],
            value => $opts{value}[0], level => $opts{level}+1, spec => $opts{spec});
        return @tests;
    }
    for (my $i=0; $i<$cl_count; $i++) {
        # process sub-lists recursively
        if (ref $opts{list}[$i] eq "ARRAY") {
            push @tests, node(path => [@{$opts{path}}, $i], list => $opts{list}[$i],
                value => $opts{value}[$i], level => $opts{level}+1, spec => $opts{spec});
            next;
        }

        # search for match: lists of scalars indicate ties so matches aren't necessarily at the same index
        my $index;
        if ($opts{this_spec} eq "ordered") {
            # at result level, matches must be the same index
            $index=$i;
        } elsif ($opts{this_spec} eq "unordered") {
            # on sub-lists, lists indicate ties so matches don't necessarily have to be at the same index
            for (my $pos=0; $pos<scalar @{$opts{value}}; $pos++) {
                if ($opts{value}[$pos] eq $opts{list}[$i]) {
                    $index = $pos;
                    last;
                }
            }
        }
        my $description = join("-", @{$opts{path}}, $i)." matches ".$opts{list}[$i];
        __PACKAGE__->debug_print("node_list compare (index=".($index // "undef")."): $description from "
            .join(" ",@{$opts{list}}));
        push @tests, node(path => [@{$opts{path}}, $i], list => $opts{list}[$i],
            value => $opts{value}[$index], level => $opts{level}+1, spec => $opts{spec});
    }
    return @tests;
}

# generate test results from nodes in blackbox test spec tree
sub node
{
    my %opts = @_;

    # verify required parameters
    __PACKAGE__->debug_print("node ".Dumper(\%opts));
    {
        my @missing;
        foreach my $param (qw(path list value level)) {
            if (not exists $opts{$param}) {
                push @missing, $param;
            }
        }
        if (@missing) {
            PrefVote::Core::Exception->throw(classname => __PACKAGE__,
                description => "missing parameter: ".join(" ", @missing));
        }
    }

    # handle checklists for subclasses with their own blackbox test specs
    # do not increment level in this case because we're entering the subclass's test spec for this level
    if ((not exists $opts{spec}) and (ref $opts{value}) and $opts{value}->can("blackbox_spec")) {
        return node_obj(%opts);
    }

    # select specification entry for the current test
    my $this_spec = shift @{$opts{spec}};
    __PACKAGE__->debug_print("node(path=".join('-',@{$opts{path}})." level=$opts{level}) -> "
        .($this_spec // "undef"));

    # test a scalar value
    if ($this_spec eq "string") {
        # short-circuit the search if the expected value is a scalar
        return ({type => "is", expected => $opts{list}, value => $opts{value},
            description => join("-", @{$opts{path}})."=".$opts{list}." (str)"});
    }
    if ($this_spec eq "int" ) {
        # short-circuit the search if the expected value is a scalar
        return ({type => "cmp_ok", expected => $opts{list}, op => "==", value => $opts{value},
            description => join("-", @{$opts{path}})."=".$opts{list}." (int)"});
    }
    if ($this_spec eq "fp" ) {
        # short-circuit the search if the expected value is a scalar
        return ({type => "ok", value => fp_equal($opts{value}, $opts{list}),
            description => join("-", @{$opts{path}})."=".$opts{list}." (fp)"});
    }

    # generate tests for hashes
    if ($this_spec eq "hash") {
        return node_hash(%opts);
    }

    # generate tests for ordered or unordered lists
    if ($this_spec eq "ordered" or $this_spec eq "unordered") {
        return node_list(%opts, this_spec => $this_spec);
    }
 
    # throw exception for unrecognized spec
    PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "spec",
        description => "unrecognized test spec '$this_spec' for ".join("-", @{$opts{path}}));
}

# top-level tree traversal for blackbox tests
sub check
{
    my ($self, $checklist, $value) = @_;

    # check parameters
    if (not $value->can("blackbox_spec")) {
        PrefVote::Core::InternalDataException->throw(classname => __PACKAGE__, attribute => "value",
            description => "unrecognized object ".(ref $value));
    }

    # return list of tests collected from traversing the tree from the root node
    $self->debug_print("check(".(ref $value).")");
    return node(path => [], list => $checklist, value => $value, level => 0);

    # check voting object against checklist
#    foreach my $key (sort keys %$checklist) {
#        if (not exists $self->{$key}) {
#            push @tests, {type => "fail", description => "root->$key"};
#            next;
#        }
#        my $nodetype = ref $self->{$key};
#        if ($nodetype->can("blackbox_spec")) {
#            push @tests, $nodetype->blackbox_check([$key], $checklist->{$key}, $self->{$key}, 0);
#        }
#        if (ref $self->{$key} eq "ARRAY") {
#            push @tests, node([$key], $checklist->{$key}, $self->{$key}, 0);
#        } elsif ($key eq "rounds") {
#            for (my $round_num=0; $round_num<$self->rounds_count(); $round_num++) {
#                 push @tests, $self->round_get($round_num)->blackbox_check($checklist->{rounds}[$round_num],
#                    $round_num);
#            }
#        } else {
#            croak "unrecognized test key $key";
#        }
#    }
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
