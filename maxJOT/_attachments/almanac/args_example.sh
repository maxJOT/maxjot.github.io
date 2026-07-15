#!/usr/bin/env bash
#============================================================================
# Filename: args_example.sh
# Author:   maxJOT
# Purpose:  Process comandline options and arguments - demo
# Platform: macOS/Linux running Bash
# License:  https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  https://maxjot.github.io/maxJOT/bash/bash-almanac.html
#============================================================================

IAM=( ${BASH_SOURCE[0]##*/} 1.0 )

# Address exit vs. return if source exectued.
( return 0 2>/dev/null ) && sourced=1 || sourced=0

function help {
  echo "Usage:
  ${IAM} [-h | -v] [-d level] source [-o target]"
  echo
  echo "Arguments:
  -h, --help               show help.
  -v, --version            show version.
  -d, --demo level         demo level (0-3).
  -o, --output target      write to target filename.
  source                   input filename."
  echo
  echo "Examples:
  ${IAM} -d 1 sample.txt
  ${IAM} -d 1 sample.txt -o sample.cmp"
  echo
  echo "Description:
  Simple example how to process command line arguments."
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
  iam="${BASH_SOURCE[0]##*/}"
  iam="${iam%.sh}"
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
    unset -f help version err1 quit
    unset version help demo output target source level args combine
    unset sourced consolidate nomatch char item i IAM B1 T0 RG
    unset -f cleanup
}


# MAIN #

# First rule out single-dash long options. 
# Word matching is the trick here.
# 
for i in "$@"; do
  if grep -iqwE -- 'emo|ersion|elp|utput' <<< ${i:2}; then
    msg E args "Invalid command line argument."
    msg I "Invalid long option detected: ${i}"
    msg I "Try \`${IAM} --help' for more information."
    (( sourced )) && { cleanup; return 1; } || exit 1
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
demo=0 output=0 level=0 target=0 
#
for i in "${!args[@]}"; do
  if [[ ${demo} = 1 ]]; then
    case "${args[i]}" in
      [0-3]) level=${args[i]}; args[i]=; break ;;
      *) err1 ${LINENO} "Invalid compression level." \
           "Level: ${args[i]}" \
           "Try \`${IAM} --help' for more information."
         (( sourced )) && { cleanup; return 1; } || exit 1 ;;
    esac
  else
    case "${args[i]}" in
      -d|--demo) # Must not be the last argument 
        if (( i + 1 < ${#args[@]} )); then
          demo=1; args[i]=
        else
          msg E args "Missing compression level."
          msg I "Try \`${IAM} --help' for more information."
          (( sourced )) && { cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done

for i in "${!args[@]}"; do  
  if [[ ${output} = 1 ]]; then
    case "${args[i]}" in
      -*) err1 ${LINENO} "Invalid filename." \
            "Filename: ${args[i]}" \
            "Try \`${IAM} --help' for more information."
          (( sourced )) && { cleanup; return 1; } || exit 1 ;;
       *) target="${args[i]}"; args[i]=; break ;;
    esac
  else    
    case "${args[i]}" in
      -o|--output) # Must not be the last argument.
        if (( i + 1 < ${#args[@]} )); then
          output=1; args[i]=
        else
          msg args "No target filename."
          msg I "Try \`${IAM} --help' for more information."
          (( sourced )) && { cleanup; return 1; } || exit 1
        fi ;;
    esac
  fi
done

# Process arguments that are not options.
# Skip over emptied array slots and options.
#
for i in "${!args[@]}"; do
  case "${args[i]}" in
    "") continue ;;
    -*) continue ;;
    *) source="${args[i]}"; args[i]=; break ;;
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
  err1 ${LINENO} "Invalid option(s)." \
    "Invalid option(s): $*" \
    "Try \`${IAM} --help' for more information."
  (( sourced )) && { cleanup; return 1; } || exit 1
done
 
# Some options are mutually exclusive and cannot be combined.
#
(( help + version > 1 )) && combine=invalid
(( help + version + demo > 1 )) && combine=invalid
(( help + version + output > 1 )) && combine=invalid

if [[ ${combine} == invalid ]]; then
    msg E args "Invalid combination of command line arguments."
    msg "Try \`${IAM} --help' for more information."
    (( sourced )) && { cleanup; return 1; } || exit 1
fi

# Finished checking integrity of command line arguments.
# Continue processing the result.
#
(( help )) && { help; (( sourced )) && { cleanup; return; } || exit; }
(( version )) && { version; (( sourced )) && { cleanup; return; } || exit; }

# Source argument is mandatory, file must exist.
#
if [[ -z ${source} ]]; then
  msg E args "No source filename"
  msg I "Try \`${IAM} --help' for more information."
  (( sourced )) && { cleanup; return 1; } || exit 1
elif [[ ! -e ${source} ]]; then
  msg E args "File not found."
  msg I "File: ${source}"
  msg I "Try \`${IAM} --help' for more information."
  (( sourced )) && { cleanup; return 1; } || exit 1
fi

echo Result:
echo "source:   ${source}"
echo "output    ${output}"
echo "target:   ${target}"
echo "demo:     ${demo}"
echo "level:    ${level}"

cleanup

## END
