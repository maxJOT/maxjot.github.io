#!/usr/bin/env bash
#============================================================================
# Filename: dmgcrack.sh
# Author:   maxJOT
# Purpose:  Determine the password of macOS encrypted disk images or
#           sparsebundles using passwords listed in pwdlist.txt. Invalid
#           passwords are written to pwdlist.txt.invalid. When a valid
#           password is found, it is displayed on screen. If pwlist.txt
#           does not exist, a sample file is created automatically.
# Platform: macOS
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# URL:      https://maxjot.github.io/maxJOT/downloads/dmgcrack.html
# History:  10-May-2026, initial release
#           25-May-2026, version 1.1
#           - introducing function msg addressing error and notifications.
#           - eliminating race condition ejecting a disk image and CTRL/C.
#============================================================================

IAM=( "${BASH_SOURCE[0]##*/}" 1.1 )

function msg {
  #
  # Provide standard messaging for errors and information.
  # (https://maxjot.github.io/maxJOT/bash/bash-almanac.html)
  # $1 = Severity E X W I
  # $2 = Function or facility (optional)
  # $3 = Text (optional)
  local iam opt cln fac= str=
  cln="${BASH_LINENO[0]}" # Caller line number.
  [[ -n $2 ]] && fac=", $2"
  [[ -n $3 ]] && str=", $3"
  opt="${fac}${str}"
  iam="${IAM%.sh}"
  case "$1" in
    E) printf "%%%s-E-%s%s\n\a" "${iam}" ${cln} "${opt}" >&2 ;;
    W) printf "%%%s-W-%s%s\n" "${iam}" ${cln} "${opt}" >&2 ;;
    I) printf "%%%s-I-%s%s\n" "${iam}" ${cln} "${opt}" ;;
    *) printf "%s\n" "$@" ;;
  esac
}

function term_init_macos {
  #
  # Assign useful escape and control sequences for a  256-color terminal
  # emulation, if available. There is, however, no ill-effect if the terminal
  # does not - in which case variables will be empty and produce no output.
  # Requires Bash >= 3.
  #
  # Usage:
  #   term_init_macos         : Create variables.
  #   term_init_macos demo    : Demonstrate (verify).
  #   term_init_macos cleanup : Remove variables if source exectued.
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
      echo -e "\nColor table for xterm-256color terminal emulation:\n"
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
      echo; echo 'Usage, e.g.: echo "${B1}Red text${T0}"'; echo
    ;;
    cleanup)
      # Remove variables defined by term_init. This is useful to clean up
      # the shell (ENV) if term_init was source executed.
      # script has been source executed.
      local -a all=( "${tput_fg[@]}" "${tput_bfg[@]}" "${tput_bg[@]}"
                     "${tput_misc[@]}" )
      for i in "${all[@]}"; do unset "${i%:*}"; done
      if [[ -n ${TERM_INIT_OLD_TERM} ]]; then
        export TERM="${TERM_INIT_OLD_TERM}"
        unset TERM_INIT_OLD_TERM
      fi
      unset -f term_init_macos
    ;;
    *)
      # Define variables for terminal emulators (SSH, xterm-256color).
      for i in "${tput_fg[@]}" "${tput_bg[@]}" "${tput_misc[@]}"; do
        printf -v "${i%:*}" '%s' "$(tput ${i#*:} 2>/dev/null)"
      done
      # Bright colors, add bold. Bold orange (BD+C3) = bright yellow.
      for i in "${tput_bfg[@]}"; do
        printf -v "${i%:*}" '%s' "${BD}$(tput ${i#*:} 2>/dev/null)"
      done
      # Any SSH client/terminal worth mentioning supports xterm-256color.
      # Some installations may not be configured properly. Nevertheless,
      # restore the original TERM value when running term_init cleanup.
      TERM_INIT_OLD_TERM="${TERM}"
      export TERM=xterm-256color
      C3=$(tput setaf 214)  # Orange
      R3=$(tput setab 214)  # Orange background
      C4=$(tput setaf 25)   # Blue
    ;;
  esac
}

term_init_macos
#term_init_macos demo

# Exit if this script has been source-executed.
#
( return 0 > /dev/null 2>&1 )
if [[ $? -eq 0 ]]; then
  echo
  \msg E "${B1}source-execution unsupported${T0}"
  term_init_macos cleanup
  unset -f msg 
  unset IAM
  echo
  return 1
fi

function checksum {
  # The following aims to protect from installation or download corruption.
  # It is not meant to protect from tampering.
  # Use the name of the script as argument to recalculate checksum.
  #
  local sed count
  case $( uname -s ) in
    Darwin) md5sum=md5; sed_cmd=( sed -i '' ) ;;
    Linux)  md5sum=md5sum; sed_cmd=( sed -i ) ;;
  esac
  count=$(wc -l < "${BASH_SOURCE[0]}")
  count=$(( count - 1 )) # Ignore the last line for cacluating md5.
  crc=( $( head -n ${count} ${BASH_SOURCE[0]} | ${md5sum} |cut -c1-12) )
  num=( $( tail -1 ${BASH_SOURCE[0]} | grep "^#" ) )
  if [[ $1 == ${IAM} ]]; then
    "${sed_cmd[@]}" "s/${num[2]}/${crc[0]}/g" "${BASH_SOURCE[0]}"
    echo
    msg W checksum "signature replaced"
    echo; exit 0
  elif [[ ${crc[0]} != "${num[2]}" ]]; then
    echo
    msg E checksum "${B1}self-integrity check failed${T0}"
    msg I "please download and install a new copy"
    msg I "run \`./${IAM} ${IAM}' to bless this version"
    echo; exit 1
  fi
}

checksum "$1"

function box {
  # Arguments: $1 = Color scheme $2 = Text 
  #            $3 = Format (optional):
  #                 0 = standard newline (default).
  #                 1 = do not move the cursor.
  #                 2 = move the cursor to the beginning of the line (\r).
  #
  local maxlen background indent fb t0
  local box_top box_bottom box1 box2 box3 box4 box5 box6 box7 box8
  t0=$( tput sgr0 )
  maxlen=65 box1=$'\u250C' box2=$'\u2500' box3=$'\u2510' box4=$'\u2502'
  box5=$'\u2514' box6=$'\u2518' box7=$'\u251C' box8=$'\u2524'
  # Generate horizontal line.
  box2=$( eval printf "${box2}%.0s" {1..${maxlen}} )
  # Generate top middle and bottom box-lines.
  box_top=$( printf "${box1}${box2}${box3}" )
  box_middle=$( printf "${box7}${box2}${box8}" )
  box_bottom=$( printf "${box5}${box2}${box6}" )
  # white space with background.
  background=$( eval printf -- '\ %.0s' {1..${maxlen}} )
  # Set forground and background color.
  case $1 in
    2) fb=$( tput setaf 11; tput setab 2 ) ;; # bright yellow on green
    3) fb=$( tput setaf 214; tput setab 0 ) ;; # orange on black
    4) fb=$( tput setaf 7; tput setab 4 ) ;; # white on blue
    0) fb=$( tput setaf 7; tput setab 0 ) ;; # white on black
    r) fb=$( tput rev ) ;; # Reverse
    *) fb= ;;      # No color
  esac
  indent="  ${fb}${box4}${t0}"
  if [[ "$2" == box_top ]]; then
    printf "  ${fb}${box_top}${t0}\n"
  elif [[ "$2" == box_bottom ]]; then
    printf "  ${fb}${box_bottom}${t0}\n"
  elif [[ "$2" == box_middle ]]; then
    printf "  ${fb}${box_middle}${t0}\n"
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

function help {
  echo "Usage:
  ${IAM} [OPTIONS] target"
  echo
  echo "Arguments:
  target                  macOS disk image or sparsebundle."
  echo 
  echo "Options:
  -p, --password FILE     Use a custom password list file.
                          Default: pwdlist.txt
  -h, --help              Show help.
  -v, --version           Show version."
  echo
  echo "Description:
  Determine the password of a macOS encrypted disk image or sparsebundle
  by testing passwords from a list. If no password list is provided and
  pwdlist.txt does not exist, a sample list will be created automatically.

  Each failed password is written to pwdlist.txt.invalid. When a valid
  password is found, it is displayed on screen and the process stops."
  echo
  echo "Examples:
  ${IAM} diskimage.dmg
  ${IAM} -p mypasswords.txt diskimage.sparsbundle"
  echo
}

function version {
  echo "Version ${IAM[1]}"
  echo
  echo "Copyright (c) 2026 maxJOT. All Rights Reserved."
  echo "Free to use but not for sale. No redistribution of modified"
  echo "copies. https://maxjot.github.io/maxJOT/license_maxjot.html"
  echo
}

# Abort if the system is not macOS. hdiutil is macOS only.
#
if [[ $( uname -s ) != Darwin ]]; then
  echo
  msg E "${B1}incompatible Operating System${T0}"
  msg I "hdiutil requires macOS"
  echo; exit 1
fi

function shortvar {
  # Shorten $1 so it does not exceed $2 length.
  # $1=string (required) $2=max length, default 40
  # Returns: shortvar_0 (global)
  #
  local str="$1" max_length=${2:-40}
  if (( ${#str} <= max_length )); then
    shortvar_0="${str}"
  else
    local half=$(( (max_length - 3) / 2 ))
    shortvar_0="${str:0:half}...${str: -half}"
  fi
}

function gen_pwdlist {
  # Create a sample password list $PWDLIST.
  {
    printf "%s\n" "Note: One password per line, terminated by a Return."
    printf "%s\n" "Passwords are used exactly as entered,"
    printf "%s\n" "including whitespace and special characters."
    printf "%s\n" "Do not add shell-style quotes or escaping."
    printf "%s\n" "password" "!my_password\$" "'mypassword'"
    printf "%s\n" ">mypassword<" "\\mypassword\\" "#my!password#"
    printf "%s\n" "my\"password\"" " my password "
  } > "${PWDLIST}"
  if [[ ! -s ${PWDLIST} ]]; then
    echo
    msg E gen_pwdlist "${B1}error creating password list${T0}"
    msg I "file: ${PWDLIST}"
    msg I "try \`${IAM} --help' for more information"
    echo; exit 1
  else
    echo
    msg I "password list file required"
    msg I "${B3}new default sample file created${T0}"
    echo
  fi
}

function hdiutil_cmd {
  # hdiutil provides only limited exit codes that are useful
  # to determine successful program execution. Hence we need
  # to parse the hdiutil output.
  local args="-nomount -noverify -noautofsck"
  local dmg_spec hdiname
  case $1 in
    1) trap 'last_command_0=${BASH_COMMAND}' ERR
       result_0=$( LC_ALL=C hdiutil isencrypted "${DMG}" 2>&1 )
       status_0=$?
       trap cleanup SIGINT       
       ;;
    2) result_0=$( printf "%s" "$2" | \
         LC_ALL=C hdiutil attach -stdinpass ${args} "${DMG}" 2>&1 )
       ;;
    3) # Get and normalize the absolute path to the disk image.
       dmg_spec=$(cd "$(dirname -- "$DMG")" && pwd -P)/$(basename -- "$DMG")
       result_0=$( LC_ALL=C hdiutil info | \
         awk -F': ' '/^image-path/ {print $2}' | \
         while IFS= read -r hdiname; do
           [[ "${hdiname}" == "${dmg_spec}" ]] && echo attached
         done )
       ;;
  esac
} 

function sec_notice {
  echo
  box r box_top
  box r "PLEASE NOTE"
  box r
  box r "The following file(s) may contain confidential password"
  box r "data and reveal password patterns or candidate choices."
  box r
  shortvar "${PWDLIST}" 46
  box r "  ${shortvar_0}"
  # Verify ${PWDINV} exists and is not empty.
  if [[ -s ${PWDINV} ]]; then
    shortvar "${PWDINV}" 46
    box r "  ${shortvar_0}"
  fi
  box r
  box r "Deleting these file(s) is highly recommended."
  box r box_bottom
}

function sort_invalid {
  # Verify ${PWDINV} exists and is not empty.
  if [[ -s ${PWDINV} ]]; then
    LC_ALL=C sort -u -o "${PWDINV}" "${PWDINV}"
  fi
}

function eject {
  # Eject an attached disk image.
  # Requires $dev_name_0 provided by function crackpwd.
  LC_ALL=C hdiutil eject -force -quiet "${dev_name_0}"
}

function crackpwd {
  # Walk through $PWDLIST.
  # Requires $result_0 provided by hdiutil_cmd function.
  echo; echo; echo; echo
  echo "${U1}   ${BD}Press Ctrl-C to abort.${T0}${U1}${U1}${U1}"
  while IFS= read -r pwd || [[ -n "${pwd}" ]]; do
    printf '   testing (%s/%s): %-54s\r' ${rem_0} ${num} "${pwd:-<empty>}"
    hdiutil_cmd 2 "${pwd}"
    dev_name_0=$(awk '/^\/dev\// {print $1; exit}' <<< "${result_0}")
    if [[ -n ${dev_name_0} ]]; then
      # Remove the successfully attached disk image.
      eject
      echo "${ED}   Invalid password attempts: $(( ${rem_0} -1 ))"
      echo "   ${B2}Valid password found at line ${rem_0}${T0}"
      # Display the working password with a visual ruler to reveal
      # whitespace. Generate a 60-character ruler and truncate it to the
      # length of the password. Tabs are unsupported by the Apple Disk
      # Utility UI and therefore do not need to be considered.
      ruler=12345678901234567890
      printf -v header ${ruler} ${ruler} ${ruler}
      len=${#pwd}          
      header="${header:0:len}" # Truncate to password length
      echo
      echo "   ${RV}${header}${T0}"
      echo "   ${pwd}"
      sort_invalid
      sec_notice
      echo
      exit 0 # Exit on valid password found.
    elif grep -qi "Authentication error" <<< "${result_0}"; then
      # Write wrong passwords to $PWDINV.
      echo "${pwd}" >> "${PWDINV}"
    else
      # Report unexpected hdiutil output.
      echo "${result_0}"
      echo
      echo; exit 1
    fi
    rem_0=$(( rem_0 + 1 )) 
  done < "${PWDLIST}"
  echo "${ED}   Invalid password attempts: $(( ${rem_0} -1 ))"
  echo "   See \`${PWDINV}' (sorted)."
  sort_invalid
  sec_notice
  echo
}

# MAIN #

# First rule out single-dash long options. 
# Word matching is the trick here.
# 
for i in "$@"; do
  if grep -iqwE -- 'ersion|elp' <<< ${i:2}; then
    echo
    msg E args "${B1}invalid command line argument${T0}"
    msg I "invalid long option detected: ${i}"
    msg I "try \`${IAM} --help' for more information"
    echo; exit 1
  fi
done
 
# Create a copy of current arguments and purge valid
# standalone arguments from the array.
#
declare -a args=("$@")
help=0 version=0
#
for i in "${!args[@]}"; do
  case "${args[i]}" in
    -h|--help) help=1; args[i]= ;;
    -v|--version) version=1; args[i]= ;;
    -[hv]*)
      # Process any combination of arguments.
      # Invalid combinations will be addressed later.
      bundle="${args[i]#-}"
      nomatch=
      for (( j=0; j<${#bundle}; j++ )); do
        char="${bundle:j:1}"
        case "${char}" in
          h) help=1 ;;
          v) version=1 ;;
          *) nomatch+="${char}" ;;
        esac
      done
      # Reject non-matching chars.
      [[ -n ${nomatch} ]] && args[i]="-${nomatch}" || args[i]=
    ;;
  esac
done

# Process arguments that require another parameter.
#
password=0 PWDLIST=
#
for i in "${!args[@]}"; do  
  if [[ ${password} = 1 ]]; then
    case "${args[i]}" in
      -*) echo
          msg E args "${B1}invalid filename${T0}"
          msg I "file: ${args[i]}"
          msg I "try \`${IAM} --help' for more information"
          echo; exit 1 ;;
       *) PWDLIST="${args[i]}"; args[i]=; break ;;
    esac
  else    
    case "${args[i]}" in
      -p|--password) # Must not be the last argument.
        if (( i + 1 < ${#args[@]} )); then
          password=1; args[i]=
        else
          echo
          msg E args "${B0}password file not specified${T0}"
          msg I "try \`${IAM} --help' for more information"
          echo; exit 1
        fi ;;
    esac
  fi
done

# Process arguments that are not options.
# Skip over emptied array slots and options.
#
target=0
for i in "${!args[@]}"; do
  case "${args[i]}" in
    "") continue ;;
    -*) continue ;;
    *) target=1; DMG="${args[i]}"; args[i]=; break ;;
  esac  
done
 
# After all valid arguments have been removed from our args[] copy,
# consolidate the remaining command line argument(s) and replace the
# original command line.
#
declare -a consolidate=()
for item in "${args[@]}"; do
    [[ -n "${item}" ]] && consolidate+=( "${item}" )
done
set -- "${consolidate[@]}"
 
# Check if there are any remaining command line arguments
# and determine if they are valid or invalid.
#
for item in "$@"; do
  [[ -z ${item} ]] && continue
  echo
  msg E args "invalid option(s)"
  msg I "option(s): $*"
  msg I "try \`${IAM} --help' for more information"
  echo; exit 1
done
 
# At this point all possible options are set to 1 or 0.
# Some are mutually exclusive and cannot be combined.
#
(( help + version > 1 )) && combine=invalid
(( help + version + target > 1 )) && combine=invalid
(( help + version + password > 1 )) && combine=invalid

if [[ ${combine} == invalid ]]; then
  echo
  msg E args "${B1}invalid combination of command line arguments${T0}"
  msg I "try \`${IAM} --help' for more information"
  echo; exit 1
fi
 
# Finished checking integrity of command line arguments.
# Continue processing the result.
#
(( help )) && { help; exit; }
(( version )) && { version; exit; }

# Verify specified $PWDLIST exists and is not empty. 
# Use pwdlist.txt as default. 
#
if (( password )); then
  if [[ ! -s ${PWDLIST} ]]; then
    echo
    msg E args "${B1}no such password list or empty file${T0}"
    msg I "file: ${PWDLIST}"
    msg I "try \`${IAM} --help' for more information"
    echo; exit 1
  fi 
else
  PWDLIST=pwdlist.txt
fi

# Define $PWDINV filename.
PWDINV="${PWDLIST}.invalid"

# Verify parameter $1 (disk image/sparsebundle) exists.
#
if [[ -z ${DMG} ]]; then
  echo
  msg E args "${B1}no target specified${T0}"
  msg I "please specify the disk image or sparsebundle"
  msg I "try \`${IAM} --help' for more information"
  echo; exit 1
elif [[ ! -d "${DMG}" && ! -f "${DMG}" ]]; then
  echo
  msg E args "${B1}disk image not found${T0}"
  msg I "target: ${B3}${DMG}${T0}"
  echo; exit 1
fi

# Sanity checks.
#
if [[ ${PWDLIST} == ${DMG} ]]; then
  echo
  msg E args "password list and target cannot be the same"
  msg I "file: ${PWDLIST}"
  msg I "target: ${B3}${DMG}${T0}"
  echo; exit 1
fi

function cleanup {
  # Avoid a possible race condition that can occur while
  # processing the crackpwd function, attaching the disk
  # image and hitting CTRL/C.
  dev_name_0=$(awk '/^\/dev\// {print $1; exit}' <<< "${result_0}")
  echo; echo; echo; echo
  [[ -n ${dev_name_0} ]] && eject
  msg I aborted
  echo; exit 1
}

trap cleanup SIGINT

# Check if the disk image has already been attached/mounted and exit.
#
hdiutil_cmd 3
if [[ "${result_0}" == attached ]]; then
  echo
  msg E "hdiutil" "${B1}disk image already attached or mounted${T0}"
  msg I "please use Apple Disk Utility for more information"
  msg I "target: ${B3}${DMG}${T0}"
  echo; exit 0
fi

# Proceed depending on whether or not the disk image is encrypted.
#
hdiutil_cmd 1
if [[ ${status_0} -ne 0 ]]; then
  echo
  echo "${last_command_0}"
  echo "${result_0}"
  msg E hdiutil "${B1}unexpected error${T0}"     
  echo; exit 1
else
  # $result shows YES/NO reported by the hdiutil ($result_0)
  result=$( awk -F': ' '/^encrypted:/ {print $2}' <<< "${result_0}" )
fi
#
case "${result}" in
  YES) # If $PWDLIST was specified on the command line, file existence
       # has already been verified while processing command line arguments.
       # If $PWDLIST refers to the default pwdlist.txt filename, generate a
       # sample password file if it does not exist, but only when the
       # specified disk image is encrypted. In all cases, verify $PWDLIST
       # appears to contain text data (ASCII or Unicode), not binary data.
       [[ ! -s ${PWDLIST} ]] && gen_pwdlist
       if ! file "${PWDLIST}" | grep -qi 'text'; then
         echo
         msg E "password list must be a text file"
         msg I "file: ${PWDLIST}"
         echo; exit 1
       fi
       # Standard header/summary.
       num=$( awk 'END {print NR}' "${PWDLIST}" )
       rem_0=1 # global variable (password progress counter).
       echo
       box 4 box_top
       shortvar "${DMG}" 46
       box 4 "Disk image:     ${B3}${shortvar_0}"
       shortvar "${PWDLIST}" 46
       box 4 "Password list:  ${BD}${shortvar_0}"
       box 4 "Passwords:      ${BD}${num}"
       box 4 box_bottom
       # Walk through $PWDLIST.
       crackpwd
       ;;
  NO) echo
      msg E hdiutil "${B1}disk image does not appear password protected${T0}"
      msg I "please use Apple Disk Utility for more information"
      msg I "target: ${B3}${DMG}${T0}"
      echo; exit 0
     ;;
  *) echo
     msg E hdiutil "${B1}cannot determine encryption${T0}" 
     msg I "please use Apple Disk Utility for more information"
     msg I "target: ${B3}${DMG}${T0}"
     echo; exit 1
     ;;
esac

## END bf17cf0964e7
