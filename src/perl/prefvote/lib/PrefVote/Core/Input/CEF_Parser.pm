# PrefVote::Core::Input::CEF_Parser
# ABSTRACT: Condorcet Election Format (CEF) standalone parser generated by Parse::Yapp
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0

# copyright for Parse::Yapp::Driver code which is automatically inserted into the build:
#   Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
#   Copyright © 2017 William N. Braswell, Jr.
#   See Parse::Yapp(3) for legal use and distribution rights
# more info on Parse::Yapp is at https://metacpan.org/pod/Parse::Yapp

####################################################################
#    This file was generated using Parse::Yapp version 1.21.
#        Don't edit this file, use source file instead.
#             ANY CHANGE MADE HERE WILL BE LOST !
####################################################################

package PrefVote::Core::Input::CEF_Parser;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Carp qw(croak);

@PrefVote::Core::Input::CEF_Parser::ISA = qw(Parse::Yapp::Driver);
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Copyright © 2017 William N. Braswell, Jr.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

# CORRELATION #py001: $VERSION must be changed in both Parse::Yapp & Parse::Yapp::Driver
$VERSION = '1.21';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------


#line 8 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"

    use Readonly;
    Readonly::Array my @CEF_TOKENS => (
        [ EMPTY_RANKING => qr(/EMPTY_RANKING/)x, ],
        [ TAGDELIM      => qr([|][|])x, ],
        [ ','           => qr([,])x, ],
        [ '^'           => qr([\^])x, ],
        [ '*'           => qr([*])x, ],
        [ '='           => qr([=])x, ],
        [ '>'           => qr([>])x, ],
        [ INT           => qr(\d+)x, ],
        [ WORD          => qr(\w+)x, ],
    );


sub new {
    my($class)=shift;
    ref($class)
        and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7,
			'EMPTY_RANKING' => 8
		},
		GOTOS => {
			'line' => 4,
			'tag' => 5,
			'equal_list' => 6,
			'words' => 1,
			'ranking' => 2,
			'word' => 3,
			'candidate' => 12,
			'tags' => 9,
			'choice_list' => 10
		}
	},
	{#State 1
		ACTIONS => {
			"," => -5,
			'WORD' => 7,
			'TAGDELIM' => -5,
			'INT' => 11
		},
		DEFAULT => -12,
		GOTOS => {
			'word' => 13
		}
	},
	{#State 2
		DEFAULT => -2
	},
	{#State 3
		DEFAULT => -21
	},
	{#State 4
		ACTIONS => {
			'' => 14
		}
	},
	{#State 5
		DEFAULT => -4
	},
	{#State 6
		ACTIONS => {
			"=" => 15
		},
		DEFAULT => -9
	},
	{#State 7
		DEFAULT => -22
	},
	{#State 8
		ACTIONS => {
			"*" => 20,
			"^" => 17
		},
		DEFAULT => -13,
		GOTOS => {
			'multipliers' => 18,
			'quantifier' => 19,
			'weight' => 16
		}
	},
	{#State 9
		ACTIONS => {
			"," => 21,
			'TAGDELIM' => 22
		}
	},
	{#State 10
		ACTIONS => {
			"*" => 20,
			"^" => 17,
			">" => 24
		},
		DEFAULT => -13,
		GOTOS => {
			'quantifier' => 19,
			'weight' => 16,
			'multipliers' => 23
		}
	},
	{#State 11
		DEFAULT => -23
	},
	{#State 12
		DEFAULT => -11
	},
	{#State 13
		DEFAULT => -20
	},
	{#State 14
		DEFAULT => 0
	},
	{#State 15
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7
		},
		GOTOS => {
			'words' => 25,
			'word' => 3,
			'candidate' => 26
		}
	},
	{#State 16
		ACTIONS => {
			"*" => 20
		},
		DEFAULT => -17,
		GOTOS => {
			'quantifier' => 27
		}
	},
	{#State 17
		ACTIONS => {
			'INT' => 28
		}
	},
	{#State 18
		DEFAULT => -7
	},
	{#State 19
		ACTIONS => {
			"^" => 17
		},
		DEFAULT => -16,
		GOTOS => {
			'weight' => 29
		}
	},
	{#State 20
		ACTIONS => {
			'INT' => 30
		}
	},
	{#State 21
		ACTIONS => {
			'WORD' => 7,
			'INT' => 11
		},
		GOTOS => {
			'tag' => 31,
			'words' => 32,
			'word' => 3
		}
	},
	{#State 22
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7,
			'EMPTY_RANKING' => 8
		},
		GOTOS => {
			'equal_list' => 6,
			'words' => 25,
			'ranking' => 33,
			'word' => 3,
			'candidate' => 12,
			'choice_list' => 10
		}
	},
	{#State 23
		DEFAULT => -6
	},
	{#State 24
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7
		},
		GOTOS => {
			'candidate' => 12,
			'equal_list' => 34,
			'words' => 25,
			'word' => 3
		}
	},
	{#State 25
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7
		},
		DEFAULT => -12,
		GOTOS => {
			'word' => 13
		}
	},
	{#State 26
		DEFAULT => -10
	},
	{#State 27
		DEFAULT => -15
	},
	{#State 28
		DEFAULT => -19
	},
	{#State 29
		DEFAULT => -14
	},
	{#State 30
		DEFAULT => -18
	},
	{#State 31
		DEFAULT => -3
	},
	{#State 32
		ACTIONS => {
			'INT' => 11,
			'WORD' => 7
		},
		DEFAULT => -5,
		GOTOS => {
			'word' => 13
		}
	},
	{#State 33
		DEFAULT => -1
	},
	{#State 34
		ACTIONS => {
			"=" => 15
		},
		DEFAULT => -8
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'line', 3,
sub
#line 38 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{
                                    my %attr;
                                    if ( ref $_[3][0] eq 'HASH' ) {
                                        # include multiplier hash contents if it exists
                                        my $subattr = shift @{$_[3]};
                                        %attr = %$subattr;
                                    }
                                    $attr{tags} = [ sort @{$_[1]} ];
                                    return [ \%attr, @{$_[3]} ];
                                }
	],
	[#Rule 2
		 'line', 1,
sub
#line 48 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1]; }
	],
	[#Rule 3
		 'tags', 3,
sub
#line 52 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ @{$_[1]}, $_[3] ]; }
	],
	[#Rule 4
		 'tags', 1,
sub
#line 53 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ $_[1] ]; }
	],
	[#Rule 5
		 'tag', 1,
sub
#line 57 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1]; }
	],
	[#Rule 6
		 'ranking', 2,
sub
#line 61 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ (defined $_[2]) ? ($_[2]) : (), @{$_[1]} ]; }
	],
	[#Rule 7
		 'ranking', 2,
sub
#line 62 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ (defined $_[2]) ? ($_[2]) : () ]; }
	],
	[#Rule 8
		 'choice_list', 3,
sub
#line 66 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ @{$_[1]}, $_[3] ]; }
	],
	[#Rule 9
		 'choice_list', 1,
sub
#line 67 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ $_[1] ]; }
	],
	[#Rule 10
		 'equal_list', 3,
sub
#line 71 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ @{$_[1]}, $_[3] ]; }
	],
	[#Rule 11
		 'equal_list', 1,
sub
#line 72 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return [ $_[1] ]; }
	],
	[#Rule 12
		 'candidate', 1,
sub
#line 76 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1]; }
	],
	[#Rule 13
		 'multipliers', 0, undef
	],
	[#Rule 14
		 'multipliers', 2,
sub
#line 81 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return { %{$_[1]}, %{$_[2]} }; }
	],
	[#Rule 15
		 'multipliers', 2,
sub
#line 82 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return { %{$_[1]}, %{$_[2]} }; }
	],
	[#Rule 16
		 'multipliers', 1,
sub
#line 83 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1]; }
	],
	[#Rule 17
		 'multipliers', 1,
sub
#line 84 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1]; }
	],
	[#Rule 18
		 'quantifier', 2,
sub
#line 88 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return { quantifier => $_[2]}; }
	],
	[#Rule 19
		 'weight', 2,
sub
#line 92 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return { weight => $_[2]}; }
	],
	[#Rule 20
		 'words', 2,
sub
#line 96 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return $_[1] . " " . $_[2]; }
	],
	[#Rule 21
		 'words', 1,
sub
#line 97 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return "" . $_[1]; }
	],
	[#Rule 22
		 'word', 1,
sub
#line 101 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return "" . $_[1]; }
	],
	[#Rule 23
		 'word', 1,
sub
#line 102 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"
{ return 0 + $_[1]; }
	]
],
                                  @_);
    bless($self,$class);
}

#line 105 "/home/ikluft/src/github/prefvote/src/perl/prefvote/lib/PrefVote/Core/Input//CEF_Parser.yp"


sub _Error
{
    my ( $parser ) = @_;
    my $expect_str = ( scalar $parser->YYExpect > 0 ) ? ( join( ' ', sort $parser->YYExpect )) : "";
    my $errmsg = ( exists $parser->YYData->{ERRMSG} )
        ?  $parser->YYData->{ERRMSG}
        : "Syntax error at position " . $parser->{USER}{CHARNO}
            . (( defined $parser->YYCurtok and length $parser->YYCurtok > 0 )
                ? ", found " . $parser->YYCurtok . " '" . $parser->YYCurval . "'" : "" )
            . (( length $expect_str > 0 ) ? ", expected $expect_str" : "" );
    croak $errmsg;
}

sub _Lexer
{
    my ($parser) = shift;

    $parser->YYData->{INPUT}
        or return ( '', undef );

    if( $parser->YYData->{INPUT} =~ s/^ ( \s+ )//x ) {
        $parser->{USER}{CHARNO} += length $1;
    }

    for ( $parser->YYData->{INPUT} ) {
        foreach my $token_pair ( @CEF_TOKENS ) {
            my ( $token_name, $token_regex ) = @$token_pair;
            if (s/ ^ ( $token_regex ) //x) {
                $parser->{USER}{CHARNO} += length $1;
                return ( $token_name, $1 );
            }
        }
    }
    return;
}

sub parse
{
    my ($self, $input_str) = @_;
    $self->YYData->{INPUT} = $input_str;
    $self->{USER}{CHARNO}  = 0;
    my $result = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/prefvote/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/prefvote/pulls>
