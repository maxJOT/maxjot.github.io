#!/usr/bin/env bash
#============================================================================
# Filename: box.sh
# Author:   maxJOT
# Purpose:  Initialize box functions - demo.
# Platform: macOS/Linux running Bash > 4.2.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

function mute {
  # Optional feature to suppress keyboard and cursor output
  # when it can interfere with proper box and content rendering.
  #
  # $1 on:  Hide cursor, disable terminal echo, disable ctrl/s/q/c/d.
  #         Stop user/keyboard interference while rendering screen output.
  # $1 off: Restore previously saved terminal state.
  #
  local hc=$( tput civis ); local rc=$( tput cnorm )
  #
  case $1 in
   on) SAV=$( stty -g </dev/tty )  # Save tty settings. Global scope.
       stty -echo -icanon -ixoff intr '?' eof '?' </dev/tty
       printf ${hc} ;;
   off) stty ${SAV} </dev/tty
        printf ${rc} ;;
  esac
} 

function box {
  # $1 = Color scheme.
  # $2 = Text.
  # $3 = Format (optional):
  #      0 = standard newline (default).
  #      1 = do not move the cursor.
  #      2 = move the cursor to the beginning of the line (\r).
  # Example: box r --top
  #          box r "The rabbit jumps over the fox" 1
  #          box r "and escapes."
  #          box r --middle
  #          box r "http://maxjot.github.io/maxJOT/bash/bash-almanac.html"
  #          box r --bottom
  #
  local maxlen background indent fb t0
  local box_top box_middle box_bottom box1 box2 box3 box4 box5 box6 box7 box8
  t0=$( tput sgr0 )
  maxlen=65
  box1=$'\u250C' box2=$'\u2500' box3=$'\u2510' box4=$'\u2502'
  box5=$'\u2514' box6=$'\u2518' box7=$'\u251C' box8=$'\u2524'
  # Generate horizontal line.
  box2=$( eval printf "${box2}%.0s" {1..${maxlen}} )
  # Generate top middle and bottom box-lines.
  box_top=$( printf "${box1}${box2}${box3}" )
  box_middle=$( printf "${box7}${box2}${box8}" )
  box_bottom=$( printf "${box5}${box2}${box6}" )
  # Used for white space with background.
  # printf -v background '%*s' ${maxlen} '' 
  background=$( eval printf -- '\ %.0s' {1..${maxlen}} )
  # Set forground and background color.
  case $1 in
    4) fb=$( tput setaf 7; tput setab 4 ) ;; # white/blue
    0) fb=$( tput setaf 7; tput setab 0 ) ;; # black/white
    r) fb=$( tput rev ) ;; # Reverse
    *) fb= ;;      # No color
  esac
  indent="  ${fb}${box4}${t0}"
  if [[ "$2" == --top ]]; then
    printf "  ${fb}${box_top}${t0}\n"
    lastarg=0
  elif [[ "$2" == --bottom ]]; then
    printf "  ${fb}${box_bottom}${t0}\n"
    lastarg=0
  elif [[ "$2" == --middle ]]; then
    printf "  ${fb}${box_middle}${t0}\n"
    lastarg=0
  else
    # Insert indent depending on previous lastarg.
    case ${lastarg} in
      0) printf "   ${fb}${background}${box4}${t0}\r" ;;
      1) unset indent ;;
      2) ;;
      *) printf "   ${fb}${background}${box4}${t0}\r" ;;
    esac
    case "${3}" in
      0) printf "${indent}${fb} %s${t0}\n" "$2"
         lastarg=0 ;;
      1) printf "${indent}${fb} %s${t0}" "$2"
         lastarg=1 ;;
      2) printf "${indent}${fb} %s${t0}\r" "$2"
         lastarg=2 ;;
      *) printf "${indent}${fb} %s${t0}\n" "$2"
         lastarg=0 ;;
    esac
  fi
}

## END
