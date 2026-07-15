#!/usr/bin/env bash

IAM=( ${BASH_SOURCE[0]##*/} 1.1 )

# Address exit vs. return if source executed.
( return 0 2>/dev/null ) && sourced=1 || sourced=0

function help {
  echo "Usage:
  ${IAM} [-h | -v] [-d level] source [-o output filename]"
  echo
  echo "Arguments:
  -h, --help               show help
  -v, --version            show version
  -d, --demo level         demo level (0-3)
  -o, --output filename    write output to filename
  source                   source filename"
  echo
  echo "Examples:
  ${IAM} -d 1 sample.txt
  ${IAM} -d 1 sample.txt -o sample.out"
  echo
  echo "Description:
  Simple example how to parse command line arguments."
  echo
}

function version {
  echo "Version ${IAM[1]}"
  echo
  echo "Copyright (c) 2024-2026 maxJOT. All Rights Reserved."
  echo "Free to use but not for sale. No redistribution of modified"
  echo "copies. https://maxjot.github.io/maxJOT/license_maxjot.html"
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
    unset -f help version msg
    unset v_0 h_0 d_0 o_0 outfile_0 source_0 level_0 args_0 combine
    unset sourced consolidate nomatch char item i IAM B1 T0 RG
    unset -f cleanup
}


# MAIN #

# ----------------------------------------------------------------------------
# Phase 1 detects and rejects invalid long options that use a single
# dash (-) instead of two dashes (--). Word matching after removing
# the first two characters is used to detect these invalid forms.
# ----------------------------------------------------------------------------
#
for i in "$@"; do
  if grep -iqwE -- 'emo|ersion|elp|utput' <<< ${i:2}; then
    echo
    msg E args "invalid command line argument"
    msg I "invalid long option detected: ${i}"
    msg I "try \`${IAM} --help'"
    echo
    (( sourced )) && { \cleanup; return 1; } || exit 1
  fi
done

# ----------------------------------------------------------------------------
# Phase 2 parses simple short and long command-line options, such as
# -h, --help and -v, --version. These options may also be combined
# into a single argument, such as -hv or -vh. When recognized, the
# corresponding variables (h_0, v_0) are set to 1 and the matching
# option characters are removed from the argument list.
#
# Options may appear multiple times and in any order without causing
# any ill effects. Duplicate matches simply repeat setting the
# corresponding variables to 1. For example, -hv, -hhvv and -hvhhv
# all produce the same result.
#
# Any character inside a combined option that is not recognized by
# this parsing phase is extracted and reconstructed as a new command-
# line option for further processing during phase 3. For example:
#
#   -hvd 2  => h_0=1, v_0=1, -d 2
#   -hvcd 2 => h_0=1, v_0=1, -cd 2
# ----------------------------------------------------------------------------
#
declare -a args_0=("$@") 
h_0=0 v_0=0

for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    -h|--help) h_0=1; args_0[i]= ;;
    -v|--version) v_0=1; args_0[i]= ;;
    -[hv]*)
      # Support a combination of arguments.
      bundle="${args_0[i]#-}"
      nomatch=
      for (( j=0; j<${#bundle}; j++ )); do
        char="${bundle:j:1}"
        case "${char}" in
          h) h_0=1 ;;
          v) v_0=1 ;;
          *) nomatch+="${char}" ;;
        esac
      done
      # Remove matching options or create new options.
      [[ -n ${nomatch} ]] && args_0[i]="-${nomatch}" || args_0[i]=
    ;;
  esac
done

# ----------------------------------------------------------------------------
# Phase 3 parses dash (-) options that have not yet been consumed by
# any of the previous parsing phases. Unlike simple options, these
# require an additional argument or parameter to be valid, such as a
# number, word, or filename.
# 
# Valid options and parameters are assigned to variables and consumed
# from the argument list, just like in the previous parsing phases.
# These options must not be the last argument in the list but may occur
# in any order and may be specified multiple times without ill effects,
# other than reassigning the corresponding variables. For example:
#
#   -d 1 -d 3   => d_0=1, level_0=3
#   -o filename => o_0=1, outfile_0=filename
# ----------------------------------------------------------------------------
#
d_0=0 level_0=0 o_0=0 outfile_0=0 
#
for i in "${!args_0[@]}"; do
  if [[ ${d_0} = 1 ]]; then
    case "${args_0[i]}" in
      [0-3]) level_0=${args_0[i]}; args_0[i]=; break ;;
      *) echo
         msg E args "invalid demo level"
         msg I "level: ${args_0[i]}"
         msg I "try \`${IAM} --help'"
         echo
         (( sourced )) && { \cleanup; return 1; } || exit 1 ;;
    esac
  else
    case "${args_0[i]}" in
      -d|--demo) # Must not be the last argument 
        if (( i + 1 < ${#args_0[@]} )); then
          d_0=1; args_0[i]=
        else
          echo
          msg E args "missing demo level"
          msg I "try \`${IAM} --help'"
          echo
          (( sourced )) && { \cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done

for i in "${!args_0[@]}"; do  
  if [[ ${o_0} = 1 ]]; then
    case "${args_0[i]}" in
      -*) echo
          msg E args "invalid filename"
          msg I "filename: ${args_0[i]}"
          msg I "try \`${IAM} --help'"
          echo
          (( sourced )) && { \cleanup; return 1; } || exit 1 ;;
       *) outfile_0="${args_0[i]}"; args_0[i]=; break ;;
    esac
  else    
    case "${args_0[i]}" in
      -o|--output) # Must not be the last argument.
        if (( i + 1 < ${#args_0[@]} )); then
          o_0=1; args_0[i]=
        else
          echo
          msg E args "missing output filename"
          msg I "try \`${IAM} --help'"
          echo
          (( sourced )) && { \cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done
 
# ----------------------------------------------------------------------------
# Phase 4 parses stand-alone command-line arguments that are neither
# dash (-) options nor option parameters, such as keywords or filenames.
#
# At this stage, all valid command-line arguments should have been
# assigned to variables, and their corresponding array elements are empty.
#
# Finally, consolidate the array by removing all empty (consumed) elements
# and consider any remaining elements as invalid.
# ----------------------------------------------------------------------------
#
source_0=
#
for i in "${!args_0[@]}"; do
  case "${args_0[i]}" in
    "") continue ;; # Ignore empty array elements.
    -*) continue ;; # Ignore dash (-) options.
    *) source_0="${args_0[i]}"; args_0[i]=; break ;;
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
  msg E args "invalid argument"
  msg I "argument(s): ${consolidate[@]}"
  msg I "try \`${IAM} --help'"
  echo
  (( sourced )) && { \cleanup; return 1; } || exit 1
fi
 
# ----------------------------------------------------------------------------
# Phase 5 determines which command-line arguments are mandatory and
# which options are mutually exclusive. Since validated option flags
# are either set to 1 or remain at 0, simple arithmetic can be used
# to detect invalid combinations.
#
# This final phase also verifies required filenames and executes
# help or version functions according to the specified option flags.
# ----------------------------------------------------------------------------#
(( h_0 + v_0 > 1 )) && combine=invalid
(( h_0 + v_0 + d_0 > 1 )) && combine=invalid
(( h_0 + v_0 + o_0 > 1 )) && combine=invalid

if [[ ${combine} == invalid ]]; then
    echo
    msg E args "invalid combination of arguments"
    msg I "try \`${IAM} --help'"
    echo
    (( sourced )) && { \cleanup; return 1; } || exit 1
fi

# Display help and version as requested.
#
(( h_0 )) && { \help; (( sourced )) && { \cleanup; return; } || exit; }
(( v_0 )) && { \version; (( sourced )) && { \cleanup; return; } || exit; }

# Source variable is mandatory, file must exist.
#
if [[ -z ${source_0} ]]; then
  echo
  msg E args "missing source filename"
  msg I "try \`${IAM} --help'"
  echo
  (( sourced )) && { \cleanup; return 1; } || exit 1
elif [[ ! -e ${source_0} ]]; then
  echo
  msg E args "file not found"
  msg I "file: ${source_0}"
  msg I "try \`${IAM} --help'"
  echo
  (( sourced )) && { \cleanup; return 1; } || exit 1
fi

echo
echo "Parsed command line arguments:"
echo "------------------------------"
echo "source:   ${source_0}"
echo "output    ${o_0}"
echo "outfile:  ${outfile_0}"
echo "demo:     ${d_0}"
echo "level:    ${level_0}"

cleanup

## END
