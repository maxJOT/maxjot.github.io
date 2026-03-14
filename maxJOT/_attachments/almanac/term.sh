#!/usr/bin/env bash
#============================================================================
# Filename: term.sh
# Author:   maxJOT
# Purpose:  Demo using term_init function.
# Platform: macOS/Linux running Bash.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

function term_init {
  #
  # Assign useful terminal sequences that are compatible with any
  # 256-color VGA terminal, if available. There is, however, no
  # ill-effect if the terminal does not - in which case variables 
  # will simply be empty and produce no output. Requires Bash >= 3.
  #
  # Usage:
  #   term_init         : Create variables.
  #   term_init demo    : Demonstrate (verify).
  #   term_init cleanup : Remove variables if source exectued.
  #
  # Define arrays of variable names and appropriate tput arguments.
  local -a tput_fg=( 'C0:setaf 0' 'C1:setaf 1' 'C2:setaf 2' 'C3:setaf 3' 
                     'C4:setaf 4' 'C5:setaf 5' 'C6:setaf 6' 'C7:setaf 7' )
  local -a tput_bfg=( 'B0:setaf 0' 'B1:setaf 1' 'B2:setaf 2' 'B3:setaf 3'
                      'B4:setaf 4' 'B5:setaf 5' 'B6:setaf 6' 'B7:setaf 7' )
  local -a tput_bg=( 'R0:setab 0' 'R1:setab 1' 'R2:setab 2' 'R3:setab 3'
                     'R4:setab 4' 'R5:setab 5' 'R6:setab 6' 'R7:setab 7' )
  local -a tput_misc=( 'BD:bold' 'RG:bel' 'BL:blink' 'T0:sgr0' 'U1:cuu1'
                       'RV:rev' 'ED:ed' 'EL:el' 'HC:civis' 'RC:cnorm' )
  local i i1 i2
  #
  case "$1" in
    demo)
      echo -e "\nConsole and terminal compatible colors:\n"
      for i in "${tput_fg[@]}" "${tput_bfg[@]}" BD "${tput_bg[@]}" RV; do
        i1="${i%:*}" 
        echo -n "${!i1}$i1${T0} "
        case $i1 in C7|BD|RV) printf "\n";; esac
      done
      for i1 in "${tput_fg[@]}"; do
        i1="${i1%:*}" 
        for i2 in "${tput_bg[@]}"; do
          i1="${i1%:*}" i2="${i2%:*}"
          [[ ${i1#C} == ${i2#R} ]] && continue
          case $i1$i2 in C6R2|C2R6|C5R1|C1R5|C7R3|C0R4) continue;; esac
          echo -n "${!i1}${!i2}$i1$i2${T0} "
        done; echo
      done
      for i1 in "${tput_bfg[@]}"; do
        for i2 in "${tput_bg[@]}"; do
          i1="${i1%:*}" i2="${i2%:*}"
          case $i1$i2 in B3RV|B4R4) continue;; esac
          echo -n "${!i1}${!i2}$i1$i2${T0} "
        done; echo
      done
    ;;
    cleanup)
      # Remove variables defined by term_init. This is useful to clean up
      # the shell (ENV) if term_init was source executed.
      # script has been source executed.
      local -a all=( "${tput_fg[@]}" "${tput_bfg[@]}" "${tput_bg[@]}"
                     "${tput_misc[@]}" )
      for i in "${all[@]}"; do unset "${i%:*}"; done
      # Restore default Linux 16-color terminal palette and $TERM.
      if [[ "${TERM}" == linux ]]; then
        setvtrgb vga
      elif [[ -n ${TERM_INIT_OLD_TERM} ]]; then
        export TERM="${TERM_INIT_OLD_TERM}"
        unset TERM_INIT_OLD_TERM
      fi
      unset -f term_init
    ;;
    *)
      # Define variables that produce the same or similar color output
      # under Linux VGA-style 16-color (console, TERM=linux) and terminal
      # emulators (SSH, xterm-256color).
      for i in "${tput_fg[@]}" "${tput_bg[@]}" "${tput_misc[@]}"; do
        printf -v "${i%:*}" '%s' "$(tput ${i#*:} 2>/dev/null)"
      done
      # Bright colors, add bold.
      for i in "${tput_bfg[@]}"; do
        printf -v "${i%:*}" '%s' "${BD}$(tput ${i#*:} 2>/dev/null)"
      done
      # Alter the Linux console color map to replace dark yellow with a
      # more visible orange, thereby providing an additional color and
      # improving compatiblity with modern terminal emulation.
      # Note that bold orange (BD+C3) becomes bright yellow.
      if [[ "${TERM}" == linux ]]; then
        # Match Linux console and xterm-256 colors.
        echo "0,170,0,255,0,170,0,192,85,255,85,255,85,255,85,255
              0,0,170,199,0,0,170,192,85,85,255,255,85,85,255,255
              0,0,0,6,176,170,170,192,85,85,85,85,255,255,255,255" \
              | setvtrgb -
      else
        # Any SSH client/terminal worth mentioning supports xterm-256color.
        # Some installations may not be configured properly. Nevertheless,
        # restore the original TERM value when running term_init cleanup.
        # Override default orange and blue to match Linux console colors.
        TERM_INIT_OLD_TERM="${TERM}"
        export TERM=xterm-256color
        C3=$(tput setaf 214)  # Orange
        R3=$(tput setab 214)  # Orange background
        C4=$(tput setaf 25)   # Blue
      fi
    ;;
  esac
}

## END 
