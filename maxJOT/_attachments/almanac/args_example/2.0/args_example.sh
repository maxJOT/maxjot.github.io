#!/usr/bin/env bash
#============================================================================
# Filename: args_example.sh | Author: maxJOT | Platform: macOS/Linux
# Purpose:  Parse command-line options and arguments (demo)
# See --help, --version, --changelog
#
# Variable naming conventions:
#   lowercase_0 = global mutable variable
#   UPPERCASE   = static, global or exported variable
#   lowercase   = local, temporary variable
#============================================================================

IAM=( ${BASH_SOURCE[0]##*/} 2.0 )

# Exit vs. return if source executed. Create a snapshot of
# variables and functions when source executed, so we can use
# this information later to restore the shell environment when
# executing the cleanup function.  
#
if ( return 0 2>/dev/null ); then
  SOURCED=1
  ENV_VARIABLES=$( compgen -v )
  ENV_FUNCTIONS=$( compgen -A function )
else
  SOURCED=0
fi

function show_help {
  echo "Usage:
  ${IAM} [--install | --uninstall]
  ${IAM} [-h | --help | --version | --changelog]
  ${IAM} [-x <type>] [-d] [-v] <target> [-o <directory>]
  ${IAM} [-x <type>] [-d] [-v] [-t] <target>"
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
}

function run_uninstall {
  echo
  msg I uninstall "placeholder"
  echo 
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
  # Coherent messaging for errors and information.
  # (https://maxjot.github.io/maxJOT/bash/bash-almanac.html)
  # $1 = Severity E W I
  # $2 = Function or facility (optional)
  # $3 = Text (optional)
  #
  local b1 t0 iam opt cln fac= str=
  b1=$( tput bold; tput setaf 1)
  t0=$( tput sgr0 )
  cln="${BASH_LINENO[0]}" # Caller line number.
  iam="${IAM%.sh}"
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

function cleanup {
    # Avoid tainting the calling shell environment with variables
    # and functions created by this script when source executed.
    # Be sure not to remove variables before functions!
    #
    local item
    while IFS= read -r item; do
      unset -f ${item}
    done < <( awk 'FNR==NR{a[$0]++;next}!($0 in a)' - \
                <<< "${ENV_FUNCTIONS}" <( compgen -A function ) )
    while IFS= read -r item; do
      unset ${item}
    done < <( awk 'FNR==NR{a[$0]++;next}!($0 in a)' - \
                <<< "${ENV_VARIABLES}" <( compgen -v ) )
    unset IAM
    unset -f cleanup
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
  # Later phases (phase 4) may use this value for boundary checks after
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
    return 1 # Reverse status
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
    action="$(printf '%s' "${option}_ACTION" | tr '[:lower:]' '[:upper:]')"
    "${!action}"
  done
}

function phase4_duplicate {
  # $1 $2 = Short and long option to check, e.g. "-x" "--extract"
  #
  local round=0
  for i in "${!args_0[@]}"; do
    case "${args_0[i]}" in
      "$1"|"$2") round=$(( round + 1 )) 
        if (( round > 1 )); then
          echo
          msg E args "invalid duplicate option"
          msg I "Conflicting option: ${args_0[i]} ${args_0[i+1]}"
          msg I "try \`${IAM} --help'"
          echo
          (( SOURCED )) && { \cleanup; return 1; } || exit 1
        fi ;;
    esac
  done
}

function chk_file {
  # requires global variable name.
  local var=$1
  local file="${!var}"
  local name=${var%_0}
  if [[ -z ${file} ]]; then
    echo
    msg E args "${name} not specified"
    msg I "try \`${IAM} --help'"
    echo
    return 1
  elif [[ -d ${file} ]]; then
    echo
    msg E args "${name} cannot be a directory"
    msg I "directory: ${file}"
    msg I "try \`${IAM} --help'"
    echo
    return 1
  elif [[ ! -e ${file} ]]; then
    echo
    msg E args "${name} not found"
    msg I "file: ${file}"
    msg I "try \`${IAM} --help'"
    echo
    return 1
  fi
}

function chk_directory {
  # requires global variable name.
  local var=$1
  local directory="${!var}"
  if [[ ! -e ${directory} ]]; then
    echo
    msg E args "directory does not exist"
    msg I "directory: ${directory}"
    msg I "try \`${IAM} --help'"
    echo
    return 1
  elif [[ ! -d ${directory} ]]; then
    echo
    msg E args "not a directory"
    msg I "directory: ${directory}"
    msg I "try \`${IAM} --help'"
    echo
    return 1
  fi
}

# MAIN #

# ---------------------------------------------------------------------------
# Phase 1 uses the LOPTS[] array to initialize all supported long option
# variables and rejects long options arguments, that are written with a
# single dash (-) instead of two dashes (--), e.g.: -help vs. --help.
# ---------------------------------------------------------------------------

# The LOPTS array lists all supported long options (--option).
#
LOPTS=( version help changelog install uninstall
        debug extract verbose test outdir )

phase_init "$@" 

if phase1_error_lopts; then
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
fi

# ---------------------------------------------------------------------------
# Phase 2 handles command-line arguments that comply to information
# standards, such as --help, --version, etc. Such tasks terminate upon
# completion and do not need to involve the parsing of options related
# to a program's actuall purpose or operation.
#
# Recognized options are consumed from args_0 and mapped to state
# variables and/or actions. Any remaining entries in args_0 after
# processing are considered invalid.
# ---------------------------------------------------------------------------

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -h|--help)   help_0=1
                 HELP_ACTION=show_help
                 unset args_0[i] ;;
    --changelog) changelog_0=1
                 CHANGELOG_ACTION=show_changelog
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

# The option_set array defines one or more option sets that are mutually
# exclusive with all other command-line options. An option set may consist
# of a single option or multiple options. When a set consists of multiple
# options, the options within that set are not mutually exclusive and may
# be combined. For example: 
#
# install
#   The --install option is mutually exclusive and may not be combined
#   with any other command-line argument.
#
# help version changelog
#   Any combination of --help, --version, and --changelog is valid,
#   but may not be combined with any other command-line argument.
#
option_sets_0=( 'install' 'uninstall' 'help version changelog' )

# At least one info/admin option was consumed.
#
if (( ${#args_0[@]} < ${LAST_INDEX} )); then
  # Consider any remaining arguments invalid
  #
  if args_remaining; then
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
  # Check invalid combinations if info/admin args apply.
  #
  if ! validate_option_sets; then
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
  # Continue executing the appropriate functions and exit the program.
  #
  phase2_action
  (( SOURCED )) && { \cleanup; return ${status_0}; } || exit ${status_0}
fi

# ---------------------------------------------------------------------------
# Phase 3 parses simple short and long options, such as -v, --verbose or
# -d, --debug. Short options may also be combined into a single argument,
# such as -dv or -vd. When matched, the corresponding variables are set
# to 1 and the appropriate arguments are consumed from args_0[].
#
# Options may appear multiple times and in any order. Duplicate matches
# simply repeat setting the corresponding variables to 1.
#
# Phase 3 only handles options that require no additional parameter.
# Any character within a combined short option that is not recognized by
# this phase is reconstructed as a new command-line argument and left for
# subsequent parsing phases. For example:
#
#   -dvx 2         =>  debug_0=1, verbose_0=1, -x 2
#   --abc -vdcx 2  =>  debug_0=1, verbose_0=1, -cx 2 --abc
# ---------------------------------------------------------------------------

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -d|--debug) debug_0=1; unset args_0[i] ;;
    -t|--test) test_0=1; unset args_0[i] ;;
    -v|--verbose) verbose_0=1; unset args_0[i] ;;
    -[dtv]*)
      # Support combined arguments.
      #
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
      # Consume recognized option letters and keep any unrecognized
      # letters as a single dash-prefixed argument. e.g.: -dave => -ae
      # This also permits mixed bundles such as -dvx 2 and -dxv 2,
      # both of which become -x 2 and are handled by the subsequent
      # parser phase for options that take a parameter.
      #
      [[ -n ${nomatch} ]] && args_0[i]="-${nomatch}" || unset args_0[i]
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

payload_init "type directory"

phase4_duplicate "-x" "--extract"
#
for i in "${!args_0[@]}"; do
  if [[ ${extract_0} = 1 ]]; then
    case "${args_0[i]}" in
      [0-3]) type_0=${args_0[i]}; unset args_0[i]; break ;;
      *) echo
         msg E args "invalid extraction type"
         msg I "type: ${args_0[i]}"
         msg I "try \`${IAM} --help'"
         echo
         (( SOURCED )) && { \cleanup; return 1; } || exit 1 ;;
    esac
  else
    case "${args_0[i]}" in
      -x|--extract)
        # Must not be the last argument 
        #
        if (( i + 1 < ${LAST_INDEX} )); then
          extract_0=1; unset args_0[i]
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

phase4_duplicate "-o" "--outdir"
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
       *) directory_0="${args_0[i]}"; unset args_0[i]; break ;;
    esac
  else    
    case "${args_0[i]}" in
      -o|--outdir)
        # Must not be the last argument.
        #
        if (( i + 1 < ${LAST_INDEX} )); then
          outdir_0=1; unset args_0[i]
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
# been consumed and variables.
# ---------------------------------------------------------------------------

payload_init "target"

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    "") continue ;; # Ignore empty array elements.
    -*) continue ;; # Ignore dash (-) options.
    *) target_0="${args_0[i]}"; unset args_0[i]; break ;;
  esac  
done

# Consider any remaining arguments invalid
#
if args_remaining; then
  (( SOURCED )) && { \cleanup; return 1; } || exit 1
fi

# ---------------------------------------------------------------------------
# Phase 6 validates relationships between parsed command-line arguments,
# such as mandatory arguments, incompatible argument combinations, and
# argument sanity checks as required. For example:
# ---------------------------------------------------------------------------

# Option --test and --outdir are mutually exclusive.
#
if (( test_0 )); then 
  option_sets_0=( 'verbose debug extract test' )
  if ! validate_option_sets; then
    (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
fi

# Assign extract and type default.
#
[[ ${extract_0} -eq 0 ]] && { type_0=3; }

# Target is mandatory, file must exist.
#
if ! chk_file target_0; then
  (( SOURCED )) && { \cleanup; return 1; } || exit 1
fi

# Output directory (-o) when specified must be a directory.
#
if [[ ${outdir_0} -eq 1 ]]; then
  if ! chk_directory directory_0; then
     (( SOURCED )) && { \cleanup; return 1; } || exit 1
  fi
fi

# Proceed with showing the results.
#
echo
echo "RESULT"
echo "------"
echo
printf "Command-line arguments:\n\n%s\n\n" "$*"
printf "Parsed options:\n\n"
printf "%-20s%s\n" "Source execution:" ${SOURCED}
printf "%-20s%s\n" target: "${target_0}"
printf "%-20s%s" "extract type:" "${type_0}"
(( extract_0 )) && printf "\n" || printf " (default)\n"
(( test_0 )) && printf "%-20s%s\n" "test mode:" on
(( outdir_0 )) && printf "%-20s%s\n" "output directory:" "${directory_0}"
printf "%-20s%s\n" outdir: ${outdir_0}
printf "%-20s%s\n" test: ${test_0}
printf "%-20s%s\n" debug: ${debug_0}
printf "%-20s%s\n" verbose: ${verbose_0}
#
(( SOURCED )) && cleanup

## END
