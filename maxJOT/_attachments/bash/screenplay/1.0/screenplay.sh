#!/usr/bin/env bash
#============================================================================
# Filename: screenplay.sh
# Author:   maxJOT
# Purpose:  Run shell commands from a text file (.run) as if they
#           were directly typed at the command prompt. For example,
#           to automate the execution of commands to create a video
#           from the terminal window. It also enables you to display
#           any particular terminal command prompt.
# Platform: macOS/Linux running Bash
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# URL:      https://maxjot.github.io/maxJOT/downloads/screenplay.html
# Note:     lowercase_0 = global mutable variable
#           uppercase = static, global or exported variable
#           lowercase = local, temporary variable
# History:  Initial version 1.0 (06-JUN-2026)
#============================================================================

# Exit vs. return if source executed. Create a snapshot of
# variables and functions when source executed, so we can use
# this information later to restore the shell environment when
# executing the cleanup function.  
#
if ( return 0 2>/dev/null ); then
  SCREENPLAY_SOURCED=1
  SCREENPLAY_ENV_VARIABLES=$( compgen -v )
  SCREENPLAY_ENV_FUNCTIONS=$( compgen -A function )
else
  SCREENPLAY_SOURCED=0
fi

IAM=( ${BASH_SOURCE[0]##*/} 1.0 )
DEFAULT_RUNFILE="${IAM%.sh}.run"

# Define a fallback for the virutal command prompt based the current
# user ID. To set a custom command prompt, define "PROMPT" inside the
# runfile, e.g.: "PROMPT Saturn:almanac dude$"
if (( EUID == 0 )); then
  SCREENPLAY_DEFAULT_PROMPT='#'
else
  SCREENPLAY_DEFAULT_PROMPT='$'
fi

# Default PAUSE directive (seconds) to halt the processing of the runfile.
SCREENPLAY_DEFAULT_PAUSE=3

function SCREENPLAY_cleanup {
    # Avoid tainting the calling shell environment with variables
    # and functions created by this script when source executed.
    # Be sure not to remove variables before functions!
    #
    local item
    while IFS= read -r item; do
      unset -f ${item}
    done < <( awk 'FNR==NR{a[$0]++;next}!($0 in a)' - \
                <<< "${SCREENPLAY_ENV_FUNCTIONS}" <( compgen -A function ) )
    while IFS= read -r item; do
      unset ${item}
    done < <( awk 'FNR==NR{a[$0]++;next}!($0 in a)' - \
                <<< "${SCREENPLAY_ENV_VARIABLES}" <( compgen -v ) )
    unset SCREENPLAY_SOURCED
    unset -f SCREENPLAY_cleanup
}

function show_help {
  echo "Usage:
  source ${IAM} [-h | -v] runfile"
  echo
  echo "Arguments:
  -h, --help               show help
      --version            show version
      --install            install to /usr/local/bin
      --uninstall          remove from /usr/local/bin
  runfile                  text file listing command to execute"
  echo
  echo "Examples:
  source ${IAM} demo1.run"
  echo
  echo "Description:
  Automate the execution of commands read from a text file (.run)
  as if they were typed directly at the terminal commmand prompt.
  If no runfile is provided and shellscript.run does not exist,
  a sample shellscript.run will be created automatically."
  echo
}

function show_version {
  echo "Version ${IAM[1]}"
  echo
  echo "Copyright (c) 2024-2026 maxJOT. All Rights Reserved."
  echo "Free to use but not for sale. No redistribution of modified"
  echo "copies. https://maxjot.github.io/maxJOT/license_maxjot.html"
  echo
}

function run_install {
  local target="/usr/local/bin/${BASH_SOURCE[0]##*/}"
  echo
  if [[ -e "${target}" ]]; then
    msg W run_install "${B3}file already exists${T0}"
    msg I "file: ${target}"
    echo   
    if ! get_reply "${BD}Override (Y)es/(N)o:${T0}" "N Y"; then
         echo
         msg E run_install "invalid user response"
         echo
         status_0=1
         return
    fi
    [[ ${REPLY} == N ]] && { status_0=0; echo; return; }
  fi
  if \cp "${BASH_SOURCE[0]}" "${target}" && chmod 755 "${target}"; then
    echo
    msg I run_install "${B2}installation successful${T0}"
    msg I "file: ${target}" 
    echo
  else
    if [[ ! -w /usr/local/bin ]]; then
      echo
      msg E run_install "insufficient privileges"
      msg I "try \`sudo ${IAM} --install'"
      echo
      status_0=1
    else
      echo
      msg E run_install "error installing"
      msg I "file: ${target}"
      echo
      status_0=1
    fi
  fi
}

function run_uninstall {
  local target="/usr/local/bin/${BASH_SOURCE[0]##*/}"
  echo
  if [[ -e "${target}" ]]; then
    msg I "file: ${target}"
    echo
    if ! get_reply "${BD}Uninstall file (Y)es/(N)o:${T0}" "N Y"; then
         echo
         msg E run_uninstall "invalid user response"
         echo
         status_0=1
         return
    fi
    [[ ${REPLY} == N ]] && { status_0=0; echo; return; }
  fi
  if \rm "${target}"; then
    echo
    msg I run_uninstall "${B2}uninstall successful${T0}"
    msg I "file: ${target}" 
    echo
  else
    if [[ ! -w /usr/local/bin ]]; then
      echo
      msg E run_uninstall "insufficient privileges"
      msg I "try \`sudo ${IAM} --uninstall'"
      echo
      status_0=1
    else
      echo
      msg E run_uninstall "error uninstalling"
      msg I "file: ${target}"
      echo
      status_0=1
    fi
  fi
}

function term_init {
  # Assign useful terminal sequences compatible with 256-color VGA
  # terminals, if available. This is a stripped-down version of:
  # https://maxjot.github.io/maxJOT/ref/colors_and_styles.html
  #
  local -a tput_fg=( 'C0:setaf 0' 'C1:setaf 1' 'C2:setaf 2' 'C3:setaf 3'
                     'C4:setaf 4' 'C5:setaf 5' 'C6:setaf 6' 'C7:setaf 7' )
  local -a tput_bfg=( 'B0:setaf 0' 'B1:setaf 1' 'B2:setaf 2' 'B3:setaf 3'
                      'B4:setaf 4' 'B5:setaf 5' 'B6:setaf 6' 'B7:setaf 7' )
  local -a tput_misc=( 'BD:bold' 'RG:bel' 'BL:blink' 'T0:sgr0' 'U1:cuu1'
                       'RV:rev' 'ED:ed' 'EL:el' 'HC:civis' 'RC:cnorm' )
  local i i1 i2
  #
  for i in "${tput_fg[@]}" "${tput_misc[@]}"; do
    printf -v "${i%:*}" '%s' "$(tput ${i#*:} 2>/dev/null)"
  done
  # Bright colors, add bold.
  for i in "${tput_bfg[@]}"; do
    printf -v "${i%:*}" '%s' "${BD}$(tput ${i#*:} 2>/dev/null)"
  done
}

function mute {
  # Optional feature to suppress keyboard and cursor output
  # when it can interfere with proper box and content rendering.
  #
  # $1 on:  Hide cursor, disable terminal echo, disable CTRL/C/D/Z.
  #         Stop user/keyboard interference while rendering screen output.
  # $1 off: Restore previously saved terminal state.
  #
  local hc=$( tput civis ); local rc=$( tput cnorm )
  #
  case $1 in
   on) sav_0=$( stty -g </dev/tty )  # Save tty settings. Global scope.
       stty -echo -icanon susp '?' intr '?' eof '?' </dev/tty
       printf ${hc} ;;
   off) stty ${sav_0} </dev/tty
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
  # Note: lastarg_0 = global mutable.
  [[ -z ${lastarg_0} ]] && lastarg_0=0
  local maxlen background indent fb t0
  local box_top box_middle box_bottom box1 box2 box3 box4 box5 box6 box7 box8
  t0=$( tput sgr0 )
  maxlen=65
  box1='┌' box2='─' box3='┐' box4='│' box5='└' box6='┘' box7='├' box8='┤'
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
    lastarg_0=0
  elif [[ "$2" == --bottom ]]; then
    printf "  ${fb}${box_bottom}${t0}\n"
    lastarg_0=0
  elif [[ "$2" == --middle ]]; then
    printf "  ${fb}${box_middle}${t0}\n"
    lastarg_0=0
  else
    # Insert indent depending on previous lastarg.
    case ${lastarg_0} in
      0) printf "   ${fb}${background}${box4}${t0}\r" ;;
      1) unset indent ;;
      2) ;;
      *) printf "   ${fb}${background}${box4}${t0}\r" ;;
    esac
    case "${3}" in
      0) printf "${indent}${fb} %s${t0}\n" "$2"
         lastarg_0=0 ;;
      1) printf "${indent}${fb} %s${t0}" "$2"
         lastarg_0=1 ;;
      2) printf "${indent}${fb} %s${t0}\r" "$2"
         lastarg_0=2 ;;
      *) printf "${indent}${fb} %s${t0}\n" "$2"
         lastarg_0=0 ;;
    esac
  fi
}

function msg {
  # Arguments: $1 = Severity E W I
  #            $2 = Function or facility (optional)
  #            $3 = Text (optional)
  # URL: https://maxjot.github.io/maxJOT/ref/coherent_messaging.html
  # 
  local b1 t0 iam opt cln fac= str=
  b1=$( tput bold; tput setaf 1)
  t0=$( tput sgr0 )
  cln="${BASH_LINENO[0]}" # Caller line number.
  iam="${BASH_SOURCE[0]##*/}"
  iam="${iam%.sh}"
  [[ -n $2 ]] && fac=", $2"
  [[ -n $3 ]] && str=", $3"
  [[ $1 == E ]] && str=", ${b1}$3${t0}"
  opt="${fac}${str}"
  case "$1" in
    E) printf "%%%s-E-%s%s\n\a" "${iam}" ${cln} "${opt}" >&2 ;;
    W) printf "%%%s-W-%s%s\n" "${iam}" ${cln} "${opt}" >&2 ;;
    I) printf "%%%s-I-%s%s\n" "${iam}" ${cln} "${opt}" ;;
    *) printf "%s\n" "$@" ;;
  esac
}

function any_key {
  # Intercept CTRL-C
  trap "echo; abort=1; return" INT
  function _read { read -r -e -n 1; }
  local timeout sav prompt abort=0
  local bd=$(tput bold) t0=$(tput sgr0)
  [[ ${BASH_VERSINFO:-0} -ge 4 ]] && timeout=0.1 || timeout=1
  sav=$( stty -g </dev/tty )  # Save tty settings.
  # Flush the keyboard buffer.
  stty -icanon -echo </dev/tty
  read -r -t ${timeout} -s --
  stty icanon echo </dev/tty
  # Disable CTRL-D and CTRL-Z (requires read -e).
  stty eof '?' susp '?' </dev/tty
  prompt="Press any key to continue, or CTRL-C to abort."
  printf "    %s\r" "${bd}${prompt}${t0}"
  # Run read -e in a subshell so the Readline context is discarded
  # on abort, making the procedure compatible with source execution.
  $( _read )
  stty ${sav} </dev/tty # Restore tty settings.
  trap - INT  # Clear ctrl-c traps.
  unset -f _read
  (( abort )) && return 1 || return 0
}

function gen_runfile {
  # Create a sample shellscript.run file.
  local lines=(
    '#----------------------------------------------------------------------'
    "# Filename: ${IAM%.sh}.run"
    '# Purpose:  Default runfile used by ${IAM}'
    '#           This sample file has been auto-generated.'
    '# URL:      https://maxjot.github.io/maxJOT/downloads/screenplay.html'
    '#----------------------------------------------------------------------'
    '# empty line     Prints the command prompt (simulates Return).'
    "#                Lines beginning with '#' are ignored (comments)."
    '# PAUSE          Pause for N seconds (default: 3).'
    "# EXEC           Execute a script within ${IAM%.sh}'s context:"
    "#                source ${IAM} -> source script.sh, e.g.:"
    '#                EXEC script.sh'
    '# PROMPT         Set the virtual command prompt, e.g.:'
    '#                PROMPT Saturn:~ dude$'
    '#----------------------------------------------------------------------'
    'PROMPT Saturn:~ dude$'
    ''
    "echo \"Hello ${IAM%.sh}!\""
    'echo "Pause for 3 seconds"'
    'PAUSE'
    "EXEC args_example.sh -dtv ${IAM}"
    ''
    'echo "press Return to exit the demo."'
  )
  printf '%s\n' "${lines[@]}"  > "${DEFAULT_RUNFILE}"   
  if [[ ! -s ${DEFAULT_RUNFILE} ]]; then
    echo
    msg E gen_runfile "error creating runfile sample"
    msg I "file: ${DEFAULT_RUNFILE}"
    msg I "try \`${IAM} --help' for more information"
    echo
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
  else
    echo
    msg I "runfile required"
    msg I "new default sample runfile created"
    msg I "file: ${DEFAULT_RUNFILE}"
    echo
  fi
}

function phase_init {
  # Requires $LOPTS[] = list of long options, e.g.: help version.
  # Create a copy of the command-line arguments (args_0[]) for later
  # phases to work with (process/consume) and initialize all long option
  # arguments (--option) e.g.: help_0=0 version_0=0.
  #
  args_0=("$@")
  #
  # Save the original number of command-line arguments.
  # Later phases may use this value for boundary checks after
  # consumed arguments have been removed from args_0[].
  #
  LAST_INDEX=$#
  local var option
  for option in "${LOPTS[@]}"; do
    var="${option}_0"
    printf -v "${var}" '%d' 0
  done
}

function payload_init {
  # $1 = List of payload variables, e.g.: payload_init "type directory"
  # Create local payload variables (type_0= directory_0= ), but do not
  # override existing variables.
  #
  local option var
  for option in $1; do
    var="${option}_0"
    [[ -z ${!var} ]] && printf -v "${option}_0" '%s' ''
  done
}

function validate_option_sets() {
  # Validate that all options from LOPTS set to 1 belong to the same
  # option set defined in option_sets_0. Any selected option outside
  # that option set is considered an invalid combination.
  #
  local allowed applicable invalid=
  local option var
  
  for allowed in "${option_sets_0[@]}"; do
    applicable=0
    invalid=
    # Determine whether any option in this option set is set to 1.
    # If all variables are 0, then there is nothing to validate.
    #
    for option in ${allowed}; do
      var="${option}_0"
      (( ${!var} )) && { applicable=1; break; }
    done
    # Nothing to validate if $allowed includes no options set to 1.
    #
    (( applicable )) || continue
    # Any selected option from LOPTS that is not part of the current
    # option set is considered an invalid combination.
    #
    for option in "${LOPTS[@]}"; do
      var="${option}_0"
      (( ${!var} )) || continue
      [[ " ${allowed} " == *" ${option} "* ]] || invalid+=" --${option}"
    done 
    if [[ -n ${invalid} ]]; then
      echo
      msg E args "invalid combination of options"
      msg I "Conflicting option(s): ${invalid# }"
      msg I "try \`${IAM} --help'"
      echo
      return 1
    fi
  done
}

function phase1_error_lopts {
  # After stripping the first two characters from the command-line
  # arguments args_0[], the remainder is matched against valid
  # long-option names LOPTS[] with their first character removed.
  # A match e.g. "elp" means that the command-line argument is an
  # invalid long option missing a dash (-), such as -help.
  #
  local args option i
  args=$( for option in "${LOPTS[@]}"; do printf '%s|' "${option:1}"; done )
  args=${args%|}  # Remove last |.
  for i in "${args_0[@]}"; do
    if grep -iqwE -- ${args} <<< ${i:2}; then
      echo
      msg E args "invalid command-line argument"
      msg I "invalid long option detected: $i"
      msg I "try \`${IAM} --help'"
      echo
      return
    fi
  done
  return 1
}

function args_remaining {
  # Any remaining entries in args_0 represent unrecognized arguments
  # and are treated as invalid input.
  #
  if (( ${#args_0[@]} > 0 )); then
    echo
    msg E args "invalid command-line argument"
    msg I "argument(s): ${args_0[*]}"
    msg I "try \`${IAM} --help'"
    echo
  else
    return 1 # reverse status
  fi
}

function phase2_action {
  # Executes actions associated with enabled Phase 2 options.
  # Each enabled option maps to a corresponding *_ACTION handler.
  #
  status_0=0 # Default return status of actions.
  for option in "${LOPTS[@]}"; do
    var="${option}_0"
    (( ${!var} )) || continue
    action="${option^^}_ACTION"
    "${!action}"
  done
}

# ---------------------------------------------------------------------------
# Command-line parsing and related functions are based on:
# https://maxjot.github.io/maxJOT/ref/arguments_and_options.html
# ---------------------------------------------------------------------------

# MAIN #

term_init

# The LOPTS array lists all supported long options (--option).
#
LOPTS=( version help install uninstall )

phase_init "$@" 

if phase1_error_lopts; then
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
fi

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -h|--help)   help_0=1
                 HELP_ACTION=show_help
                 unset args_0[i] ;;
    --version)   version_0=1
                 VERSION_ACTION=show_version
                 unset args_0[i] ;;
    --install)   install_0=1
                 INSTALL_ACTION=run_install
                 unset args_0[i] ;;
    --uninstall) uninstall_0=1
                 UNINSTALL_ACTION=run_uninstall
                 unset args_0[i] ;;
  esac  
done

option_sets_0=( 'install' 'uninstall' 'help version' )

# At least one info/admin option was consumed.
#
if (( ${#args_0[@]} < ${LAST_INDEX} )); then
  # Consider any remaining arguments invalid
  #
  if args_remaining; then
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
  fi
  # Check invalid combinations if info/admin args apply.
  #
  if ! validate_option_sets; then
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
  fi
  # Continue executing the appropriate functions and exit the program.
  #
  phase2_action
  if (( SCREENPLAY_SOURCED )); then
    \SCREENPLAY_cleanup; return ${status_0}
  else
    exit ${status_0}
  fi
fi

payload_init "runfile"

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    "") continue ;; # Ignore empty array elements.
    -*) continue ;; # Ignore dash (-) options.
    *) SCREENPLAY_runfile_0="${args_0[i]}"; unset args_0[i]; break ;;
  esac  
done

# Consider any remaining arguments invalid
#
if args_remaining; then
  (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
fi

# Check that runfile_0 is valid when specified.
# Create default runfile if necessary.
#
if [[ -n ${SCREENPLAY_runfile_0} ]]; then
  if [[ ! -e ${SCREENPLAY_runfile_0} ]]; then
    echo
    msg E args "no such runfile"
    msg I "file: ${SCREENPLAY_runfile_0}"
    msg I "try \`${IAM} --help' for more information"
    echo
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
  fi 
else
  SCREENPLAY_runfile_0="${DEFAULT_RUNFILE}"
  # Recreate if missing or empty.
  [[ ! -s ${SCREENPLAY_runfile_0} ]] && gen_runfile
fi

# The runfile must be a text file and not empty.
#
if ! file "${SCREENPLAY_runfile_0}" | grep -qi 'text'; then
  echo
  msg E "runfile must be a text file"
  msg I "file: ${SCREENPLAY_runfile_0}"
  echo
  (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
fi

if [[ ! -s ${SCREENPLAY_runfile_0} ]]; then
  echo
  msg E args "empty runfile"
  msg I "file: ${SCREENPLAY_runfile_0}"
  msg I "try \`${IAM} --help' for more information"
  echo
  (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
fi

mute on
echo
box 4 --top
box 4 "${B3}Runfile: ${SCREENPLAY_runfile_0}"
box 4 --middle
box 4 "Commands in the runfile are displayed as though entered"
box 4 "interactively. Command output appears in real time."
box 4
box 4 "Commands are executed exactly as written, with the following"
box 4 "exceptions:"
box 4
box 4 "${BD}empty line   " 1  
box 4 "Prints the command prompt (simulates Return)."
box 4 "${BD}#            " 1
box 4 "Lines beginning with '#' are ignored (comments)."
box 4 "${BD}PAUSE        " 1
box 4 "Pause for N seconds (default: 3)."
box 4 "${BD}EXEC         " 1
box 4 "Execute a script, e.g.: EXEC script.sh"
box 4 "${BD}PROMPT       " 1
box 4 "Set the virtual command prompt, e.g.:"
box 4 "              PROMPT Saturn:~ dude\$"
box 4
box 4 "If ${BD}PROMPT" 1
box 4 "is omitted, the default prompt is derived from the"
box 4 "current user account, showing '#' for root and '$' for"
box 4 "non-privileged users. ${BD}EXEC" 1
box 4 "runs within ${IAM%.sh}'s context:"
box 4 "source ${IAM} -> source script.sh"
box 4 --middle
box 4 "${B3}After you press any key to continue, the screen is cleared"
box 4 "${B3}and a 5-second delay begins before the runfile is processed."
box 4 "${B3}When playback completes, the virtual command prompt remains"
box 4 "${B3}visible until you press Return to exit."
box 4 --bottom
echo
mute off

trap "abort=1; echo; return" INT
if ! any_key; then
    echo
    msg I any_key "aborted on CTRL-C"
    echo
    (( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 1; } || exit 1
fi

function SCREENPLAY_show_prompt {
  # Requires global variable prompt_0
  printf "%s " "${prompt_0:-${SCREENPLAY_DEFAULT_PROMPT}}"
}

function SCREENPLAY_run {
    local cmd
    SCREENPLAY_show_prompt
    sleep 1
    for ((i=0; i<${#1}; i++)); do
        printf "%s" "${1:i:1}"
        sleep 0.1
    done
    sleep 1
    echo
    if [[ $1 =~ ^[[:space:]]*source[[:space:]]+ ]]; then
      # Source execution without explicit arguments inherits the caller's
      # positional parameters, such as $1, $2, etc. Hence, $1 used by the
      # run function will propagate as $1 when sourcing without arguments.
      # Work around this by copying run's $1, using shift to remove the
      # function's positional parameter, and evaluating the copy.
      cmd=$1
      shift
      eval "${cmd}"
    else
      eval "$1"
    fi
}

function SCREENPLAY_runfile_helper {
  # Output: keyword parameter, if available.
  local keyword=$1 str=$2 str leading_spaces
  str=${str/${keyword}/}
  leading_spaces=${str%%[! ]*}
  str=${str#"${leading_spaces}"}
  echo "${str}"
}

# Check whether the first non-comment, non-blank line is a PROMPT
# directive. If so, use it during the 5-second process delay.
# 
while IFS= read -r cmd || [[ -n ${cmd} ]]; do
  [[ ${cmd} =~ ^[[:space:]]*$ ]] && continue
  [[ ${cmd} =~ ^[[:space:]]*# ]] && continue
  [[ ${cmd} =~ ^[[:space:]]*PAUSE ]] && continue
  if [[ ${cmd} =~ ^[[:space:]]*PROMPT ]]; then
    prompt_0=$( SCREENPLAY_runfile_helper PROMPT "${cmd}" )
    prompt_0=${prompt_0:-${SCREENPLAY_DEFAULT_PROMPT}}
  fi
  break
done < "${SCREENPLAY_runfile_0}"

clear
SCREENPLAY_show_prompt
sleep 5
printf "\r"

while IFS= read -r SCREENPLAY_cmd || [[ -n "${SCREENPLAY_cmd}" ]]; do
  # Ignore comment lines.
  [[ ${SCREENPLAY_cmd} =~ ^[[:space:]]*# ]] && continue
  # Keyword PAUSE defines an execution delay.
  if [[ ${SCREENPLAY_cmd} =~ ^[[:space:]]*PAUSE ]]; then
    pause_0=$( SCREENPLAY_runfile_helper PAUSE "${SCREENPLAY_cmd}" )
    sleep ${pause_0:-${SCREENPLAY_DEFAULT_PAUSE}}
    continue
  fi
  # Keyword PROMPT defines the simulated shell prompt.
  if [[ ${SCREENPLAY_cmd} =~ ^[[:space:]]*PROMPT ]]; then
    prompt_0=$( SCREENPLAY_runfile_helper PROMPT "${SCREENPLAY_cmd}" )
    prompt_0=${prompt_0:-${SCREENPLAY_DEFAULT_PROMPT}}
    continue
  fi
  # Simpulate Return on empty lines.
  [[ ${SCREENPLAY_cmd} =~ \
    ^[[:space:]]*$ ]] && { SCREENPLAY_show_prompt; echo; continue; }
  # prompt_0 defines the simulated shell prompt.
  #
  if [[ ${SCREENPLAY_cmd} =~ ^[[:space:]]*EXEC[[:space:]]+ ]]; then
    if (( SCREENPLAY_SOURCED )); then
      SCREENPLAY_run "source ${SCREENPLAY_cmd##EXEC }"
    else
      SCREENPLAY_run "./${SCREENPLAY_cmd##EXEC }"
    fi
    continue
  fi
  SCREENPLAY_run "${SCREENPLAY_cmd}"
done < "${SCREENPLAY_runfile_0}"

SCREENPLAY_show_prompt
read
(( SCREENPLAY_SOURCED )) && { \SCREENPLAY_cleanup; return 0; } || exit 0

## END
