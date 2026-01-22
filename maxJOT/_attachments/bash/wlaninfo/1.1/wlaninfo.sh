#!/bin/bash
# File:    /mnt/flux/linux/maxjot/wlaninfo.sh
# Author:  maxJOT
# License: Copyright (c) 2024 maxJOT, All Rights Reserved. 
#          The author hereby grants the following rights:
#          Free to use but not for sale. No redistribution of modified copies.
#          Please see LICENSE file.
# Date:    06-OCT-2024
# System:  FluxLinux, Bash 4.4
# Purpose: This command gathers information about wireless LAN interfaces
#          in the system, such as, bus type, vendor name, transmit power in
#          milliwatts, etc. There's no direct way, for example, to query
#          vendor name by wlan device name, makeing it somewhat challenging
#          otherwise. This script relies on several external commands, but 
#          has been designed with compatiblity in mind.
# History: 1.0: 06-OCT-2024
#               initial release.
#          1.1: 06-DEC-2025
#               Report TX and RX speeds, added Wi-Fi standard (802.11),
#               est. throughput and connection time.
#               Added compact mode (--compact).
#               Complete rework of how to process and parse command line
#               option, allowing duplicate options and multiple device name.
#               Handling any realistic user failure.
#               Some optimizaion and cosmetic chagnes.

# ----------------------------------
# Preliminary checks and definitions
# ----------------------------------

iam=${BASH_SOURCE[0]##*/}

# Assign terminal sequences if available - no effect if not.
#
deco=( 'bd:bold' 'c1:setaf 1' 'rg:bel' 't0:sgr0' )
for item in "${deco[@]}"; do
  printf -v "${item%:*}" '%s' "$(tput ${item#*:} 2>/dev/null)"
done

function err1() {
  # Error message. Takes $1 (lineno) $2 (msg). $3 and $3 are optional.
  #
  echo; echo "${iam} ($1) Aborted."
  echo "${iam}: ${bd}${c1}$2${t0}${rg}"
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
  unset err1 iam deco item cmd bd c1 rg t0 # Clean shell env.
  return 1
fi


# The following aims to protect from installation or download corruption.
#
crc=( $( head -n -1 ${BASH_SOURCE[0]} | cksum ) )
num=( $( tail -1 ${BASH_SOURCE[0]} | grep "^#" ) )
if [[ $1 == ${iam} ]]; then
  sed -i "s/${num[2]}/${crc[0]}/g" "${BASH_SOURCE[0]}"
  exit 
elif [[ ${crc[0]} -ne "${num[2]}" ]]; then
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
#
declare -a info_array
# Array elements are going to be updated - use n/a as fallback.
#
for i in {0..17}; do
    info_array[$i]="n/a"
done

# Maximum lenght of network device names according the system kernel
# limit (IFNAMSIZ). The variable also sets the left indentation in the
# info_prn output function.
#
IFNAMSIZ=16

function help() {
  echo "Usage: wlaninfo [OPTIONS] [INTERFACE]"  
  echo 
  echo "Options:
  -c, --compact     Show semicolon-separated output.
  -v, --version     Show version and licensing info.
  -p, --privacy     Redact sensitive data.
  -h, --help        Help."
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
  TCP/IP address, SSID, link quality, signal strength, transmit power,
  frequency, channel number, channel width, rx speed, tx-speed, Wi-Fi
  standard, estimated throughput, connection time."
}

function version() {
  echo "Version 1.1"
  echo "
  Copyright (c) 2024-2025 maxJOT. All Rights Reserved.
  The author grants the following rights:

  You may use this software freely, but you may not plagiarize,
  sell, or bundle it for profit, including software development
  or services. Please see /etc/LICENSE.maxJOT for more details."
}

function check_privacy() {
  # $1 variable name (required)
  # Redact contents of variable $1 if privacy has been enabled.
  #
  local -n outvar=$1
  [[ ${privacy} -eq 1 ]] && outvar="<privacy>"
}

function get_iw_link() {
  # $1 (required) wireless interface device name.
  # Get information from iw
  #
  local signal_dbm signal ssid bitrate freq_mhz freq
  local protocol xput uptime

  if hash iw 2>/dev/null; then
    iw_link=$( iw dev $1 link )
    signal_dbm=$( echo "${iw_link}" | grep -i "signal" | awk '{print $2}' )
    signal=Poor # Default. 
    freq=0 # Default.
    [[ "${signal_dbm}" -ge -80 ]] && signal=Weak
    [[ "${signal_dbm}" -ge -70 ]] && signal=Fair
    [[ "${signal_dbm}" -ge -60 ]] && signal=Good
    [[ "${signal_dbm}" -ge -50 ]] && signal=Excellent
    info_array[8]="${signal_dbm} dBm (${signal})"
    ssid=$( echo "${iw_link}" | grep -i "^[[:space:]]*SSID:" )
    ssid=$( echo "${ssid}" | awk '{print $2}' )
    check_privacy ssid
    info_array[6]="${ssid}"
    bitrate=$( echo "${iw_link}" | grep -i "bitrate:" | awk '{print $3}' )
    info_array[13]="${bitrate} Mbps"
    protocol=$( echo "${iw_link}" | grep -i "bitrate:" | cut -d' ' -f5- )
    case "${protocol}" in
      *EHT*) info_array[15]="802.11be (Wi-Fi 7)" ;;
      *HE*) info_array[15]="802.11ax (Wi-Fi 6)" ;;
      *VHT*) info_array[15]="802.11ac (Wi-Fi 5)" ;;
      *OFDM*) info_array[15]="802.11g" ;;
      *DSSS*|*CCK*) info_array[15]="802.11b" ;;
      *) [[ "${protocol}" == *MCS* ]] && info_array[15]="802.11n (Wi-Fi 4)" ;;
    esac
    freq_mhz=$( echo "${iw_link}" | grep -i "freq" | awk '{print $2}' )
    [[ ${freq_mhz%.*} -ge 2400 && ${freq_mhz%.*} -le 2483 ]] && freq=2.4
    [[ ${freq_mhz%.*} -ge 5150 && ${freq_mhz%.*} -le 5825 ]] && freq=5  
    info_array[10]="${freq} GHz (${freq_mhz})"

    # Next records require station dump.
    #
    iw_link=$( iw dev $1 station dump )
    rxrate=$( echo "${iw_link}" | grep -i "rx bitrate:" | awk '{print $3}' )
    info_array[14]="${rxrate} MBit/s"
    xput=$( echo "${iw_link}" | grep -i "throughput:" | awk '{print $3}' )
    xput=${xput%%.*} # Extract interger number.
    info_array[16]="${xput} MBit/s"
    uptime=$( echo "${iw_link}" | grep -i "connected" | awk '{print $3}' )
    info_array[17]="${uptime} Seconds"
  else
    info_array[6]="<please install iw>"
  fi
}

function get_iw_info() {
  # $1 (required) wireless interface device name.
  # Get information from iw
  #
  local txpower channel width

  if hash iw 2>/dev/null; then
    iw_info=$( iw dev $1 info )
    txpower=$( echo "${iw_info}" | grep -i "txpower" | awk '{print $2}' )
    if [[ ${txpower%.*} -eq 0 ]]; then
      txpower=0
    else
      # Convert dbm to milliwatts using awk and round accordingly.
      #
      txpower=$( awk -v dbm="${txpower}" 'BEGIN { print 10^(dbm / 10) }' )
      txpower=$( awk -v val="${txpower}" 'BEGIN { print int(val + 0.5) }' )
    fi
    info_array[9]="${txpower} mW"

    channel=$( echo "${iw_info}" | grep -i "^[[:space:]]*channel" )
    channel=$( echo "${channel}" | awk '{print $2}' )
    info_array[11]="${channel}"

    width=$( echo "${iw_info}" | grep -i -o "width:.*" | awk '{print $2}' )
    info_array[12]="${width} MHz"
  else
    info_array[9]="<please install iw>"
  fi
}

function get_iwconfig() {
  # $1 (required) wireless interface device name.
  # Get additional info from iwconfig, if installed.
  #
  local power quality

  if hash iwconfig 2>/dev/null; then
    iw_config=$( iwconfig $1 )
    power=$( echo "${iw_config}" | grep -i "^ *Power Management:" )
    power=$( echo "${power}" | awk -F: '{print $2}' )
    quality=$( echo "${iw_config}" | grep -i "^ *Link Quality=" )
    quality=$( echo "${quality}" | awk -F= '{print $2}' )
    quality=$( echo "${quality}" | awk '{print $1}' )
    [[ -n "${power}" ]] && info_array[3]="${power}"
    [[ -n "${quality}" ]] && info_array[7]="${quality}"
  else
    info_array[3]="<please install iwconfig>"
    info_array[7]="<please install iwconfig>"
  fi
}

function get_sys() {
  # $1 (required) wireless interface device name.
  # Determine device type USB or PCI, and obtain the vendor name.
  #
  local product_id vendor driver mac_address
  uevent=$( cat /sys/class/net/$1/device/uevent )

  if echo "${uevent}" | grep -q "DEVTYPE=usb_interface"; then
    info_array[1]=USB
    product_id=$( echo "${uevent}" | awk -F= '/PRODUCT/ {print $2}' )
    product_id=$( echo "${product_id}" | awk -F/ '{print $1":"$2}' )
    vendor=$( lsusb | grep "${product_id}" | sed "s/.*${product_id} //" )
    info_array[0]="${vendor}"
  elif echo "${uevent}" | grep -q "PCI_CLASS="; then
    info_array[1]=PCI
    product_id=$( echo "${uevent}" | awk -F= '/PCI_ID/ {print $2}' )
    vendor=$( lspci -nn | grep -i "${product_id}" \
              | sed 's/.*Network controller \[.*\]: //; s/ \[.*\]//' )
    info_array[0]="${vendor}"
  fi

  driver=$( echo "${uevent}" | awk -F= '/DRIVER/ {print $2}' )
  info_array[2]="${driver}"

  mac_address=$( cat /sys/class/net/$1/address )
  check_privacy mac_address
  info_array[4]="${mac_address}"
}

function get_ip() {
  # $1 (required) wireless interface device name.
  # Get the TCP/IP address, if assigned, and determine whether it
  # belongs to private IP address range. Redact the address, if it
  # is a public IP address and privacy has been enabled.
  #
  local tcpip

  # Prefer ip and fallback to ifconfig.
  #
  if hash ip 2>/dev/null; then
    tcpip=$( ip addr show $1 | awk '/inet / {print $2}' | cut -d/ -f1 )
  elif hash ifconfig 2>/dev/null; then
    tcpip=$( ifconfig $1 | awk '/inet / {print $2}' )
    tcpip=${tcpip#*:} 
    tcpip=${tcpip#* }
  else
    info_array[5]="install"
  fi

  # Skip checking TCP/IP if unavailable.
  #
  if [[ ${info_array[5]} != install ]]; then 
    if [[ -n ${tcpip} ]]; then
      if [[ ${tcpip} =~ ^10\. ]] ||
        [[ ${tcpip} =~ ^172\.1[6-9]\. ]] ||
        [[ ${tcpip} =~ ^172\.2[0-9]\. ]] ||
        [[ ${tcpip} =~ ^172\.3[0-1]\. ]] ||
        [[ ${tcpip} =~ ^192\.168\. ]]; then
        info_array[5]="${tcpip}"
      else
        check_privacy tcpip
        info_array[5]="${tcpip}"
      fi
    else 
      info_array[5]="none"  
    fi
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
    3) printf "%-${IFNAMSIZ}s  %s\n" " " "$2" ;;
    4) printf "%s;" "$2" ;;
    5) printf "%s %s;" "$2" "$3" ;;
  esac
}

function info() {
  # $1 (required) wireless interface device name.  
  # Redefine default output format if $compact=1.
  #
  local f1=1 f2=2 f3=3
  [[ ${compact} -eq 1 ]] && { local f1=4 f2=5 f3=5; }
  get_sys "$1"
  get_iw_link "$1"
  get_iw_info "$1"
  get_ip "$1"
  get_iwconfig "$1"
  info_prn $f1 "$1" "${info_array[0]}"
  info_prn $f2 "Interface:" "${info_array[1]}"
  info_prn $f2 "Kernel Driver:" "${info_array[2]}"
  info_prn $f2 "Power Management:" "${info_array[3]}"
  info_prn $f2 "MAC Address:" "${info_array[4]}"

  # Skip if no TCP/IP address or when required networking tools
  # are not installed.
  #
  case "${info_array[5]}" in
    none) info_prn $f3 "<not connected>" ;;
    install) info_prn $f3 "<please install ip>" ;;
    *)info_prn $f2 "TCP/IP Address:" "${info_array[5]}"
       info_prn $f2 "SSID:" "${info_array[6]}"
       info_prn $f2 "Link Quality:" "${info_array[7]}"
       info_prn $f2 "Signal Strength:" "${info_array[8]}"
       info_prn $f2 "Transmit Power:" "${info_array[9]}"
       info_prn $f2 "Frequency:" "${info_array[10]}"
       info_prn $f2 "Channel Number:" "${info_array[11]}"
       info_prn $f2 "Channel Width:" "${info_array[12]}"
       info_prn $f2 "RX Speed:" "${info_array[13]}"
       info_prn $f2 "TX Speed:" "${info_array[14]}"
       info_prn $f2 "Wi-Fi Standard:" "${info_array[15]}"
       info_prn $f2 "Est. Throughput:" "${info_array[16]}"
       info_prn $f2 "Connection Time:" "${info_array[17]}" ;;
  esac
  echo
}


# ----
# Main
# ----

# Set all valid command line options to zero.
#
help=0 compact=0 version=0 privacy=0

# Process user specified command line options. Allow valid options to
# be at any position, even at the end of the command line, as well as
# duplicate options, e.g.: "wlan0 -p" or "-p -p wlan0". The 'shift'
# won't work here, hence we alter a copy of the command line args.
#
declare -a args=()
args=("$@") # Copy of current command line arguments.
for i in "${!args[@]}"; do
  case "${args[i]}" in
    -h|--help) help=1; args[i]= ;;
    -v|--version) version=1; args[i]= ;;
    -p|--privacy) privacy=1; args[i]= ;;
    -c|--compact) compact=1; args[i]= ;;
    -cp|-pc) compact=1; privacy=1; args[i]= ;;
  esac
done

# Verify there are no remaining (invalid) options.
#
for item in "${args[@]}"; do
  case "${item}" in
    -*) err1 ${LINENO} "Invalid option." \
          "Unknown parameter: ${item}" \
          "Try \`${iam} --help' for more information." ;;
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
unset args consolidate

# Some options are mutually exclusive. Verify 'help' and 'version' are
# mutually exclusive and not combined with any other argument.
#
if (( help || version )); then
  if (( help && version )) ||
    (( compact || privacy || $# )); then
    err1 ${LINENO} "Invalid combination of command line arguments." \
       "Try \`${iam} --help' for more information."
  fi
  (( help )) && help
  (( version )) && version
  exit
fi

# At this stage $@ should either be empty or a valid wlan device name(s).
# Create 'ifaces' array, listing of all available wlan interfaces.
#
while IFS= read -r line; do
    ifaces+=("${line}")
done < <(LC_ALL=C ls /sys/class/ieee80211/*/device/net/ | sort)

# Verify specified wlan interfaces are valid.
#
for item in "$@"; do
  if ! [[ "${ifaces[*]}" =~ "${item}" ]]; then
    err1 ${LINENO} "Invalid device." \
       "Not a 802.11 WLAN interface: ${item}" \
       "Try \`${iam} --help' for more information."
  fi
done

if [[ -z $1 ]]; then
  if ! (( ${#ifaces[@]} )); then
    err1 ${LINENO} "No wireless devices detected."
    exit 1
  else
    for item in "${ifaces[@]}"; do
      info "${item}"
      echo
    done
  fi
else
  for item in "$@"; do
    info "${item}"
    echo
  done
fi

## END 3530605802
