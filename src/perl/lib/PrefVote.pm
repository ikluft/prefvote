# PrefVote
# ABSTRACT: Preference voting system
# derived from Vote::STV by Ian Kluft
# Copyright (c) 1998-2021 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015); # require 5.20.0 or later
## use critic (Modules::RequireExplicitPackage)

package PrefVote;
use autodie;
use Carp qw(croak);
my $debug=($ENV{PREFVOTE_DEBUG} // 0);

# new instance of vote-counting structure
sub new {
        my ($class, @args) = @_;
        my $self = {};
        bless $self, $class;
        $self->initialize(@args);
        return $self;
}

# initialize with valid choices for vote
sub initialize
{
	my $self = shift;
	my $attrs = shift;

	# required parameters
	foreach my $r_key ( "name", "choices" ) {
		if ( defined $attrs->{$r_key} ) {
			$self->{$r_key} = $attrs->{$r_key};
		} else {
			croak "initialization parameter $r_key not found\n";
		}
	}

	# optional parameters
	foreach my $o_key ( "seats", "end-time" ) {
		if ( defined $attrs->{$o_key} ) {
			$self->{$o_key} = $attrs->{$o_key};
		}
	}

	# defaults for missing optional parameters
	if ( !defined $self->{seats}) {
		$self->{seats} = 1;
	}

	# sanity checks
	if ( $self->{seats} < 1 ) {
		croak "seats up for election must be positive number\n";
	}

	# initialize tables
	$self->{ballots} = [];

	# callback for optional subclass-specific initialization
	if ($self->can("subclass_init")) {
		$self->subclass_init();
	}

	# debugging
	debug() and print STDERR "set choices to "
		.join(" ", keys %{$self->{choices}})."\n";

	return;
}

# check debug flag
sub debug
{
	return $debug;
}

# print debug message
sub debug_print
{
	my @strs = @_;
	debug() and print STDERR @strs;
	return;
}

# accessor
sub get
{
	my ($self, $key) = @_;
	if (not exists $self->{$key}) {
		return;
	}
	if (ref $self->{$key} eq "ARRAY") {
		return wantarray ? @{$self->{$key}} : join(" ", @{$self->{$key}});
	}
	return $self->{$key};
}

1;

__END__

# POD documentation

=head1 NAME

PrefVote - Preference voting system

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>

=cut