#!/usr/bin/env bash
#============================================================================
# Filename: input_example.sh
# Author:   maxJOT
# Purpose:  Demo using get_reply function.
# Platform: macOS/Linux running Bash > 4.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

# Examples

# Either copy & paste the box functions,
# or source execute a script defining these functions.
source input.sh

echo
get_reply "Press any key to continue..."

echo
get_reply "Please answer (Y)es or (N)o:" "N Y"
case "${REPLY}" in
  Y) echo Well done, you hit the letter y. ;;
  N) echo You hit the letter n or Return to accept the default. ;;
  *) echo Invalid response. ;;
esac     

echo
echo get_reply menu demo
echo
echo "(1) Sample 1   (2) Sample 2   (3) Sample 3   (E) Exit" 
get_reply "Please choose a menu option:" "E 1 2 3"
STATUS=$?
case "${REPLY}" in
  1) echo "You choose #1" ;;
  2) echo "You choose #2" ;;
  3) echo "You choose #3" ;;
  E) echo "Exit..." ;;
esac
case $STATUS in
  0) echo all went well ;;
  3) echo you failed to choose a valid option ;;
esac
echo

## END
  
