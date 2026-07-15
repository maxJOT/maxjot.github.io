#!/usr/bin/env bash
#============================================================================
# Filename: args_example.sh | Author: maxJOT | Platform: macOS/Linux
# Purpose:  Parse command-line options and arguments (demo)
# See --help, --license, --version, --changelog

# Naming conventions:
#   lowercase_0 = global mutable variable
#   UPPERCASE   = static, global or exported variable
#   lowercase   = local, temporary variable
#============================================================================

IAM=( ${BASH_SOURCE[0]##*/} 2.0 )

# Address exit vs. return if source executed.
( return 0 2>/dev/null ) && SOURCED=1 || SOURCED=0

function show_help {
  echo "Usage:
  ${IAM} [--install | --uninstall]
  ${IAM} [-h | --help | --version | --changelog]
  ${IAM} [-x <type>] [-d] [-v] <target> [-o <directory>]"
  echo
  echo "Options:
  -h, --help                 show this help screen
      --version              show version
      --changelog
      --install              install this program
      --uninstall            uninstall this program
  -d, --debug                debug mode
  -o, --outdir <directory>   write output to directory
  -t, --test                 test run (no output)
  -v, --verbose              verbose operation             
  -x, --extract <type>       extraction types:
                               0 audio
                               1 images
                               2 video
                               3 all of the above (default)"
  echo "Arguments:
  <target>                   file to process"
  echo
  echo "Examples:
  ${IAM} -dvx 1 sample.bin -o ~/Desktop"
  echo
  echo "Description:
  Demonstrates command-line argument parsing.
  URL: https://maxjot.github.io/maxJOT/bash/bash-almanac.html"
  echo
}

function show_version {
  echo "Version ${IAM[1]}"
  echo
  echo "Copyright (c) 2026 maxJOT. All Rights Reserved."
  echo "Free to use but not for sale. No redistribution of modified"
  echo "copies. https://maxjot.github.io/maxJOT/license_maxjot.html"
  echo
}

function run_install {
  echo
  msg I install "placeholder"
  echo
  (( SOURCED )) && { \cleanup; return 0; } || exit 0
}

function run_uninstall {
  echo
  msg I uninstall "placeholder"
  echo 
  (( SOURCED )) && { \cleanup; return 0; } || exit 0
}

function show_changelog {
  echo "Changelog:
  Initial version 1.0 (15-Mar-2026)
  Version 2.0 (26-MAY-2026)
    - changing variable scope and naming
    - changing demo example
    - revisiting documentation sections
    - various coding and workflow changes
    - new validate section"
  echo
}

function msg {
  #
  # Coherent messaging for errors and information.
  # (https://maxjot.github.io/maxJOT/bash/bash-almanac.html)
  # $1 = Severity E W I
  # $2 = Function or facility (optional)
  # $3 = Text (optional)
  local iam opt cln fac= str=
  cln="${BASH_LINENO[0]}" # Caller line number.
  iam="${IAM%.sh}"
  [[ -n $2 ]] && fac=", $2"
  [[ -n $3 ]] && str=", $3"
  opt="${fac}${str}"
  case "$1" in
    E) printf "%%%s-E-%s%s\n\a" "${iam}" ${cln} "${opt}" >&2 ;;
    W) printf "%%%s-W-%s%s\n" "${iam}" ${cln} "${opt}" >&2 ;;
    I) printf "%%%s-I-%s%s\n" "${iam}" ${cln} "${opt}" ;;
    *) printf "%s\n" "$@" ;;
  esac
}

function cleanup {
    # Unset special variables.
    unset -f show_help show_version run_install run_uninstall
    unset -f show_changelog validate msg phase_init
    unset directory_0 target_0 type_0 args_0 lopts_0
    unset help_0 verbose_0 uninstall_0 install_0 debug_0 extract_0
    unset test_0 outdir_0 changelog_0 version_0
    unset IAM SOURCED
    unset opt consolidate nomatch bundle char i j
    unset item invalid args
    unset -f cleanup
}

function phase_init {
  # Requires: $1 - options
  # Initialize option variables $lopts_0 (global mutual _0}
  local option
  lopts_0="$1"
  for option in ${lopts_0}; do
    printf -v "${option}_0" '%d' 0
  done
}

function validate() {
  # Req. $1:       list allowed variables (options), whose value can be 1.
  # Req. $lopts_0: list of available long options to check against.
  # Returns:       list of variable names that are set to 1, which are not
  #                included in $1, and are therefore invalid.
  # Example:       invalid=$( validate "verbose debug extract test" )
  #                invalid="--outdir"
  #
  local allowed=$1 applicable=0 invalid=
  local option var
  # Determine if any of the variables has been set to 1. 
  # If all variables are 0, then there is nothing to validate.
  for option in ${allowed}; do
    var="${option}_0"
    (( ${!var} )) && { applicable=1; break; }
  done
  # Nothing to validate if $1 includes no options set to 1.
  (( applicable )) || return 0
  # Check if any options from $lopts are set to 1 and not included
  # in $allowed and consider them invalid.
  for option in ${lopts_0}; do
    var="${option}_0"
    (( ${!var} )) || continue
    grep -qw "${option}" <<< "${allowed}" || invalid+=" --${option}"
  done
  printf '%s\n' "${invalid# }"
}

# MAIN #

# ---------------------------------------------------------------------------
# Phase 1 detects and rejects invalid long options that use a single
# dash (-) instead of two dashes (--). Word matching after removing
# the first two characters is used to detect these invalid forms.
# ----------------------------------------------------------------------------
#
args="ersion|elp|nstall|ninstall|hangelog|ebug|erbose|xtract|irectory"
for i in "$@"; do
  if grep -iqwE -- "${args}" <<< "${i:2}"
  then
    echo
    msg E args "invalid command-line argument"
    msg I "invalid long option detected: ${i}"
    msg I "try \`${IAM} --help'"
    echo
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
done

# ---------------------------------------------------------------------------
# Phase 2 manages command-line arguments related to program help,
# information, and self-administration tasks. Such options perform
# their requested action and terminate the program upon completion.
#
# These options do not participate in the program's normal operation,
# accept no additional parameters, and may be combined when meaningful.
# Any other command-line arguments given together with them are
# considered incompatible and reported as invalid.
#
# To keep the remaining parser phases dedicated to the program's actual
# operation and avoid unnecessary parsing complexity, phase 2 is handled
# separately and prior to all other argument processing.
# ---------------------------------------------------------------------------
#
declare -a args_0=("$@")
declare -a consolidate=()
unset opt invalid conflict
#
phase_init "help changelog version install uninstall"

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -h|--help)   help_0=1;      opt=1; args_0[i]= ;;
    --changelog) changelog_0=1; opt=1; args_0[i]= ;;
    --version)   version_0=1;   opt=1; args_0[i]= ;;
    --install)   install_0=1;   opt=1; args_0[i]= ;;
    --uninstall) uninstall_0=1; opt=1; args_0[i]= ;;
  esac  
done

if [[ -n ${opt} ]]; then 
  # Consolidate the list of command-line arguments by removing
  # emptied (consumed) array elements. When any info/admin option
  # is requested, any other or remaining command-line arguments are
  # incompatible.
  #
  for option in "${args_0[@]}"; do
    [[ -n "${option}" ]] && consolidate+=( "${option}" )
  done
  if (( ${#consolidate[@]} > 0 )); then
    echo
    msg E args "invalid command-line argument"
    msg I "argument(s): ${consolidate[*]}"
    msg I "try \`${IAM} --help'"
    echo        
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
fi

if [[ -n ${opt} ]]; then
  # Determine mutual exclusive or group option relationships.
  #
  [[ -z ${invalid} ]] && invalid=$( validate "install" )
  [[ -z ${invalid} ]] && invalid=$( validate "uninstall" )
  [[ -z ${invalid} ]] && invalid=$( validate "help version changelog" )
  if [[ -n ${invalid} ]]; then
    echo
    msg E args "invalid combination of options"
    msg I "Conflicting option(s): ${invalid# }"
    msg I "try \`${IAM} --help'"
    echo
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
  # Continue executing the appropriate functions and exit the program.
  #
  (( help_0 ))       && show_help
  (( version_0 ))    && show_version
  (( changelog_0 ))  && show_changelog
  (( install_0 ))    && run_install
  (( uninstall_0 ))  && run_uninstall
  (( SOURCED )) && { \cleanup; return 0; } || exit 0
fi

# ---------------------------------------------------------------------------
# Phase 3 parses simple short and long command-line options, such as
# -v, --verbose or -d, --debug. Short options may also be combined
# into a single argument, such as -dv or -vd. When matched, the
# corresponding variables (verbose_0, debug_0) are set to 1 and the
# approprite arguments are removed from the argument list ${args_0[@]}.
#
# Options may appear multiple times and in any order without causing
# any ill effects. Duplicate matches simply repeat setting the
# corresponding variables to 1. For example, -dv, -ddvv and -dvddv
# all produce the same result.
#
# Phase 3 only manages simple options that have no additional parameter.
# Any character inside a combined option that is not recognized by this
# parsing phase is extracted and reconstructed as a new command-line
# option. Unknown long options are unaffected. For example:
#
#   -dvx 2         =>  debug_0=1, verbose_0=1, -x 2
#   --abc -vdcx 2  =>  debug_0=1, verbose_0=1, -cx 2 --abc
# ---------------------------------------------------------------------------
#
phase_init "debug test verbose extract outdir"
#
# Create a copy of the command-line arguments.
declare -a args_0=("$@") 
#
for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -d|--debug) debug_0=1; args_0[i]= ;;
    -t|--test) test_0=1; args_0[i]= ;;
    -v|--verbose) verbose_0=1; args_0[i]= ;;
    -[dtv]*)
      # Support a combination of arguments.
      bundle="${args_0[i]#-}"
      nomatch=
      for (( j=0; j<${#bundle}; j++ )); do
        char="${bundle:j:1}"
        case "${char}" in
          d) debug_0=1 ;;
          t) test_0=1 ;;
          v) verbose_0=1 ;;
          *) nomatch+="${char}" ;;
        esac
      done
      # Remove matching options or create new options.
      [[ -n ${nomatch} ]] && args_0[i]="-${nomatch}" || args_0[i]=
    ;;
  esac
done

# ---------------------------------------------------------------------------
# Phase 4 parses dash (-) options that have not yet been consumed by
# any the previous parsing phase and require an additional argument or
# parameter to be valid, such as a number, word, or directory.
# 
# Valid options and parameters are assigned to variables and consumed
# from the argument list, just like in the previous parsing phases.
# These options may occur in any order, but unlike simple options are
# NOT allowed to be specified multiple times.
# 
# The actual payload of these variables. e.g. --extract 3, where 3 is the
# payload, will need to be stored in additional variables, e.g. type_0.
# For example:
#
#   -x 1                =>  extract_0=1, type_0=1
#   --outdir ~/Desktop  =>  outdir_0=1, directory_0=~/Desktop
# ---------------------------------------------------------------------------
#
type_0=0 directory_0= 
#
for i in "${!args_0[@]}"; do
  if [[ ${extract_0} = 1 ]]; then
    case "${args_0[i]}" in
      [0-3]) type_0=${args_0[i]}; args_0[i]= ;break ;;
      *) echo
         msg E args "invalid extraction type"
         msg I "type: ${args_0[i]}"
         msg I "try \`${IAM} --help'"
         echo
         (( SOURCED )) && { \cleanup; return 1; } || exit 1 ;;
    esac
  else
    case "${args_0[i]}" in
      -x|--extract) # Must not be the last argument 
        if (( i + 1 < ${#args_0[@]} )); then
          extract_0=1; args_0[i]=
        else
          echo
          msg E args "missing extraction type"
          msg I "try \`${IAM} --help'"
          echo
          (( SOURCED )) && { \cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done
#
for i in "${!args_0[@]}"; do  
  if [[ ${outdir_0} = 1 ]]; then
    case "${args_0[i]}" in
      -*) echo
          msg E args "invalid directory name"
          msg I "directory: ${args_0[i]}"
          msg I "try \`${IAM} --help'"
          echo
          (( SOURCED )) && { \cleanup; return 1; } || exit 1 ;;
       *) directory_0="${args_0[i]}"; args_0[i]=; break ;;
    esac
  else    
    case "${args_0[i]}" in
      -o|--outdir) # Must not be the last argument.
        if (( i + 1 < ${#args_0[@]} )); then
          outdir_0=1; args_0[i]=
        else
          echo
          msg E args "missing output directory name"
          msg I "try \`${IAM} --help'"
          echo
          (( SOURCED )) && { \cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done
 
# ---------------------------------------------------------------------------
# Phase 5 parses stand-alone command-line arguments that are neither
# dash (-) options nor option parameters, such as keywords or filenames.
#
# At this stage, all valid command-line options and arguments should have
# been consumed and erased from the argument array and assigned to global
# (_0) variables.
#
# Finally, consolidate the array by removing all empty elements and consider
# any remaining elements to be invalid.
# ---------------------------------------------------------------------------
#
target_0=
#
for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    "") continue ;; # Ignore empty array elements.
    -*) continue ;; # Ignore dash (-) options.
    *) target_0="${args_0[i]}"; args_0[i]=; break ;;
  esac  
done

# Consolidate the list of command line arguments by
# removing empty (consumed) array elements.
#
declare -a consolidate=()
for item in "${args_0[@]}"; do
  [[ -n "${item}" ]] && consolidate+=( "${item}" )
done

# Any remaining command line arguments are invalid.
#
if (( ${#consolidate[@]} > 0 )); then
  echo
  msg E args "invalid command-line argument"
  msg I "argument(s): ${consolidate[*]}"
  msg I "try \`${IAM} --help'"
  echo
  (( SOURCED )) && { \cleanup; return 1; } || exit 1
fi

# ---------------------------------------------------------------------------
# Phase 6 validates relationships between parsed command-line arguments,
# such as mandatory arguments, incompatible argument combinations, and
# argument sanity checks as required. For example:
#
# When test_0 is 1, the allowed options are -vd -extract --test
# (( t_0 )) && invalid=$( validate vdxt )
# ---------------------------------------------------------------------------
#
invalid=
(( test_0 )) && invalid=$( validate "verbose debug extract test" )

if [[ -n ${invalid} ]]; then
  echo
  msg E args "invalid combination of option"
  msg I "Conflicting option(s): ${invalid}"
  msg I "try \`${IAM} --help'"
  echo
  (( SOURCED )) && { \cleanup; return 1; } || exit 1
fi

# Target variable is mandatory, file must exist.
#
if [[ -z ${target_0} ]]; then
  echo
  msg E args "target not specified"
  msg I "try \`${IAM} --help'"
  echo
  (( SOURCED )) && { cleanup; return 1; } || exit 1
elif [[ -d ${target_0} ]]; then
  echo
  msg E args "target cannot be a directory"
  msg I "directory: ${target_0}"
  msg I "try \`${IAM} --help'"
  echo
  (( SOURCED )) && { cleanup; return 1; } || exit 1
elif [[ ! -e ${target_0} ]]; then
  echo
  msg E args "file not found"
  msg I "file: ${target_0}"
  msg I "try \`${IAM} --help'"
  echo
  (( SOURCED )) && { cleanup; return 1; } || exit 1
fi

# Output (-o) when specified must be a directory.
#
if [[ ${outdir_0} -eq 1 ]]; then
  if [[ ! -e ${directory_0} ]]; then
    echo
    msg E args "directory does not exist"
    msg I "directory: ${directory_0}"
    msg I "try \`${IAM} --help'"
    echo
    (( SOURCED )) && { cleanup; return 1; } || exit 1
  elif [[ ! -d ${directory_0} ]]; then
    echo
    msg E args "not a directory"
    msg I "directory: ${directory_0}"
    msg I "try \`${IAM} --help'"
    echo
    (( SOURCED )) && { cleanup; return 1; } || exit 1
  fi
fi

# Assign defaults.
#
[[ ${extract_0} -eq 0 ]] && { extract_0=1; type_0=3; }

# Proceed with the results.
#
echo
echo "Parsed command-line arguments:"
echo "------------------------------"
echo "output    ${outdir_0}"
echo "extract:  ${extract_0}"
echo "debug:    ${debug_0}"
echo "verbose:  ${verbose_0}"
echo "test:     ${test_0}"
echo
echo "target:   ${target_0}"
echo "type:     ${type_0}"
echo "outdir:   ${directory_0}"
cleanup

## END