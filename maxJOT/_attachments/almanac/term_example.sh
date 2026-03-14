#!/usr/bin/env bash
#============================================================================
# Filename: term_example.sh
# Author:   maxJOT
# Purpose:  Demo using term_init function.
# Platform: macOS/Linux running Bash.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

# Examples

# Either copy & paste the box functions,
# or source execute a script defining these functions.
source term.sh


# Initialize
term_init
term_init demo

# More examples
echo
echo "${B3}${R4}Yellow text, blue background${T0}"
echo "${BD}bold ${B1}red ${B2}green ${B3}yellow ${C3}orange${T0}"
echo
echo "${BL}blink${T0} and ring my bell(RG)${RG}."
echo
echo "Demonstrating cursor postion and line erase:" 
echo "The ${BD}rabbit${T0} jumps over the ${C3}fox${T0} and"
echo -n "${B2}escapes${T0}." && sleep 2
echo -n "   ${U1}${EL}"   # Position the cursor above the current
sleep 2                   # line and erase the reminder of the line.
echo; echo "${U1}${ED}"   # Erase until end of screen.

# Do not taint the current shell environment.
# Only necessary if the script has been source executed. 
term_init cleanup

## END 
