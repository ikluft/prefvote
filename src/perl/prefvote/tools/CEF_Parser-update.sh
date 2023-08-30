#!/bin/sh
# CEF_Parser-update.sh - shell warpper for CEF_Parser-update.pl to update CEF_Parser.pm with minimal diffs
# Copyright (c) 2023 by Ian Kluft
# Open Source license: Apache License 2.0 https://www.apache.org/licenses/LICENSE-2.0
#
# Run this to update the generated parser code after modifications to the CEF grammar.
export PERL_HASH_SEED=0
export PERL_PERTURB_KEYS="NO"
readlink=$(which readlink)
dirname=$(which dirname)
if [ -n "$readlink" ] && [ -n "$dirname" ]
then
    # find location of the script because CEF_Parser-update.pl is in the same directory
    canonical_script="$( $readlink -f -- "$0" )"
    dir=$( $dirname -- "$canonical_script")
else
    # without readlink and dirname, we're at a disadvantage to determine the location of the script
    # -> fall back to a requirement to run this script from the build root
    dir="tools"
fi

# find the update script
update_script="$dir/CEF_Parser-update.pl"
if [ ! -f "$update_script" ]
then
    echo "update script not found at $update_script"
    exit 1
fi

# run the update script
perl "$update_script"
