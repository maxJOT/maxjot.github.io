#!/usr/bin/env bash
#============================================================================
# Filename: box_example.sh
# Author:   maxJOT
# Purpose:  Demo using box functions.
# Platform: macOS/Linux running Bash > 4.2.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

# Examples: 

if (( BASH_VERSINFO[0] < 4 || \
    (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
  echo ${LINENO} "Bash version 4.2 or later required."
  echo; exit 1
fi

# Either copy & paste the box functions,
# or source execute a script defining these functions.
source box.sh

echo
box r --top                                # Draw the top of the box.  
box r "The rabbit jumps over the fox" 1    # End with 1 to split long lines.
box r "and escapes."
box r --middle                             # Draw a horizontal line
box r "http://maxjot.github.io/maxJOT/bash/bash-almanac.html"
box r --bottom                             # Draw the box bottom line.

echo
YL=$( tput bold; tput setaf 3; tput setab 4 ) # Yellow/blue
GN=$( tput bold; tput setaf 2; tput setab 4 ) # Green/blue
RD=$( tput bold; tput setaf 1; tput setab 4 ) # Red/blue
function struct { box 4 "${YL}$1" 1; box 4 "${GN}$2" 1; box 4 "${RD}$3"; }
text1=$( printf "%10s" yellow )
text2=$( printf "%10s" green )
text3=$( printf "%10s" red )
box 4 --top
box 4
struct "${text1}" "${text2}" "${text3}"
box 4
box 4 --bottom

echo
mute on # Disable keyobard interference/feedback.
box 0 --top
box 0
box 0 --bottom
# Move the cursor into the box (up 2 lines)
tput cuu1; tput cuu1
for ((i = 5 ; i >= 1 ; i--)); do
  # End box function with 2
  # to move the cursor to the beginning of the line.
  box 0 "Continue in $i second(s)..." 2 
  sleep 1
done
mute off # Restore original terminal attributes.
echo; echo; echo

unset -f box mute

## END
