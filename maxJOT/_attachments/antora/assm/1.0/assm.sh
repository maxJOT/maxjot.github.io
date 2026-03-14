#!/usr/bin/env bash
#============================================================================
# Filename: assm.sh (Antora Single Site Manager"
# Author:   maxJOT, 15-DEC-25
# Purpose:  Manage a Single Antora Site
# Platform: macOS/Linux running Bash 5
# License:  Copyright (c) 2024-2025 maxJOT, All Rights Reserved. 
#           The author hereby grants the following rights:
#           Free to use but not for sale. No redistribution of modified
#           copies. https://maxjot.github.io/maxJOT/license_maxjot.html
# Purpose:  Automate common Antora site tasks while minimizing potential
#           pitfalls. This script provides a menu to build, publish, verify,
#           and restore GitHub credentials. Command-line options allow quick
#           access to individual menu options.
#============================================================================

IAM=( ${BASH_SOURCE[0]##*/} 1.0 )

function err1 { #############################################################
  # Error message. Takes $1 (lineno) $2 (msg). $3 $4 $5 are optional.
  #
  local B1=$( tput bold; tput setaf 1)
  local T0=$( tput sgr0 )
  local RG=$( tput bel )
  echo; echo "${IAM} ($1) Aborted."
  echo "${IAM}: ${B1}$2${T0}${RG}"
  [[ -n $3 ]] && echo "$3"
  [[ -n $4 ]] && echo "$4"
  [[ -n $5 ]] && echo "$5"
}

# Exit if this script has been source-executed.
#
( return 0 > /dev/null 2>&1 )
if [[ $? -eq 0 ]]; then
  echo
  \err1 S "Source-execution unsupported."
  unset -f err1 
  unset IAM
  return 1
fi

function checksum { #########################################################
  # The following aims to protect from installation or download corruption.
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
    exit 
  elif [[ ${crc[0]} != "${num[2]}" ]]; then
    err1 ${LINENO} "Self-integrity check failed." \
      "Please download and install a new copy."
    echo; exit 1
  fi
}

checksum "$1"

function msg1 { #############################################################
  # Screen to display when YAML parser is required.
  # Requires: $PLAYBOOK, $SITE_USER_DIR
  #
  mute
  box 0 box_top
  box 0 "${B3}Note:${T0} ${BD}\"output:\" section detected."
  box 0 "File: ${BD}${PLAYBOOK}"
  box 0
  box 0 "Your Antora playbook contains an ${BD}output${T0} section and"
  box 0 "requires a YAML format parser to interpret it correctly."
  box 0
  box 0 "ASSM cannot continue, unless you remove the output section and"
  box 0 "let Antora use the default (build/site), or download \`yq' from:"
  box 0 "https://github.com/mikefarah/yq/releases/latest/download"
  box 0
  box 0 "Please download \`yq' (~14 MB) and copy it to the ASSM Site"
  box 0 "Configuration Directory with execute permission (chmod u+x yq)."
  box 0 "Directory: ${B3}${SITE_USER_DIR}"
  box 0 box_bottom
  umute
}

function file_header { ######################################################
  printf '%s\n' \
  "#====================================================================" \
  "# Filespec:  ${outfile}" \
  "# Site Name: ${SITE_NAME}" \
  "# Date:      ${DATE_TAG}" \
  "#====================================================================" \
  "#"
}

function readme_txt { #######################################################
  # Contents of readme.txt.
  #
  local att=$'!'
  #
  echo -e "
  Filename:  ${outfile}\n  Site Name: ${SITE_NAME}\n  Date:      ${DATE_TAG}\n
  \n  README.TXT\n
  This directory contains files used by the Antora Single Site Manager.
  (${IAM}, Version ${IAM[1]})\n  WARNING${att}\n
  Do not delete this directory. It may contain important GIT (.git)
  repository information. The Antora Single Site Manager will recreate
  missing files and directories automatically, but any customizations
  will be lost.\n
  -------------------------------------------------------------------------\n
  git.conf:
  Edit the GIT_URL variable to match your remote GitHub repository.
  This repository is used to publish the Antora-generated site to
  github.io.\n
  -------------------------------------------------------------------------\n
  site.conf:
  Defines configurable options for Node services, Antora Single Site
  Manager internals, and OS-specific Node Manager initialization.\n
  -------------------------------------------------------------------------\n
  postproc.sh:
  Post-processing tasks required by the Antora build and publish functions.
  It addresses modifes html files to enable custom number-badge feature for
  reference markers.\n
  -------------------------------------------------------------------------\n
  keys (directory):
  sshkeys.tar:
  Backup of the last working GitHub public and private SSH keys used
  for passwordless authentication.
  cert.pem, key.pem:
  Clipboard API (copy code) requires a secure context (HTTPS).\n
  -------------------------------------------------------------------------\n 
  .git (hidden directory):
  When publishing via GIT, the .git directory inside the Antora-generated
  site is a symlink to this directory. This allows the site output to be
  removed and rebuilt without losing GIT history.\n
  "
}

function site_conf { ########################################################
  # Contents of site_conf.
  #
  local nvminit n=$'\n'
  #
  nvminit="Unsupported Operating System"
  [[ ${OS} == Darwin ]] && nvminit=/opt/local/share/nvm/init-nvm.sh
  [[ ${OS} == Linux ]] && nvminit=~/.nvm/nvm.sh
  file_header
  printf '%s\n' \
  "# TCP port and TCP/IP address (hostname) of the http-server" \
  "# providing the Antora Site on your local computer." \
  "# (usually this does not need to be changed.)" \
  "HTTP_ADDR=localhost" \
  "HTTP_PORT=8000${n}" \
  "# After generating the Antora site, automatically open your" \
  "# web browser to view the site served by the local http-server." \
  "# Set this to 'yes' or 'no', or 'ask'." \
  "BROWSER_LAUNCH=ask${n}" \
  "# Service to use when publishing the Antora generated site." \
  "# Currently only 'github.io' has been implemented." \
  "SERVICE=github.io${n}" \
  "# OS specific script to initialize the node shell environment." \
  "NVM_INIT=\"${nvminit}\""
}

function git_conf { #########################################################
  # Contents of git.conf
  #
  local n=$'\n'
  #
  file_header
  printf '%s\n' \
  "# Set GIT_URL to your remote GitHub repository used to publish the site" \
  "# (GitHub Pages), e.g.: \"git@github.com:maxJOT/maxjot.github.io.git\"" \
  "GIT_URL=\"git@github.com:maxJOT/maxjot.github.io.git\"${n}" \
  "# Set SITE_URL to the location where your site is published." \
  "SITE_URL=\"https://maxjot.github.io\"${n}" \
  "# SSH_KEYPAIR defines the names of the SSH keys for passwordless" \
  "# secure GitHub authentication (SSH user equivalence)." \
  "# See GitHub Docs – SSH authentication, for more info." \
  "SSH_KEYPAIR=( id_ed25519 id_ed25519.pub )"
} 

function postproc_sh { ######################################################
  # Contents of postproc.sh
  #
  local n=$'\n' a=$'!' a1=$'![1-9][0-9]\\?!' a2=$'                 '
  #
  echo '#!/usr/bin/env bash'
  file_header
  printf '%s\n' \
  '# Requries $1: function to run, $2: function parameter.' \
  "${n}function demo { status_0=\$1; }${n}${n}function callout {" \
  "  # Requires \$1: HTML file to process.${n}  #" \
  '  # Use !A-Z! markers, e.g. !A! anywhere in .adoc documents as a' \
  "  # reference badge, similar to Asciidoc callouts. Post-processing" \
  '  # will convert these markers, e.g. !A!, to letter-badges, just' \
  "  # like Asciidoc callouts, but without any Asciidoc placement" \
  "  # restrictions. The reference markers are invisible to the" \
  "  # \"Copy code\" function. Color and appearance are defined in the" \
  "  # maxJOT.css global stylesheet (.doc .coalpha).${n}  #" \
  "  if grep -q '${a}[A-Z]${a}' \"\$1\"; then" \
  '    local workfile; workfile=$( mktemp )' \
  "    awk '{ for (i = 65; i <= 90; i++) { letter = sprintf(\"%c\", i)" \
  "           marker = \"$a\" letter \"$a\"" \
  '           repl = "<span class=\"coalpha\" " \' \
  '           "data-value=\"" letter "\"></span><b>(" letter ")</b>"' \
  "           gsub(marker, repl) } print" \
  "         }' \"\$1\" > \"\${workfile}\" || { status_0=error; return; }" \
  "    # If output differs, replace file." \
  "    cmp -s \"\$1\" \"\${workfile}\"${n}    case \$? in" \
  '      0) rm -f "${workfile}"; status_0=none ;;' \
  '      1) mv "${workfile}" "$1"; status_0=modified ;;' \
  "      2) echo status_0=error ;;${n}    esac${n}  else" \
  "    status_0=none${n}  fi${n}}${n}\$1 \"\$2\" \"\$3\"${n}## END"
}

function download_yq { ######################################################
  # Download yq depending on OS and architecture.
  #
  local os=$( uname -s ) arch=$( uname -m )
  local yq_bin=""
  #
  echo 
  get_reply "${BD}Let ASSM download and install \`yq' (Y/N)?:${T0}" "N Y"
  case ${REPLY} in
    Y) case ${os} in
         Darwin) [[ ${arch} = x86_64 ]] && yq_bin=yq_darwin_amd64
                 [[ ${arch} = arm64 ]] && yq_bin=yq_darwin_arm64 ;;
          Linux) [[ ${arch} = x86_64 ]] && yq_bin=yq_linux_amd64
                 [[ ${arch} = arm64 ]] && yq_bin=yq_linux_arm64 ;;
       esac
       if [[ -z ${yq_bin} ]]; then
         err1 "Unsupported Operating System." \
           "OS: ${os} on ${arch}" 
         echo; exit 1
       else
         curl -L -o "${SITE_USER_DIR}/yq" \
         "https://github.com/mikefarah/yq/releases/latest/download/${yq_bin}"
         chmod +x "${SITE_USER_DIR}/yq"
       fi ;;
    N) ;;
    *) printf "\nInvalid response, aborting...\n\n"
       exit 1 ;;
  esac
}

function get_build_site_dir { ###############################################
  # YML is complex and difficult to query without a special tool.
  # No tool needed if no output specified (default build/site).
  # Requires $DOCS_SITE_DIR $SITE_USER_DIR $PATH $PLAYBOOK
  # Defines  $BUILD_SITE_DIR
  #
  local output PATH="./:${SITE_USER_DIR}:${PATH}"
  #
  # Check if $PLAYBOOK is a potentially valid Antora playbook file.
  # Lowercase 'site' and 'content' starting at col 0 is mandatory.
  if ! grep -q '^site:' "${PLAYBOOK}" \
    || ! grep -q '^content:' "${PLAYBOOK}"; then
    err1 ${LINENO} "Not a valid playbook file" \
      "File: ${PLAYBOOK}" \
      "Missing sections: site:, content:"
    echo; exit 1
  fi
  #
  # Check if a custom output section exists.
  # Early exit if yq is required but not installed.
  grep -q '^output:' "${PLAYBOOK}" && output=1 || output=0
  if (( output )); then
    if ! command -v yq &> /dev/null; then
      echo
      msg1
      echo
      download_yq
      if ! command -v yq &> /dev/null; then
        err1 ${LINENO} "Command not found." \
          "Command: \`yq'."
        echo; exit 1
      fi
    fi
  fi
  # Try it again with yq installed or playbook adjusted.
  grep -q '^output:' "${PLAYBOOK}" && output=1 || output=0
  if (( output )); then
    # Attempt to extract build directory using yq
    BUILD_SITE_DIR=$( 
      yq e '.output.dir // (.output.destinations[] |
            select(.provider=="fs").path)' ${PLAYBOOK} )      
      # Check if we got a value.
      if [ -z "${BUILD_SITE_DIR}" ]; then
        err1 ${LINENO} "Failure parsing \"output:' section." \
          "File: ${PLAYBOOK}"
        echo; exit 1
      elif [ $( echo "${BUILD_SITE_DIR}" | wc -l ) -gt 1 ]; then
        err1 ${LINENO} "Unsupported \"output:\" directory." \
          "Multiple fs output destinations defined." \
          "File: ${PLAYBOOK}"
        echo; exit 1
      fi
  else
    BUILD_SITE_DIR=build/site  # Default, relative to antora-playbook.yml.
  fi
  # Convert BUILD_SITE_DIR to absolut path.
  BUILD_SITE_DIR=${BUILD_SITE_DIR#./}   # Remove leading ./ if exist.
  if [[ ${BUILD_SITE_DIR} != /* ]]; then
    BUILD_SITE_DIR="${DOCS_SITE_DIR}/${BUILD_SITE_DIR}"
  fi
}

function err2 { #############################################################
  # Empty or missing variable.
  #
  err1 ${LINENO} "Missing or empty variable." \
    "Variable: ${item}" \
    "Source: ${outfile}"
  echo; exit 1
}

function err3 { #############################################################
  # Error in variable content.
  #
  err1 ${LINENO} "Error in variable." \
    "Variable: ${item}" \
    "Source: ${outfile}"
  echo; exit 1
}

function get_git_conf { #####################################################
  # Create git.conf if missing, then source git.conf and
  # verify the variables. Requires $SITE_USER_DIR
  # 
  local outfile="${SITE_USER_DIR}/git.conf"
  local item var_array=( GIT_URL SITE_URL SSH_KEYPAIR )
  # Create if missing.
  [[ ! -e ${outfile} ]] && git_conf > "${outfile}"
  source "${outfile}"
  # Error and Exit if variable is missing or incorrect.
  for item in "${var_array[@]}"; do
    [[ -z ${!item} ]] && err2
  done
}

function get_site_conf { ####################################################
  # Create site.conf if missing, then source site.conf and
  # verify the variables. Requires $SITE_USER_DIR
  #
  local nvminit outfile="${SITE_USER_DIR}/site.conf"
  local item var_array=( HTTP_PORT HTTP_ADDR
                         BROWSER_LAUNCH SERVICE NVM_INIT )
  # Create if missing.
  [[ ! -e ${outfile} ]] && site_conf > "${outfile}"
  source "${outfile}"
  # Error and Exit if variable is missing or incorrect.
  for item in "${var_array[@]}"; do
    [[ -z ${!item} ]] && err2
    case ${item} in
      BROWSER_LAUNCH)
        case ${!item,,} in
          yes) BROWSER_LAUNCH=yes ;;
           no) BROWSER_LAUNCH=no ;;
          ask) BROWSER_LAUNCH=ask ;;
            *) err3 ;;
        esac
        continue ;;
      SERVICE)
        case ${!item,,} in
          github.io) SERVICE=github.io ;;
                  *) err3 ;;
        esac
        continue ;;
      NVM_INIT) [[ ! -e ${!item} ]] && err3 ;;
    esac
  done
} 

function check_certificates { ###############################################
  # Clipboard API (copy code) requires a secure context (HTTPS).
  # Requires $SITE_USER_DIR $HTTP_ADDR
  local cert=${SITE_USER_DIR}/keys/
  mkdir -p ${SITE_USER_DIR}/keys
  if [[ ! -f ${SITE_USER_DIR}/keys/${HTTP_ADDR}_key.pem ]] || \
    [[ ! -f ${SITE_USER_DIR}/keys/${HTTP_ADDR}_cert.pem ]]; then
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout "${SITE_USER_DIR}/keys/${HTTP_ADDR}_key.pem" \
      -out "${SITE_USER_DIR}/keys/${HTTP_ADDR}_cert.pem" \
      -days 3650 -subj "/CN=${HTTP_ADDR}" \
      -addext "subjectAltName=DNS:${HTTP_ADDR}" > /dev/null 2>&1
  fi
  if [[ ! -f ${SITE_USER_DIR}/keys/${HTTP_ADDR}_key.pem ]] || \
    [[ ! -f ${SITE_USER_DIR}/keys/${HTTP_ADDR}_cert.pem ]]; then
    err1 ${LINENO} "Error creating self-signed TLS certificate." \
      "Directory: ${SITE_USER_DIR}/keys"
    exit; exit 1
  fi
}

function init_variables { ###################################################
  # Initialize environment and internal variables for Antora site
  # deployment. Creates $SITE_USER_DIR and appropriate readme.txt
  # as well as creating git.conf and site.conf.
  #
  local outfile build_path 
  #
  # Verify there is a antora-playbook.yml in the current working
  # directory and use the parent directory name as SITE_NAME. 
  if [[ ! -f ${PLAYBOOK} ]] || \
    [[ -L ${PLAYBOOK} ]]; then
    err1 ${LINENO} "File not found." \
      "File: \`${PLAYBOOK}' not found in current directory."
    echo; exit 1
  fi
  DOCS_SITE_DIR=$(pwd -P) 
  DATE_TAG=$( date +%d-%b-%y )   
  SITE_NAME=$( basename "$( pwd -P )" )
  SITE_USER_DIR=~/${IAM%%.*}/${SITE_NAME}
  mkdir -p "${SITE_USER_DIR}"
  get_build_site_dir               # Define BUILD_SITE_DIR
  # Extract relative path to $DOCS_SITE_DIR if possible. 
  build_path=${BUILD_SITE_DIR#${DOCS_SITE_DIR}}
  build_path=${build_path#/}
  SITE_USER_DIR="${SITE_USER_DIR}/${build_path}" # Final $SITE_USER_DIR.
  mkdir -p "${SITE_USER_DIR}"
  if [[ ! -d ${SITE_USER_DIR} ]]; then
    err1 ${LINENO} "Cannot create directory." \
      "Directory: ${SITE_USER_DIR}"
    echo; exit 1
  fi  
  case $( uname -s ) in
    Darwin) OS=Darwin ;;
     Linux) OS=Linux ;;
         *) OS=unknown ;;
  esac
  outfile=~/${IAM%%.*}/readme.txt
  [[ ! -e ${outfile} ]] && readme_txt > "${outfile}" # Readme.txt
  # Create git.conf and site.conf and process user configurable options.
  get_site_conf
  get_git_conf
  # Create postproc.sh
  outfile="${SITE_USER_DIR}/postproc.sh"
  if [[ ! -e ${outfile} ]]; then
    postproc_sh > "${outfile}"
    chmod u+x "${outfile}"
  fi
  # Manage web browser self-signed certificates.
  check_certificates
  # Internal variables.
  GIT_SITE_DIR="${BUILD_SITE_DIR}/.git" # Symlink inside site.
  GIT_SAFE_DIR="${SITE_USER_DIR}/.git" # Actual Git repo.
  DEFUI_DIR="default-ui"
  BUNDLE_URL="https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts"
  BUNDLE_URL="${BUNDLE_URL}/HEAD/raw/build/ui-bundle.zip?job=bundle-stable"
  BUNDLE_SRC="https://gitlab.com/antora/antora-ui-default.git"
  GIT_MIN=2.52
  HTTP_LOG=/tmp/http_server.log
}

function term_init { ########################################################
  # Assign useful terminal sequences that are compatible with any
  # 256-color VGA terminal, if available. There is, however, no
  # ill-effect if the terminal does not - in which case variables 
  # will simply be empty and produce no output. Requires Bash >= 3.
  #
  # Usage:
  #   term_init         : Create variables.
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

term_init

# Verify Bash is version 4 or later.
#
if [[ ! ${BASH_VERSINFO[0]:-0} -ge 4 ]]; then
  err1 ${LINENO} "Bash version 4 or later required." # read -t 0.1
  echo; exit 1
fi

function help { #############################################################
  echo "Usage:
  ${IAM}
  ${IAM} [OPTIONS] [MENU_OPTION]"
  echo
  echo "Options:
  -c, --config      Show configuration variables.
  -h, --help        Help
  -m, --main        Select MENU_OPTION from the Main menu.
  -p, --publish     Select MENU_OPTION from the Publish menu.
  -v, --version     Show version and licensing info."
  echo
  echo "Examples:
  ${IAM}           Show Menus (default).
  ${IAM} -m 1      Select option 1 from the Main menu.
  ${IAM} -cp 3     Select option 3 from the Publish menu and
                    display the configuration screen."
  echo
  echo "Description:
  The Antora Single Site Manager streamlines Antora site development
  and manages the complete workflow from building to publishing. It
  offers simple menu options to automate complex site management tasks,
  preventing common configuration pitfalls, including Git deployment.

  ASSM creates a configuration directory under the user's home directory
  to store customization options for HTTPS settings, security keys, and
  Git specifics. See readme.txt and use the -c option for details."
}

function version { ##########################################################
  echo "Version ${IAM[1]}"
  echo
  echo "Copyright (c) 2024-2026 maxJOT. All Rights Reserved."
  echo "Free to use but not for sale. No redistribution of modified"
  echo "copies. https://maxjot.github.io/maxJOT/license_maxjot.html"
}

function mute { #############################################################
  # Hide cursor, disable terminal echo, disable ctrl/s/q/c/d.
  # Stop user/keyboard interference while rendering screen output.
  #
  sav_0=$(stty -g </dev/tty)  # Save tty settings. Global scope.
  stty -echo -icanon -ixoff intr '?' eof '?' </dev/tty
  read -r -t 0.1 -s -- 
  printf ${HC}
} 

function umute { ############################################################
  # Restore terminal state prior to mute().
  #
  stty ${sav_0} </dev/tty
  printf ${RC}
}

function get_reply { ########################################################
  # Arguments: $1=prompt $2=valid options (optional).
  #
  local tries=0 option prompt answer indent
  local sav=$(stty -g </dev/tty)
  local hc=$(tput civis) rc=$(tput cnorm) u1=$(tput cuu1) ed=$(tput ed)
  local b1=$(tput bold; tput setaf 1) t0=$(tput sgr0)
  #
  if [[ ! ${BASH_VERSINFO:-0} -ge 4 ]]; then
    printf "\n${b1} \`get_reply' requires Bash 4 or later.${t0}\n"
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
    options=( ${2^^} )
    default=${options[0]}
    prompt="$1 [${default}]"
  fi
  #
  while true; do    
    # Flush the keyboard buffer.
    stty -icanon -echo </dev/tty
    read -r -t 0.1 -s --
    # Disable ctrl/s/q/c/d and set stdin to interactive mode.
    stty icanon echo -ixoff intr '?' eof '?' </dev/tty
    echo -en "${rc}${prompt}${ed}"
    read -r -e -n 1 -p " " answer
    answer=${answer^^}         # Convert to uppercase.
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

function box { ##############################################################
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
    4) fb=$( tput setaf 7; tput setab 4 ) ;; # white/blue
    0) fb=$( tput setaf 7; tput setab 0 ) ;; # black/white
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

function shortvar { #########################################################
  # Shorten a $1 so it does not exceed $2 length.
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

function approve_config { ###################################################
  # Required functions: term_init, box, get_reply, init_variables.
  #
  init_variables
  echo
  function orange { box 4 "${C3}$1" 1; box 4 "$2"; }
  mute # stop user input and cursor display while drawing the box.
  box 4 box_top
  box 4 "${BD}Please verify before continuing."
  box 4 box_middle
  shortvar "${PLAYBOOK}" 47
  orange "PLAYBOOK       " "${shortvar_0}"
  shortvar "${NVM_INIT}" 47
  orange "NVM_INIT       " "${B3}${shortvar_0}"
  shortvar "${DOCS_SITE_DIR}" 47
  orange "DOCS_SITE_DIR  " "${shortvar_0}"
  shortvar "${BUILD_SITE_DIR}" 47
  orange "BUILD_SITE_DIR " "${shortvar_0}"
  shortvar "${SITE_USER_DIR}" 47
  orange "SITE_USER_DIR  " "${shortvar_0}"
  shortvar "${GIT_URL}" 47
  orange "GIT_URL        " "${B3}${shortvar_0}"
  shortvar "${SITE_URL}" 47
  orange "SITE_URL       " "${B3}${SITE_URL}"
  orange "SERVICE        " "${B3}${SERVICE}"
  orange "HTTP_PORT      " "${B3}${HTTP_PORT}"
  orange "HTTP_ADDR      " "${B3}${HTTP_ADDR}"
  orange "HTTP_LOG       " "${HTTP_LOG}"
  orange "BROWSER_LAUNCH " "${B3}${BROWSER_LAUNCH}"
  box 4 box_middle
  shortvar "${SITE_USER_DIR}" 47
  box 4 "Edit files in ${B3}${shortvar_0}" 
  box 4 "to make configuration changes."
  box 4 box_bottom
  echo 
  umute # Restore terminal state prior to mute().
  unset -f orange
  # Don't pause when in non-menu mode.
  if (( config != 1 )); then
    get_reply "      Press any key to continue"
  fi 
}

function version_compare { ##################################################
  # Requries: $1=any verison string, e.g. 2.52.0
  #           $2=any version string, e.g. 2.54
  # Returns 0 if $1 is higher or equal than $2
  # Returns 1 if $1 is less than $2
  awk -F. '{ for (i=1;i<=NF;i++) v[NR,i]=$i+0; n=NF>n?NF:n }
             END { for (i=1;i<=n;i++) {
               if (v[1,i] > v[2,i]) exit 0
               if (v[1,i] < v[2,i]) exit 1
             } exit 0 }' <<< $1$'\n'$2
}

function check_git { ########################################################
  # Check git version requirements and githup passwordless SSH.
  # Attempt recovery of archived keys if possible.
  #
  if [[ ! -e "${SITE_USER_DIR}/keys/sshkeys.tar" ]]; then
    function yellow { box 0 "${B3}$1" 1; box 0 "$2"; }
    box 0 box_top
    yellow "WARNING!" "No backup exists."
    yellow "        " "Automatic repair/recovery is unavailable."
    box 0 box_bottom
    unset -f yellow
    echo
  fi
  local git_version=$( git --version | awk '{print $3}' )
  version_compare ${git_version} ${GIT_MIN}
  if [[ $? -ne 0 ]]; then
     printf "${BD}Warning: Git release less than ${GIT_MIN}${T0}\n"
  fi
  # Verify git login.
  ssh-keygen -F github.com 2>/dev/null | grep -q ecdsa
  if [[ $? -ne 0 ]]; then
    mkdir -p ~/.ssh
    ssh-keyscan -4 -t ecdsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    if [[ $? -eq 0 ]]; then
      chmod 644 ~/.ssh/known_hosts
      echo "Github host key updated successfully."
    else
      err1 ${LINENO} "Error retrieving Github host key.${T0}"
      echo; exit 1
    fi
  fi
  if [[ ! -e ~/.ssh/${SSH_KEYPAIR[0]} ]] \
     || [[ ! -e ~/.ssh/${SSH_KEYPAIR[1]} ]]; then
    mkdir -p ~/.ssh
    ( cd ~/.ssh
      tar xf "${SITE_USER_DIR}/keys/sshkeys.tar" > /dev/null 2>&1 )
    if [[ $? -eq 0 ]]; then
      echo "${BD}Missing Github login keys restored successfully.${T0}"
    else
      err1 ${LINENO} "Backup not found." \
        "File: ${SITE_USER_DIR}/keys/sshkeys.tar" \
        "Error restoring missing Github login keys."
      echo; exit 1
    fi
  fi
  echo "GIT URL: ${B6}${GIT_URL}${T0}" 
  git ls-remote "${GIT_URL}" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "Git and Github login verified successfully."
    mkdir -p "${SITE_USER_DIR}"
    ( cd ~/.ssh
      tar cf "${SITE_USER_DIR}/keys/sshkeys.tar" ${SSH_KEYPAIR[@]} )
    echo "${BD}Github recovery key backup updated.${T0}"
    echo "${SITE_USER_DIR}/keys/sshkeys.tar"
  else
    err1 ${LINENO} "Github SSH login failure."
    echo; exit 1
 fi
}

function git_prepare { ######################################################
  # The purpose of this function is to protect an valid Git directory
  # from being removed by an Antora generate --clean command. The function
  # will verify and relocate a current Git directory if necessary, and
  # provide appropriate feedback if this cannot be accomplished.
  #
  local dir target
  # Remove invalid or empty Git directories.
  for dir in "${GIT_SITE_DIR}" "${GIT_SAFE_DIR}"; do
    if [[ -d ${dir} || -L ${dir} ]]; then
      if [[ ! -f ${dir}/HEAD \
        && ! -d ${dir}/objects \
        && ! -d ${dir}/refs ]]; then
        echo
        rm -rf "${dir}"
        if ! [[ -d ${dir} ]]; then
          echo "${BD}Removed empty/invalid Git directory.${T0}"
          echo "Directory: ${dir}"
        else
          err1 ${LINENO} "Error removing empty invalid Git directory." \
            "Directory: ${dir}"
          echo; exit 1
        fi
      fi
    fi
  done
  # Check/Update current state.
  site_git_exists=0; site_git_is_symlink=0; build_git_exists=0
  [[ -e ${GIT_SITE_DIR} ]] && site_git_exists=1
  [[ -L ${GIT_SITE_DIR} ]] && site_git_is_symlink=1
  [[ -d ${GIT_SAFE_DIR} ]] && build_git_exists=1
  # No Git directory exists, nothing to be done. 
  # Function publish_github_io will handle this.
  if (( ! site_git_exists && ! build_git_exists )); then
    status_0=0
    return 0
  fi
  # GIT_SITE_DIR exists and is a symlink
  if (( site_git_exists && site_git_is_symlink )); then
    target=$( cd "${GIT_SITE_DIR}" && pwd -P )
    if [[ ${target} == ${GIT_SAFE_DIR} ]]; then
        status_0=0
        return 0 # Current .git setup is valid.
    else
      err1 ${LINENO} "Unexpected Git symlink." \
        "Symlink: ${GIT_SITE_DIR}" \
        "Target: ${target}" \
        "Expected: ${GIT_SAFE_DIR}"
      echo; exit 1
    fi
  fi
  # GIT_SITE_DIR exists and is a real directory.
  if (( site_git_exists && ! site_git_is_symlink )); then
    if (( build_git_exists )); then
      err1 ${LINENO} "Unexpected Git directories." \
        "Directory: ${GIT_SAFE_DIR}" \
        "Directory: ${GIT_SITE_DIR}"
      echo; exit 1
    else
      mv "${GIT_SITE_DIR}" "${GIT_SAFE_DIR}"
      ln -s "${GIT_SAFE_DIR}" "${GIT_SITE_DIR}"
      printf "\n${B3}Git relocated:${T0}\n"
      echo "Symlink: ${GIT_SITE_DIR}"
      echo "Target: ${GIT_SAFE_DIR}"
      status_0=0
      return 0 # Valid Git configuration.
    fi
  fi
  # GIT_SITE_DIR missing but valid GIT_SAFE_DIR exists.
  if (( ! site_git_exists && build_git_exists )); then
    ln -s "${GIT_SAFE_DIR}" "${GIT_SITE_DIR}"
    printf "\n${B3}Git Symlink recovered:${T0}\n"
    echo "Symlink: ${GIT_SITE_DIR}"
    echo "Target: ${GIT_SAFE_DIR}"
  fi
  status_0=0
}

function init_antora { ######################################################
  # Set up antora environment and cd into DOCS_SITE_DIR, which
  # is the default location for local node installations.
  # 
  local http_server=0
  #
  if [[ -d "${DOCS_SITE_DIR}" ]]; then
    source "${NVM_INIT}"
    cd "${DOCS_SITE_DIR}"
  else
    err1 ${LINENO} "Directory does not exist." \
      "Directory: ${DOCS_SITE_DIR}"
    echo; exit 1    
  fi

  # Check node installation prerequisites.
  #
  npm list http-server >/dev/null 2>&1 && http_server=1 # installed.
  if [[ ${http_server} -eq 0 ]]; then
    function red { box 0 "${B1}$1" 1; box 0 "$2"; }
    echo
    mute # stop user input and cursor display while drawing the box.
    box 0 box_top
    red "ERROR!" "${BD}Missing node installation pre-requisites."
    box 0
    [[ ${http_server} -eq 0 ]] && box 0 "http-server not installed."
    box 0 box_bottom
    umute # Restore terminal state prior to mute().
    unset -f red 
    err1 ${LINENO} "Node installation failure."
    echo; exit 1
  fi
}

function install_ui_bundle { ################################################
  local out="${DOCS_SITE_DIR}/${DEFUI_DIR}/ui-bundle_${DATE_TAG}.zip"
  #
  mkdir -p "${DOCS_SITE_DIR}/${DEFUI_DIR}"
  if [[ -f ${out} ]]; then
    err1 ${LINENO} "File already exists." \
      "File: ${out}"
    status_0=1
    echo
  else
    curl -L "${BUNDLE_URL}" -o "${out}"
    if [[ $? -eq 0 ]]; then
      echo
      echo "Download successful."
      echo -e "File: ${out}\n"
      echo -e "${BD}Remember to update antora-playbook.yml${T0}\n"
      status_0=0
    else
      err1 ${LINENO} "Error downloading." \
        "File: ${out}"
      echo; exit 1
    fi
  fi
}

function clone_ui_src { #####################################################
  # Fetch the current default Antora UI source from github.
  # Create a new diretory with a current date tag and verify it is empty.
  #
  local out source_dir="${DOCS_SITE_DIR}/${DEFUI_DIR}/source/${DATE_TAG}"
  if [[ -d "${source_dir}" ]]; then
    out=$( find "${source_dir}" -type d -maxdepth 0 -empty )
    if [[ "${out}" != "${source_dir}" ]]; then
      err1 ${LINENO} "Directory not empty." \
        "Directory: ${source_dir}"
      echo; exit 1
    fi
  else
     mkdir -p "${source_dir}" \
       || { err1 ${LINENO} "Error creating directory." \
              "Directory: ${source_dir}"
            echo; exit 1; }
  fi
  # Clone the Antora UI.
  git clone "${BUNDLE_SRC}" "${source_dir}" 
  if [[ $? -ne 0 ]]; then
    err1 ${LINENO} "Error fetching git repository."
    echo; exit 1
  else
    printf "\nSource directory:\n"
    printf "${B3}${source_dir}${T0}\n\n"
    status_0=0
  fi
}

function build_antora { #####################################################
  # Exectuing Antora from within a valid DOCS_SITE_DIR always works,
  # regardless of Antora being installed globally ($HOME) or locally.
  # Build the site and enable Antora rebuild watcher for localhost
  # according to LIVE_RELOAD variable.
  #
  init_antora
  cd "${DOCS_SITE_DIR}"
  # Antora requires a .git directory.
  if [[ ! -d .git ]]; then
    printf "\n${B3}Warning:${T0} ${BD}Directory not found.${T0}\n"
    printf "Directory: ${DOCS_SITE_DIR}/.git\n\n"
    box 0 box_top
    box 0 "${B3}Note:${T0} The Git repository is used for remote source" 1
    box 0 "management"
    box 0 "      of the Antora software and is not related to" 1
    box 0 "publishing" 
    box 0 "      the generated Antora site. If this is a local-only Antora"
    box 0 "      installation, the .git repository can simply be recreated"
    box 0 "      without any issues."
    box 0 box_bottom
    echo
    get_reply "${BD}Create the local Git repository?${T0} :" "Y N"
    case "${REPLY}" in
      Y) git init -q
         git commit --allow-empty -m init ;;
      N) printf "\nExiting...\n\n"
         exit 0 ;;
      *) printf "\nInvalid response, aborting...\n\n"
         exit 1 ;;
    esac     
  fi
  echo -n "Building site... "
  npx antora $* "${PLAYBOOK}"
  return $?
}

function get_tcp_pid { ######################################################
  # Return the pid of given tcp/ip listening port
  # Requires $1=port
  #
  local pid dump
  # Check the origin of lsof.
  dump=$( readlink "$( which lsof )" 2>/dev/null )
  if [[ ${dump} == *busybox* ]]; then
    pid=$( netstat -tulpn 2>/dev/null \
          | grep LISTEN \
          | grep ":$1" \
          | awk '{ split($7,a,"/"); print a[1]; exit }' )
  else
    pid=$( lsof -ti tcp:$1 -sTCP:LISTEN 2>/dev/null )
  fi
  [[ -z ${pid} ]] && echo 0 || echo ${pid}
}

function stop_http_server { #################################################
  pid=$( get_tcp_pid ${HTTP_PORT} )
  if [ ${pid} -ne 0 ]; then
    echo "Web server currently running."
    echo "Killing process ${pid}"
    kill ${pid}
    # Verify
    pid=$( get_tcp_pid ${HTTP_PORT} )
    if [[ ${pid} -eq 0 ]]; then
      echo "Process ${pid} killed successfully."
      echo "Removing logfile: ${HTTP_LOG}"
      rm "${HTTP_LOG}"
      status_0=0
    else
      err1 ${LINENO} "Error stopping process ${pid}."
      echo; exit 1
    fi
  else 
    echo "Web server already shutdown."
    status_0=0
  fi
}

function start_http_server { ################################################
  # Start the http-server and return success or failure.
  #
  local line pid=$( get_tcp_pid ${HTTP_PORT} )
  [[ ${pid} -ne 0 ]] && stop_http_server # Always stop prior to starting.
  echo "Starting http-server..."
  # Create a new logfile.
  init_antora
  # Start http-server in background with no-store,
  # no-cache, must-revalidate attributes.
  # Note: liverload interlinks http-server, and will automatically
  #       reload the page when file changes occur in the build/site
  #       directory. You still need to connect to port 8000.
  nohup npx http-server "${BUILD_SITE_DIR}" -S \
          -C "${SITE_USER_DIR}/keys/${HTTP_ADDR}_cert.pem" \
          -K "${SITE_USER_DIR}/keys/${HTTP_ADDR}_key.pem" \
          -a ${HTTP_ADDR} -p ${HTTP_PORT} \
          -c -1 > "${HTTP_LOG}" 2>&1 &
  echo "Server logfile: ${HTTP_LOG}"
  # Wait for success or timeout.
  start_time=$(date +%s)
  while true; do
    if grep -qi "${HTTP_ADDR}:${HTTP_PORT}" "${HTTP_LOG}"; then
      echo ${C2}
      cat "${HTTP_LOG}"
      echo ${T0}
      break
    fi
    now=$(date +%s)
    if (( now - start_time > 10 )); then
      echo ${C1}
      cat "${HTTP_LOG}"
      echo ${T0}
      err1 ${LINENO} "Failure starting http-server" \
        "Timeout waiting for ${HTTP_ADDR}:${HTTP_PORT}" \
        "Logfile: ${HTTP_LOG}" 
      echo; return 1
      status_0=1
    fi
    sleep 1
  done
  status_0=0
  return 0
}

function open_browser { #####################################################
  # Opens a tab/window using the default web browser. 
  # Requires $BROWSER_LAUNCH
  #
  local cmd
  #
  case ${OS} in 
    Darwin) cmd="open https://${HTTP_ADDR}:${HTTP_PORT}" ;;
     Linux) cmd="python -m webbrowser https://${HTTP_ADDR}:${HTTP_PORT}" ;;
         *) cmd="echo https://${HTTP_ADDR}:${HTTP_PORT}" ;;
  esac
  case ${BROWSER_LAUNCH} in
    yes) ${cmd} >/dev/null 2>&1
         echo; status_0=0 ;;
    ask) box r box_top
         box r "Use Shift + Reload Page to bypass the web-browser cache."
         box r box_bottom
         echo
         get_reply \
           "${BD}Open URL in web browser? (Y/N)${T0}:" "N Y"
         case "${REPLY}" in
           Y) ${cmd}
              echo; status_0=0 ;;
           N) echo; status_0=0 ;;
           *) printf "\nInvalid response, exiting...\n"
              echo; status_0=0 ;;
         esac ;;
      *) echo; status0=0 ;;
  esac
}

function define_menu_options { ##############################################
  # We need to define the menu_number variables in menu and non-menu mode.
  #
  MENU_M1="${BD}(1) Build Site"
  MENU_M2="${B2}(2) Build Site & Restart Local Server"
  MENU_M3="${B3}(3) Build Site (Reset) & Restart Local Server"
  MENU_M4="${B1}(4) Stop Local Server"
  MENU_M5="${B6}(5) Start Local Server"
  MENU_M6="${C3}(6) Publish Web Site Menu (github.io)"
  MENU_M8="(8) Clone Default Antora UI Source"
  MENU_M9="(9) Install Default Antora UI Bundle"
  MENU_M0="(0) Init NVM Shell"
  MENU_P1="${BD}(1) Verify Git and Github SSH Login"
  MENU_P2="${B5}(2) Analyze Without Publishing"
  MENU_P3="${B2}(3) Publish Site Updates"
  MENU_P4="${B3}(4) Complete Site Redeploy (Reset Update History)"
}

function publish_github_io { ################################################
  if [[ ${publish} -ne 1 ]]; then
    echo
    mute # stop user input and cursor display while drawing the box.
    box 4 box_top
    box 4 " SITE_URL: ${B6}${SITE_URL}"
    box 4 " GIT_URL:  ${B6}${GIT_URL}"
    box 4 box_middle
    box 4 " ${MENU_P1}"
    box 4 " ${MENU_P2}"
    box 4 " ${MENU_P3}"
    box 4 " ${MENU_P4}"
    box 4
    box 4 " (E) Exit"
    box 4 box_bottom
    umute # Restore terminal state prior to mute().
    echo
    get_reply "      ${BD}Press menu option:${T0}" "E 1 2 3 4"
    [[ $? -eq 3 ]] && status_0=1
    local menu_opt_0=${REPLY}
    echo
  fi
  case ${menu_opt_0} in
    1) printf "\n${MENU_P1}${T0}\n\n"
       git_prepare
       check_git
       status_0=0
       return ;;
    2) printf "\n${MENU_P2}${T0}\n\n" ;;
    3) printf "\n${MENU_P3}${T0}\n\n" ;;
    4) printf "\n${MENU_P4}${T0}\n\n" ;;
    E) printf "\nExiting...\n"
       status_0=1
       return ;;
  esac
  # The remaining menu options (2,3,4) require to be executed
  # from within the site directory. It must be an absolute path.
  # Antora also requires a _ directory for UI assets to function.
  if [[ -d "${BUILD_SITE_DIR}/_" ]]; then
    echo "Site directory: ${B3}${BUILD_SITE_DIR}${T0}"
  else
    err1 ${LINENO} "Directory does not exit." "${BUILD_SITE_DIR}/_"
    echo; exit 1
  fi
  #
  cd "${BUILD_SITE_DIR}" # Critical.
  # A valid Antora site requires a _ directory for UI assets to function.
  # It should also contain 404.html.
  if [[ ! -f "${BUILD_SITE_DIR}/404.html" ]]; then
    err1 ${LINENO} "File not found: 404.html" \
      "Directory: ${BUILD_SITE_DIR}/_" \
      "No site has been generated, yet." 
    echo; exit 1
  fi
  # Always ignore .DS_Store (macos) and create .nojekyll
  # Applies to menu option 2, 3 and 4.
  touch .nojekyll # Required for Github/Antora
  echo ".DS_Store" > .gitignore # Files to ignore
  #
  case ${menu_opt_0} in
    2) git_prepare
       local tmp_index file_diff_status file_diff_names
       local f kb git_history=1
       # We want git to operate against an existing .git directory, if
       # available. In any case, simulate the update given the current
       # options and project upload statistics. If no .git directory
       # exists, show statitics for a full site upload.
       if [[ ! -d .git ]]; then
         git_history=0 # Final message marker that .git was not found.
         git config --global init.defaultBranch main
         git init -q
         git read-tree --empty
         git add -A
         file_diff_status=$( git diff --name-status --cached )
         file_diff_names=$( git diff --cached --name-only --diff-filter=AM )
         rm -rf .git
       else
         # Stage all files in the temp index directory.
         tmp_index=$(mktemp)
         GIT_INDEX_FILE="${tmp_index}" git read-tree --empty
         GIT_INDEX_FILE="${tmp_index}" git add -A
         file_diff_status=$( GIT_INDEX_FILE="${tmp_index}"\
           git diff --name-status --cached )
         file_diff_names=$( GIT_INDEX_FILE="${tmp_index}"\
           git diff --cached --name-only --diff-filter=AM )
         rm -rf "${tmp_index}"
       fi
       if [[ -z "${file_diff_status}" ]]; then
         echo "${BD}No changes detected since last site publish.${T0}"
         status_0=0
         return
       else
         echo
         get_reply \
           "${BD}List changed files since last publish? ${T0}:" "N Y"
         case "${REPLY}" in
           Y) printf "\n${file_diff_status}\n" ;;
           N) echo ;;
           *) printf "\nInvalid response, exiting...\n"
              status_0=1
              return ;;
         esac
       fi
       printf "\n${BD}Summary of files that would be published:${T0}\n\n"
       awk '{count[$1]++} END { for (k in count) 
             printf "%s: %d\n", k, count[k] }' <<< "${file_diff_status}"
       kb=$( echo "${file_diff_names}" |
         while IFS= read -r f; do du -k -- "$f"; done |
         awk '{s+=$1} END {print s}' )
       echo "Total space: ${kb} KB"
       status_0=0
       if [[ ${git_history} -eq 0 ]]; then
         printf "\n${B3}Warning:${T0} ${BD}Directory not found.${T0}\n"
         echo "Directory: ${BUILD_SITE_DIR}/.git"
         echo
         box 0 box_top
         box 0 "${B3}Note:${T0} ${BD}The .git directory does not exist."
         box 0 "An analysis compared to previous commits or repository could"
         box 0 "not be performed. This is expected if the site has not yet"
         box 0 "been published, or the .git directory was deleted on purpose."
         box 0 box_bottom
         status_0=1
       fi
       return ;;
  esac
  # Continue with remaining menu options 3 and 4.
  get_reply "${BD}Are you sure?${T0}:" "N Y"
  case "${REPLY}" in
    Y) ;;
    N) printf "\nExiting...\n"
       status_0=1
       return ;;
    *) printf "\nInvalid response, exiting...\n"
       status_0=1
       return ;;
  esac     
  # Always recover .git if possible (applies to option 3 and 4).
  git_prepare  
  case ${menu_opt_0} in
    3) if [[ ! -d .git ]]; then
         err1 ${LINENO} "Git directory does not exist." \
           "Directory: GIT_SITE_DIR"
         echo
         box 0 box_top
         box 0 "${B3}Note:${T0} ${BD}The .git directory cannot be found."
         box 0 "You may restore the directory from backup, or choose the"
         box 0 "menu option to perform a complete redeploy."
         box 0 box_bottom
         status_0=1
         echo; return
       else
         git config --global init.defaultBranch main
         git init -q
         git read-tree --empty
         git add -A
         git commit -m "General update"
         git remote get-url origin >/dev/null 2>&1 \
           || git remote add origin "${GIT_URL}"
         git push origin main
         [[ $? -eq 0 ]] && status_0=0
         return
       fi ;;
    4) git_prepare     
       if [[ -d .git ]]; then
         echo
         echo "${BD}Existing .git directory appears to be valid.${T0}"
         echo "GIT directory: ${B3}${GIT_SAFE_DIR}${T0}"
         echo
         get_reply "${BD}Really erase? Are you sure?${T0}:" "N Y"
         case "${REPLY}" in
           Y) rm -rf "${GIT_SITE_DIR}"
              rm -rf "${GIT_SAFE_DIR}" ;;
           N) printf "\nExiting...\n"
              status_0=1
              return ;;
           *) printf "\nInvalid response, exiting...\n"
              status_0=1
              return ;;
         esac
       fi
       mkdir -p "${GIT_SAFE_DIR}"
       ln -sf "${GIT_SAFE_DIR}" "${GIT_SITE_DIR}"
       echo
       git init
       git add -A
       git commit -m "Site redeploy"
       git branch -M main
       git remote add origin "${GIT_URL}"
       git push -f origin main
       [[ $? -eq 0 ]] && status_0=0
       return ;;
  esac
}

function post_process { #####################################################
  # Requries $1 - postproc.sh function name $2 task (depending).
  # Read antora.yml to get single stream of text separated by comma,
  # regardless of YAML format. Then extract the component name, which
  # is the same name as the directory where to find all AsciiDoc to HTML
  # converted pages.
  #
  local after_name content component_name search_dir status
  local count=0 mod=0
  #
  content=$( tr '\n\r' ',' < ${DOCS_SITE_DIR}/antora.yml )
  after_name=${content#*name:}
  after_name=${after_name# }   # Remove leading space if present.
  component_name=$( cut -d, -f1 <<< ${after_name} )
  search_dir="${BUILD_SITE_DIR}/${component_name}"
  echo
  echo -en "Post processing...${T0}\r"
  target=$( find "${search_dir}" \
            -iname "_attachments" -prune -o -iname '*.html' -print )
  # wc will count the number of newlines.
  if [[ -n ${target} ]]; then
    items=$( wc -l <<< ${target} | awk '{printf $1}' )
    echo "${BD}Post processing found ${items} HTML files.${T0}"
    while IFS= read -r file || [[ -n ${file} ]]; do
      source ${SITE_USER_DIR}/postproc.sh $1 "${file}" $2
      if [[ ${status_0} == error ]]; then
        err1 ${LINENO} "Error processing file." \
          "File: ${file}"
        echo; exit 1
      elif [[ ${status_0} == modified ]]; then
        (( mod++ )) # Number of files modifed.
      fi
      (( count++ ))
      echo -en "${B3}Processing ${count} of ${items} files${T0}\r"
    done <<< "${target}"
    echo "${BD}Post processing completed. ${mod} files modified.${T0}"
  else
    echo "${BD}No HTML files found.${T0}"
    status_0=0
    return
  fi
}

# ----
# MAIN
# ----
# Process user specified command line options. Allow valid options to
# be at any position, even bundled, or at the end of the command, as
# well as duplicate options. Since 'shift' won't work here, we create
# and alter a copy of args $@, and consolidate later.
#
declare -a args=()
help=0 version=0 config=0 main=0 publish=0 round=0 number=undefined
file=""

# First rule out single-dash long options. Word matching is the trick here.
# 
for i in "$@"; do
  if grep -iqwE -- 'onfig|ublish|ersion|ain|elp' <<< ${i:2}; then
    err1 ${LINENO} "Invalid command line argument." \
      "Invalid long option detected: ${i}" \
      "Try \`${IAM} --help' for more information."
    echo; exit 1
  fi
done

args=("$@") # Copy of current command line arguments.
for i in "${!args[@]}"; do
  case "${args[i]}" in
    -h|--help) help=1; args[i]= ;;
    -v|--version) version=1; args[i]= ;;
    -c|--config) config=1; args[i]= ;;
    -m|--main) main=1; args[i]= ;;
    -p|--publish) publish=1; args[i]= ;;
    [0-9])
      # Do not accept more than one number while
      # loopging through the arguments (round > 1).
      (( round++ ))
      [[ ${round} -eq 1 ]] && { number=${args[i]}; args[i]= ; }
    ;;
    -[hvcmp]*)
      # Process any combination of arguments.
      # Invalid combinations will be addressed later.
      bundle="${args[i]#-}"
      for (( j=0; j<${#bundle}; j++ )); do
        char="${bundle:j:1}"
        case "$char" in
          h) help=1 ;;
          v) version=1 ;;
          c) config=1 ;;
          m) main=1 ;;
          p) publish=1 ;;
        esac
      done
      args[i]=
    ;;
  esac
done

# Check whatever arguments are left for valid filenames.
#
for i in "${!args[@]}"; do
  case "${args[i]}" in
    *.yml) if [[ -e ${args[i]} ]]; then
             file=${args[i]}
             args[i]=
             break; # Exit loop after first valid filename.
           else
             err1 ${LINENO} "File not found." \
               "File: ${args[i]}" \
               "Try \`${IAM} --help' for more information."
             echo; exit 1
           fi ;;
  esac
done

# After all valid arguments have been removed from our args[] copy,
# consolidate the remaining command line argument(s) and replace the
# original command line.
#
declare -a consolidate=()
for item in "${args[@]}"; do
    [[ -n "${item}" ]] && consolidate+=("${item}")
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
  echo; exit 1
done

# Some options are mutually exclusive and cannot be combined.
#
(( help + version + publish + main > 1 )) && combine=invalid
(( help + version > 1 )) && combine=invalid
(( help + version + config > 1 )) && combine=invalid
(( publish + main > 1 )) && combine=invalid

if [[ ${combine} == invalid ]]; then
    err1 ${LINENO} "Invalid combination of command line arguments." \
      "Try \`${IAM} --help' for more information."
    echo; exit 1
fi

if (( main || publish )); then
  if [[ ${number} == undefined ]]; then
    err1 ${LINENO} "Missing menu option." \
      "'main' or 'publish' requires a menu number." \
      "Try \`${IAM} --help' for more information."
    echo; exit 1
  fi
fi
if [[ ${number} != undefined ]]; then
  if (( publish + main != 1 )); then
    err1 ${LINENO} "Missing menu option." \
      "Number requires 'main' or 'publish' keyword." \
      "Try \`${IAM} --help' for more information."
    echo; exit 1
  fi
fi

# Publish or build reqire a menu number within certain ranges.
#
if (( main )); then
  if (( number < 0 || number > 9 )); then
    err1 ${LINENO} "Invalid 'main' menu option." \
      "Valid menu option range: 0 - 9"
    echo; exit 1
  fi
elif (( publish )); then
  if (( number < 1 || number > 4 )); then
    err1 ${LINENO} "Invalid 'publish' menu option." \
      "Valid menu option range: 1 - 4"
    echo; exit 1
  fi
fi

# Finished checking integrity of command line arguments.
# Continue processing the result.
#
(( help )) && { help; echo; exit; }
(( version )) && { version; echo; exit; }


# Define $PLAYBOOK.
#
[[ -z ${file} ]] && PLAYBOOK=antora-playbook.yml || PLAYBOOK=${file}

# Show config and exit if argument is -c only.
#
if (( config )); then
  approve_config
  (( publish + main == 0 )) && { echo; exit; }
fi

# Define menu options in menu and non-menu mode.
#
define_menu_options
#
if (( publish + main == 0 )); then
  # Skip non-menu mode.
  approve_config
  echo
  http_pid=$( lsof -ti tcp:${HTTP_PORT} -sTCP:LISTEN )
  (( ${http_pid} )) && h_msg="${B2}running" || h_msg="${B1}stopped"
  function header { box 4 "${C3}$1" 1; box 4 "$2" 1; box 4 "$3"; }
  mute # stop user input and cursor display while drawing the box.
  box 4 box_top
  ws="          "
  header "${C3} Antora Manager 1.0${ws}"  "http-server: ${h_msg}"
  unset -f header
  box 4 box_middle
  box 4 " ${MENU_M1}"
  box 4 " ${MENU_M2}"
  box 4 " ${MENU_M3}"
  box 4 " ${MENU_M4}"
  box 4 " ${MENU_M5}"
  box 4 " ${MENU_M6}"
  box 4
  box 4 " ${MENU_M8}"
  box 4 " ${MENU_M9}" 
  box 4 " ${MENU_M0}"
  box 4 " (E) Exit"
  box 4 box_bottom
  umute # Restore terminal state prior to mute().
  echo
  get_reply "      ${BD}Press menu option:${T0}" "E 1 2 3 4 5 6 7 8 9 0"
  [[ $? -eq 3 ]] && status_0=1
else
  # Skip menu-mode. 
  init_variables
  [[ ${main} -eq 1 ]] && REPLY=${number}
  if [[ ${publish} -eq 1 ]]; then
    menu_opt_0=${number}
    case ${SERVICE} in
       github.io) publish_github_io ;;
       * ) err1 ${LINENO} "Publishing Service not implemented." \
             "Service: ${SERVICE}"
           echo; exit 1 ;;
    esac
  fi
fi
case "${REPLY}" in
  1) printf "\n${MENU_M1}${T0}\n\n"
     if build_antora && post_process callout; then
       start_http_server && open_browser
     else
       status_0=1
     fi
  ;;
  2) printf "\n${MENU_M2}${T0}\n\n"
     stop_http_server # Stop local http-server prior to building.
     if build_antora && post_process callout; then
       start_http_server && open_browser
     else
       status_0=1
     fi
  ;;
  3) printf "\n${MENU_M3}${T0}\n\n"
     stop_http_server
     git_prepare # Verify .git directory.
     printf "\nSite directory: ${B3}${BUILD_SITE_DIR}${T0}\n\n"
     get_reply \
       "${BD}Erase Site directory, are you sure? ${T0}:" "Y N"
     case "${REPLY}" in
       Y) macos=$( cd ${BUILD_SITE_DIR}; mv -f .DS_Store /tmp &> /dev/null )
          rm -rf "${BUILD_SITE_DIR}"
          if [[ -d "${BUILD_SITE_DIR}" ]]; then
            err1 ${LINENO} "Error deleting directory." \
              "Directory: ${BUILD_SITE_DIR}"
            echo; exit 1
          else
            mkdir -p "${BUILD_SITE_DIR}"
            git_prepare # Restore .git link, if available.
          fi ;;
       N) echo "Continuing without erasing the site directory..." ;;
       *) printf "\nInvalid response, exiting...\n"; exit 1 ;;
     esac
     if build_antora --stacktrace && post_process callout; then
       start_http_server && open_browser
     else
       status_0=1
     fi
  ;;
  4) printf "\n${MENU_M4}${T0}\n\n"
     stop_http_server
  ;;
  5) printf "\n${MENU_M5}${T0}\n\n"
     init_antora
     start_http_server && open_browser
  ;; 
  6) case ${SERVICE} in
       github.io) publish_github_io ;;
       * ) err1 ${LINENO} "Publishing Service not implemented." \
             "Service: ${SERVICE}"
           echo; exit 1 ;;
     esac       
  ;;
  7) echo -e "\n${C6}Time is money - I have time...${T0}"
     echo "${C3}https://buymeacoffee.com/maxjot${T0}"
  ;;
  8) printf "\n${MENU_M8}${T0}\n\n"
     clone_ui_src
  ;;
  9) printf "\n${MENU_M9}${T0}\n\n"
     init_antora
     install_ui_bundle
  ;;
  0) printf "\n${MENU_M0}${T0}\n\n"
     cd "${DOCS_SITE_DIR}"
     printf "${B3}Type 'exit' or CTRL-D when finished${T0}\n\n"
     bash --rcfile <( cat ~/.bash_profile "${NVM_INIT}" ) -i 
  ;;
  E) printf "\nExiting...\n\n"
     status_0=1
  ;;
esac

if [[ ${status_0} -eq 0 ]]; then
  echo; echo "${IAM} completed ${BD}${C2}successfully${T0}."
else
  echo; echo "${IAM} completed."
fi

## END b0fd89e4d58c 
