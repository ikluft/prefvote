# PrefVote::Core::TestUtil
# ABSTRACT: testing utilities to contain Test::More runtime dependency away from non-test modules
# Copyright (c) 1998-2022 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
 
# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote::Core::TestUtil;

use autodie;
use Carp qw(croak);
use Data::Dumper;
use Test::More;
use base "PrefVote";

# run a single test
sub do_test
{
    my $test = shift;

    # process test case parameters as hash
    if ($test->{type} eq "is") {
        Test::More::is($test->{value}, $test->{expected}, $test->{description});
        return;
    }
    if ($test->{type} eq "cmp_ok") {
        Test::More::cmp_ok($test->{value}, $test->{op}, $test->{expected}, $test->{description});
        return;
    }
    if ($test->{type} eq "ok") {
        Test::More::ok($test->{value}, $test->{description});
        return;
    }
    if ($test->{type} eq "pass") {
        Test::More::pass($test->{description});
        return;
    }
    if ($test->{type} eq "fail") {
        Test::More::fail($test->{description});
        return;
    }
    Test::More::fail("unrecognized test type ".(defined $test->{type} ? "'".$test->{type}."'" : "(undef)")
        ." in test: ".$test->{description});
    return;
}

# run list of tests from data generated by PrefVote::Core::TestSpec::check()
sub do_tests
{
    my @tests = @_;

    __PACKAGE__->debug_print("tests ".Dumper(\@tests));
    Test::More::plan(tests => scalar @tests);
    foreach my $test (@tests) {
        do_test($test);
    }
    return;
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote::Core::TestUtil - testing utilities to contain Test::More runtime dependency away from non-test modules

=head1 SYNOPSIS

    require PrefVote::Core::TestUtil;
    $vote_obj->debug_print("checking tests: ".(ref $vote_obj));
    my @tests = $vote_obj->blackbox_check();
    PrefVote::Core::TestUtil::do_tests(@tests);

=head1 DESCRIPTION

PrefVote::Core::TestUtil is used for black-box testing of PrefVote.
It provides a function do_tests() which accepts the array of tests returned from
blackbox_check() from any voting method subclass of PrefVote::Core. It is meant to keep the dependency on
the L<Test::More> module separate from other run-time modules that shouldn't otherwise be muddied by a
dependence on a test module.

=head1 FUNCTIONS

=over 1

=item do_tests ( @tests )

=item do_test ( \%test )

=back

=head1 SEE ALSO

L<PrefVote::Core>

L<https://github.com/ikluft/prefvote>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut

