#!/bin/bash
# File:    wlaninfo.sh
# Author:  maxJOT
# License: Copyright (c) 2024-2026 maxJOT, All Rights Reserved. 
#          Free to use but not for sale. No redistribution of modified
#          copies. See LICENSE file for full terms and disclaimer.
# Date:    06-OCT-2024
# Purpose: This command gathers information about wireless LAN interfaces
#          in the system, such as, bus type, vendor name, transmit power in
#          milliwatts, etc. There's no direct way, for example, to query
#          vendor name by wlan device name, making this a challenging task.
#          This script relies on several external commands, but has been
#          designed with compatibility in mind.
# History: 1.0: 06-OCT-2024
#               initial release.
#          1.1: 06-DEC-2025
#               Report TX and RX speeds, added Wi-Fi standard (802.11),
#               estimated throughput, and connection time.
#               Added compact mode (--compact).
#               More advanced parsing of command line arguments, allowing
#               multiple options in various combinations.
#               Some optimizaion and cosmetic chagnes.
#          1.2: 10-DEC-2025
#               Added support for Wi-Fi 6E.
#               Early exit if not Linux (cannot be ported due to HW).
#               Changing integrity check from crc to md5sum (Linux only).
#               Removed unnecessary Bash 4 nameref-code (outvar)
#               to maintain Bash 3 compatibility.
#               Fixed termination of last item shown in --compact mode.
#               Code optimization and cosmetic changes.

# ----------------------------------
# Preliminary checks and definitions
# ----------------------------------

IAM=${BASH_SOURCE[0]##*/}

# Assign terminal sequences if available - no effect if not.
#
deco=( 'BD:bold' 'C1:setaf 1' 'C6:setaf 6' 'RG:bel' 'T0:sgr0' )
for item in "${deco[@]}"; do
  printf -v "${item%:*}" '%s' "$(tput ${item#*:} 2>/dev/null)"
done

function err1() {
  # Error message. Takes $1 (lineno) $2 (msg). $3 and $3 are optional.
  #
  echo; echo "${IAM} ($1) Aborted."
  echo "${IAM}: ${BD}${C1}$2${T0}${RG}"
  [[ -n $3 ]] && echo "$3"
  [[ -n $4 ]] && echo "$4"
  [[ $1 -ne S ]] && exit 1
}

# Exit if this script has been source-executed.
#
$( return 0 2>&- )
if [[ $? -eq 0 ]]; then
  echo
  \err1 S "Source-execution unsupported."
  # Clean sourced shell environment functions and variables.
  unset IAM deco item cmd BD C1 C3 RG T0 # Clean shell env.
  unset -f err1
  return 1
fi

# Check prerequisites.
#
if [[ $( uname -s ) != Linux ]]; then
  err1 ${LINENO} "Incompatible Operating System." \
    "This program requires Linux and won't function on any other OS."
fi

# Verify Bash is version 3 or later.
if [[ ! ${BASH_VERSINFO:-0} -ge 3 ]]; then
  err1 ${LINENO} "Bash version 3 or later required."
fi

declare -a inst=()
cmd_list="head tail md5sum sed grep awk ip|ifconfig iw lsusb lspci cut
          iwconfig"
for cmd in ${cmd_list}; do
   case "${cmd}" in
     *\|*) command -v "${cmd%|*}" >/dev/null 2>&1 && left=1 || left=0
           command -v "${cmd#*|}" >/dev/null 2>&1 && right=1 || right=0
           if ! (( left )); then
             if ! (( right )); then
               # left and right fallback tool, if not installed.
               inst+=("${cmd%|*}")
             fi
           fi ;;
     *) command -v "${cmd}" >/dev/null 2>&1 || inst+=("${cmd}") ;;
   esac
done
if (( ${#inst[@]} )); then
  err1 ${LINENO} "Unavailable commands." \
    "Please install: ${inst[*]}"
fi

# The following aims to protect from installation or download corruption.
#
crc=( $( head -n -1 ${BASH_SOURCE[0]} | md5sum |cut -c1-12) )
num=( $( tail -1 ${BASH_SOURCE[0]} | grep "^#" ) )
if [[ $1 == ${IAM} ]]; then
  sed -i "s/${num[2]}/${crc[0]}/g" "${BASH_SOURCE[0]}"
  exit 
elif [[ ${crc[0]} != "${num[2]}" ]]; then
  err1 ${LINENO} "Self-integrity check failed." \
     "Please download and install a new copy."
fi

# Store wireless information in an array.
#    0 Vendor              1 Type               2 Kernel Driver
#    3 Power Management    4 MAC Address        5 TCP/IP Address
#    6 SSID                7 Link Quality       8 Signal Strength
#    9 Transmit Power     10 Frequency          11 Channel Number
#   12 Channel Width      13 TX Speed           14 RX Speed
#   15 Wi-Fi Standard     16 Est. Throughput    17 Connection Time
#   18 TCP/IP v6
#
declare -a info_array_0
# Array elements are going to be updated - use n/a as fallback.
#
for i in {0..17}; do
    info_array_0[$i]="n/a"
done

# Maximum length of network device names according the system kernel
# limit (IFNAMSIZ). The variable also sets the left indentation in the
# info_prn output function.
#
IFNAMSIZ=16

function help() {
  echo "Usage: wlaninfo [OPTIONS] [INTERFACE]"  
  echo 
  echo "Options:
  -c, --compact     Show semicolon-separated output.
  -h, --help        Help
  -p, --privacy     Redact sensitive data.
  -v, --version     Show version and licensing info."
  echo
  echo "Interface:
  Optional. The command will show all wireless interfaces by default."
  echo
  echo "Examples:
  wlaninfo          Show all wireless devices, e.g., wlan0, wlan1.
  wlaninfo -p       Redact public TCP/IP address, SSID and MAC address.
  wlaninfo wlan0    Show the wlan0 interface."
  echo
  echo "Description:
  This command retrieves the following wireless information:
  Product name, interface, kernel driver, power management, MAC address,
  TCP/IP address, TCP/IP v6, SSID, link quality, signal strength,
  transmit power, frequency, channel number, channel width, tx speed,
  rx-speed, Wi-Fi standard, estimated throughput, connection time."
}

function version() {
  echo "Version 1.2"
  echo "
  Copyright (c) 2024-2026 maxJOT. All Rights Reserved.
  Free to use but not for sale. No redistribution of modified
  copies. See LICENSE file for full terms and disclaimer."
}

function update_info_array() {
  # $1 info_array_0 index (global, required)
  # $2 variable (required)
  # $3 string (required)
  # Update index_array[$1] to $3 only if $2 is not empty
  # to prevent overwriting the default value (n/a).
  [[ -n $2 ]] && info_array_0[$1]="$3"
}

function get_iw_link() {
  # $1 (required) wireless interface device name.
  #
  local signal_dbm signal ssid txtrate freq_mhz freq
  local protocol rxrate xput uptime

  iw_link=$( iw dev $1 link )
  iw_station=$( iw dev $1 station dump )

  signal_dbm=$( awk '/signal/ { print $2}' <<< ${iw_link} )
  signal=Poor # Default. 
  freq=0 # Default.
  [[ "${signal_dbm}" -ge -80 ]] && signal=Weak
  [[ "${signal_dbm}" -ge -70 ]] && signal=Fair
  [[ "${signal_dbm}" -ge -60 ]] && signal=Good
  [[ "${signal_dbm}" -ge -50 ]] && signal=Excellent
  update_info_array 8 "${signal_dbm}" "${signal_dbm} dBm (${signal})" 

  ssid=$( awk '/^[[:space:]]*SSID/ {print $2}' <<< ${iw_link} )
  # Redact contents of variable $1 if privacy has been enabled.
  [[ ${privacy} -eq 1 ]] && ssid="<privacy>"
  update_info_array 6 "${ssid}" "${ssid}"

  freq_mhz=$( awk '/freq/ {print $2}' <<< ${iw_link} )
  [[ ${freq_mhz%.*} -ge 2400 && ${freq_mhz%.*} -le 2483 ]] && freq=2.4
  [[ ${freq_mhz%.*} -ge 5150 && ${freq_mhz%.*} -le 5825 ]] && freq=5
  [[ ${freq_mhz%.*} -ge 5925 && ${freq_mhz%.*} -le 7125 ]] && freq=6
  update_info_array 10 "${freq}" "${freq:-TBD} GHz (${freq_mhz})"

  protocol=$( awk '/tx bitrate/ {print}' <<< ${iw_link} )
  txrate=$( awk '{print $3}' <<< ${protocol} )
  update_info_array 13 "${txrate}" "${txrate} MBit/s"
  case "${protocol}" in
    *EHT*) update_info_array 15 "${protocol}" "802.11be (Wi-Fi 7)" ;;
    *HE*) if [[ "${freq}" == 6 ]]; then
            update_info_array 15 "${protocol}" "802.11ax (Wi-Fi 6E)"
          else
            update_info_array 15 "${protocol}" "802.11ax (Wi-Fi 6)"
          fi ;;
    *VHT*) update_info_array 15 "${protocol}" "802.11ac (Wi-Fi 5)" ;;
    *OFDM*) update_info_array 15 "${protocol}" "802.11g" ;;
    *DSSS*|*CCK*) update_info_array 15 "${protocol}" "802.11b" ;;
    *) if [[ "${protocol}" == *MCS* ]]; then
         update_info_array 15 "${protocol}" "802.11n (Wi-Fi 4)"
       fi ;;
  esac

  # Next records require station dump.

  rxrate=$( awk '/rx bitrate/ {print $3}' <<< ${iw_station} )
  update_info_array 14 "${rxrate}" "${rxrate} MBit/s"

  xput=$( awk '/throughput/ {print $NF}' <<< ${iw_station} )
  xput=${xput%%.*} # Extract interger number.
  update_info_array 16 "${xput}" "${xput} MBit/s"

  uptime=$( awk '/connected/ {print $3}' <<< ${iw_station} )
  update_info_array 17 "${uptime}" "${uptime} Seconds"
}

function get_iw_info() {
  # $1 (required) wireless interface device name.
  # Get information from iw
  #
  local txpower channel width

  iw_info=$( iw dev $1 info )

  txpower=$( awk '/txpower/ {print $2}' <<< ${iw_info} )
  if [[ ${txpower%.*} -eq 0 ]]; then
    txpower=0
  else
    # Convert dbm to milliwatts using awk and round accordingly.
    #
    txpower=$( awk -v dbm="${txpower}" 'BEGIN { print 10^(dbm / 10) }' )
    txpower=$( awk -v val="${txpower}" 'BEGIN { print int(val + 0.5) }' )
  fi
  update_info_array 9 "${txpower}" "${txpower} mW"

  channel=$( awk '/channel/ {print $2}' <<< ${iw_info} ) 
  update_info_array 11 "${channel}" "${channel}"

  width=$( awk -F'width:' '/width:/ {print $2}' <<< ${iw_info} )
  width=$( awk '{print $1}' <<< ${width} )
  update_info_array 12 "${width}" "${width} MHz"
}

function get_iwconfig() {
  # $1 (required) wireless interface device name.
  # Get additional info from iwconfig, if installed.
  #
  local power quality

  iw_config=$( iwconfig $1 )

  power=$( awk -F':' '/Power Management/ {print $2}' <<< ${iw_config} )
  update_info_array 3 "${power}" "${power}"

  quality=$( awk -F'=' '/Link Quality/ {print $2}' <<< ${iw_config} )
  quality=$( awk '{print $1}' <<< ${quality} )
  update_info_array 7 "${quality}" "${quality}"
}

function get_sys() {
  # $1 (required) wireless interface device name.
  # Determine device type USB or PCI, and obtain the vendor name.
  #
  local product_id vendor driver mac_address
  uevent=$( cat /sys/class/net/$1/device/uevent )

  if echo "${uevent}" | grep -q "DEVTYPE=usb_interface"; then
    info_array_0[1]=USB
    product_id=$( awk -F'=' '/PRODUCT/ {print $2}' <<< ${uevent} )
    product_id=$( awk -F'/' '{print $1":"$2}' <<< ${product_id} )
    vendor=$( lsusb | grep "${product_id}" | sed "s/.*${product_id} //" )
    update_info_array 0 "${vendor}" "${vendor}"
  elif echo "${uevent}" | grep -q "PCI_CLASS="; then
    update_info_array 1 "${uevent}" "PCI"
    product_id=$( awk -F'=' '/PCI_ID/ {print $2}' <<< ${uevent} )
    vendor=$( lspci -nn | grep -i "${product_id}" \
              | sed 's/.*Network controller \[.*\]: //; s/ \[.*\]//' )
    update_info_array 0 "${vendor}" "${vendor}"
  fi

  driver=$( echo "${uevent}" | awk -F= '/DRIVER/ {print $2}' )
  update_info_array 2 "${driver}" "${driver}"

  mac_address=$( cat /sys/class/net/$1/address )
  # Redact contents of variable $1 if privacy has been enabled.
  [[ ${privacy} -eq 1 ]] && mac_address="<privacy>"
  update_info_array 4 "${mac_address}" "${mac_address}"
}

function get_ip() {
  # $1 (required) wireless interface device name.
  # Get the TCP/IP address, if assigned, and determine whether it
  # belongs to private IP address range. Redact the address, if it
  # is a public IP address and privacy has been enabled.
  #
  local tcpip tcpip_v6

  # Prefer ip and fallback to ifconfig.
  #
  if command -v ip >/dev/null 2>&1; then
    tcpip=$( ip addr show $1 | awk '/inet / {print $2}' | cut -d/ -f1 )
    tcpip_v6=$( ip addr show $1 | awk '/inet6 / {print; exit}' )
  elif command -v ifconfig >/dev/null 2>&1; then
    tcpip=$( ifconfig $1 | awk '/inet / {print $2}' )
    tcpip=${tcpip#*:} # Busybox compatibility. 
    tcpip=${tcpip#* }
    tcpip_v6=$( ifconfig $1 | awk '/inet6 / {print; exit}' )
  fi

  [[ -n ${tcpip_v6} ]] && tcpip_v6=yes || tcpip_v6=no
  update_info_array 18 "${tcpip_v6}" "${tcpip_v6}"  

  # Skip checking TCP/IP if unavailable.
  #
  if [[ -n ${tcpip} ]]; then
    if [[ ${tcpip} =~ ^10\. ]] ||
      [[ ${tcpip} =~ ^172\.1[6-9]\. ]] ||
      [[ ${tcpip} =~ ^172\.2[0-9]\. ]] ||
      [[ ${tcpip} =~ ^172\.3[0-1]\. ]] ||
      [[ ${tcpip} =~ ^192\.168\. ]]; then
      update_info_array 5 "${tcpip}" "${tcpip}"
    else
      # Redact contents of variable $1 if privacy has been enabled.
      [[ ${privacy} -eq 1 ]] && tcpip="<privacy>"
      update_info_array 5 "${tcpip}" "${tcpip}"
    fi
  else 
    tcpip=none
    update_info_array 5 "${tcpip}" "${tcpip}"
  fi
}

function info_prn() {
  # $1 Style (required)
  # $2 Text
  # $3 Text
  #
  case $1 in
    1) printf "%-${IFNAMSIZ}s  %-60s\n" "$2" "$3" ;; 
    2) printf "%-${IFNAMSIZ}s  %-19s  %-39s\n" " " "$2" "$3" ;;
    4) printf "%s;" "$2" ;;
    5) printf "%s %s;" "$2" "$3" ;;
    6) printf "%s %s\n" "$2" "$3" ;;
  esac
}

function info() {
  # $1 (required) wireless interface device name.  
  # Redefine default output format if $compact=1.
  #
  local f1=1 f2=2 f3=2
  [[ ${compact} -eq 1 ]] && { local f1=4 f2=5 f3=6; }
  declare -a info_array_0=()
  # Array elements are going to be updated - use n/a as fallback.
  #
  for i in {0..18}; do
    info_array_0[$i]="n/a"
  done

  get_sys "$1"
  get_iw_link "$1"
  get_iw_info "$1"
  get_ip "$1"
  get_iwconfig "$1"
  info_prn $f1 "$1" "${info_array_0[0]}"
  info_prn $f2 "Interface:" "${info_array_0[1]}"
  info_prn $f2 "Kernel Driver:" "${info_array_0[2]}"
  info_prn $f2 "Power Management:" "${info_array_0[3]}"
  info_prn $f2 "MAC Address:" "${info_array_0[4]}"

  # Skip if neither IPv4 nor IPv6 assigned
  #
  if [[ "${info_array_0[5]}" == "none" \
     && "${info_array_0[18]}" == "no" ]]; then
    info_prn $f3 "<not connected>"
  else
    info_prn $f2 "TCP/IP Address:" "${info_array_0[5]}"
    info_prn $f2 "TCP/IP v6:" "${info_array_0[18]}"
    info_prn $f2 "SSID:" "${info_array_0[6]}"
    info_prn $f2 "Link Quality:" "${info_array_0[7]}"
    info_prn $f2 "Signal Strength:" "${info_array_0[8]}"
    info_prn $f2 "Transmit Power:" "${info_array_0[9]}"
    info_prn $f2 "Frequency:" "${info_array_0[10]}"
    info_prn $f2 "Channel Number:" "${info_array_0[11]}"
    info_prn $f2 "Channel Width:" "${info_array_0[12]}"
    info_prn $f2 "TX Speed:" "${info_array_0[13]}"
    info_prn $f2 "RX Speed:" "${info_array_0[14]}"
    info_prn $f2 "Wi-Fi Standard:" "${info_array_0[15]}"
    info_prn $f2 "Est. Throughput:" "${info_array_0[16]}"
    info_prn $f3 "Connection Time:" "${info_array_0[17]}"
  fi
}

# ----
# Main
# ----

# Set all valid command line options to zero.
#
help=0 compact=0 version=0 privacy=0

# Process user specified command line options. Allow valid options to
# be at any position, even bundled, or at the end of the command line,
# as well as duplicate options, e.g.: "wlan0 -p" or "-p -p wlan0". Since
# 'shift' won't work here, we create and alter a copy of the command
# line arguments, and will consolidate later.
#
declare -a args=()
args=("$@") # Copy of current command line arguments.
for i in "${!args[@]}"; do
  case "${args[i]}" in
    -h|--help) help=1; args[i]= ;;
    -v|--version) version=1; args[i]= ;;
    -p|--privacy) privacy=1; args[i]= ;;
    -c|--compact) compact=1; args[i]= ;;
    -[cpm]*) bundle="${args[i]#-}"
             for (( j=0; j<${#bundle}; j++ )); do
               char="${bundle:j:1}"
               case "$char" in
                 c) compact=1 ;;
                 p) privacy=1 ;;
               esac
             done
             args[i]= ;;
  esac
done   

# Verify there are no remaining (invalid) options.
#
for item in "${args[@]}"; do
  case "${item}" in
    -*) err1 ${LINENO} "Invalid option." \
          "Unknown parameter: ${item}" \
          "Try \`${IAM} --help' for more information." ;;
  esac
done

# Consolidate the remaining command line argument(s) and
# replace the original command line.
#
declare -a consolidate=()
for item in "${args[@]}"; do
    [[ -n "${item}" ]] && consolidate+=("${item}")
done
set -- "${consolidate[@]}"

# Some options are mutually exclusive. Verify 'help' and 'version' are
# mutually exclusive and not combined with any other argument.
#
if (( help || version )); then
  if (( help && version )) ||
    (( compact || privacy || $# )); then
    err1 ${LINENO} "Invalid combination of command line arguments." \
       "Try \`${IAM} --help' for more information."
  fi
  (( help )) && help
  (( version )) && version
  exit
fi

# $@ should now be empty or contain user-specified WLAN device name(s).
# Build the $ifaces array from detected WLAN interfaces and use it either
# to validate user input or to process all interfaces when none were given.
#
# Create ifaces array listing all active live wlan interfaces. 
while IFS= read -r line; do
  # Skip empty lines or directory names.
  [[ -z ${line} || ${line} == /sys/class* ]] && continue
  ifaces+=("${line}")
done < <( LC_ALL=C ls /sys/class/ieee80211/*/device/net )
  
if [[ -z $1 ]]; then
  if ! (( ${#ifaces[@]} )); then
    err1 ${LINENO} "No wireless device(s) detected."
    exit 1
  else
  for item in "${ifaces[@]}"; do
    echo
    info "${item}"
  done
  fi
else
  # Verify that user specified wlan interfaces exist.
  for item in "$@"; do
    found=0
    for i in "${ifaces[@]}"; do
      [[ "${item}" == "${i}" ]] && found=1 && break
    done
    if [[ ${found} -eq 0 ]]; then
      err1 ${LINENO} "Invalid device." \
         "Invalid 802.11 WLAN interface: ${item}" \
         "Try \`${IAM} --help' for more information."
    fi
  done
  # Proceed with user specified wlan interface(s).
  for item in "$@"; do
    echo
    info "${item}"
  done
fi

## END de9ac94fd513