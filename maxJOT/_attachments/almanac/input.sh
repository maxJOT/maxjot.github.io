#!/usr/bin/env bash
#============================================================================
# Filename: input.sh
# Author:   maxJOT
# Purpose:  Initialize get_reply functions - demo.
# Platform: macOS/Linux running Bash > 4.
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

function get_reply {
  # Arguments:
  #   $1=prompt.
  #   $2=valid options (optional).
  # Examples:  
  #   get_reply "Press menu option:" "E 1 2 3 4"
  #   get_reply "Press any key to continue..."
  #   get_reply "Hit (y)es or (n)o, or (a)bort:" "Y N A"
  #
  # Note: $2 is optional. When specified, the first item
  # is automatically shown as the default answer. e.g. [E].
  # Any leading indentation in $1 automatically aligns the feedback.
  #
  # `read -t 0.1' causes an invalid timeout specification error
  # if not Bash 4 or later. Use 1 under Bash 3, which will still work
  # to flush the keyboard buffer, but cause a > 1 second delay.
  #
  local tries=0 option prompt answer indent
  local sav=$(stty -g </dev/tty)
  local hc=$(tput civis) rc=$(tput cnorm) u1=$(tput cuu1) ed=$(tput ed)
  local b1=$(tput bold; tput setaf 1) t0=$(tput sgr0)
  #
  if [[ ! ${BASH_VERSINFO:-0} -ge 4 ]]; then
    printf "\n${b1} \`get_reply' requires Bash 4 or later.${t0}\n"
    timeout=1
  fi
  # Restore cursor and cleanup prior to exiting the menu.
  opt_cleanup() { 
    stty ${sav} </dev/tty; printf ${rc}; unset -f opt_msg opt_cleanup; }
  # Hide cursor, disable terminal echo, and show error message.
  opt_msg() { 
    stty -echo </dev/tty; echo -e "${hc}\n${b1}$1${t0}"; sleep 1; }
  # Provide a dummy prompt when $1 is missing. Use any leading white
  # space when specified as indent, and align messages accordingly.
  if [[ -z $1 ]]; then
    prompt="?:"
  else
    indent=${1%%[!$' \t']*}
    prompt="$1"
  fi
  # Convert $2 to uppercase and make it an array for easier processing.
  # Adjust the prompt accordingly, using the first specified character
  # as default. Otherwise leave $1 as is (any key to continue).
  if [[ -n $2 ]]; then
    options=( $(printf '%s' "$2" | tr '[:lower:]' '[:upper:]') )
    default=${options[0]}
    prompt="$1 [${default}]"
  fi
  #
  while true; do    
    # Flush the keyboard buffer.
    stty -icanon -echo </dev/tty
    read -r -t ${timeout:-0.1} -s --
    # Disable ctrl/s/q/c/d and set stdin to interactive mode.
    stty icanon echo -ixoff intr '?' eof '?' </dev/tty
    echo -en "${rc}${prompt}${ed}"
    read -r -e -n 1 -p " " answer
    answer=$(printf '%s' "${answer}" | tr '[:lower:]' '[:upper:]')
    # No valid options = any key to continue.
    [[ -z ${2} ]] && { opt_cleanup; REPLY=${answer}; return 0; }
    # Apply default if the input is a Return.
    [[ -z ${answer} ]] && answer="${default}" # Default.
    for item in "${options[@]}"; do
      [[ "${answer}" == ${item} ]] \
         && { opt_cleanup; REPLY=${answer}; return 0; }
    done
    if (( tries++ == 2 )); then
      opt_msg "${indent}Aborting after 3 invalid answers."
      printf "\r${u1}${u1}${ed}"
      opt_cleanup
      return 3
    else
      opt_msg "${indent}Invalid input - please try again."
      printf "${u1}${u1}${u1}"
    fi
    stty ${sav} </dev/tty
  done
}

## END
