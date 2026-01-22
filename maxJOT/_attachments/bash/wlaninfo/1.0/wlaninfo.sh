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


# ----------------------------------
# Preliminary checks and definitions
# ----------------------------------

iam=${BASH_SOURCE[0]##*/}
b1=$( tput setaf 1 && tput bold )
t0=$( tput sgr0 )

function err1() {
  # Error message. Takes $1 (line) $2 (msg) $3 (optional) parameters.
  echo; echo "${iam} ($1) Aborted."
  echo "${iam}: ${b1}$2${t0}"
  [[ -n $3 ]] && echo "$3"
  [[ $1 -ne S ]] && exit 1
}

# Exit if this script has been source-executed.
$( return 0 2>&- )
if [[ $? -eq 0 ]]; then
  echo
  \err1 S "Source-execution unsupported."
  unset err1 iam b1 t0
  return 1
fi

cmd_list="head tail cksum sed grep awk ip iw lsusb lspci"
for cmd in ${cmd_list}; do
  command -v ${cmd} >&- || { err1 ${LINENO} "No such command: ${cmd}"; }
done

# The following aims to protect from installation or download corruption.
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
#   12 Channel Width      13 Connection
declare -a info_array

# Maximum lenght of network device names according the system
# kernel limit (IFNAMSIZ).
IFNAMSIZ=16

function help() {
  echo "Usage: wlaninfo [OPTIONS] [INTERFACE]"  
  echo 
  echo "Options:
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
  frequency, channel number, channel width, connection speed."
}

function version() {
  echo "Version 1.0"
  echo "
  Copyright (c) 2024 maxJOT. All Rights Reserved.
  The author grants the following rights:

  You may use this software freely, but you may not plagiarize,
  sell, or bundle it for profit, including software development
  or services. Please see /etc/LICENSE.maxJOT for more details."
}

function check_privacy() {
  # $1 variable name (required)
  # Redact contents of variable $1 if privacy has been enabled.
  local -n outvar=$1
  [[ ${privacy} -eq 1 ]] && outvar="-redacted-"
}

function get_iw_link() {
  # $1 (required) wireless interface device name.
  # Get information from iw
  local signal_dbm signal ssid bitrate freq_mhz freq

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

    freq_mhz=$( echo "${iw_link}" | grep -i "freq" | awk '{print $2}' )
    [[ ${freq_mhz%.*} -ge 2400 && ${freq_mhz%.*} -le 2483 ]] && freq=2.4
    [[ ${freq_mhz%.*} -ge 5150 && ${freq_mhz%.*} -le 5825 ]] && freq=5  
    info_array[10]="${freq} GHz (${freq_mhz})"
  else
    info_array[6]="(please install iw)"
    info_array[8]="n/a"
    info_array[10]="n/a"
    info_array[13]="n/a"
  fi
}

function get_iw_info() {
  # $1 (required) wireless interface device name.
  # Get information from iw
  local txpower channel width

  if hash iw 2>/dev/null; then
    iw_info=$( iw dev $1 info )
    txpower=$( echo "${iw_info}" | grep -i "txpower" | awk '{print $2}' )
    if [[ ${txpower%.*} -eq 0 ]]; then
      txpower=0
    else
      # Convert dbm to milliwatts using awk and round accordingly.
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
    info_array[9]="(please install iw)"
    info_array[11]="n/a"
    info_array[12]="n/a" 
  fi
}

function get_iwconfig() {
  # $1 (required) wireless interface device name.
  # Get additional info from iwconfig, if installed.
  local power quality

  if hash iwconfig 2>/dev/null; then
    iw_config=$( iwconfig $1 )
    power=$( echo "${iw_config}" | grep -i "^ *Power Management:" )
    power=$( echo "${power}" | awk -F: '{print $2}' )
    quality=$( echo "${iw_config}" | grep -i "^ *Link Quality=" )
    quality=$( echo "${quality}" | awk -F= '{print $2}' )
    quality=$( echo "${quality}" | awk '{print $1}' )
    [[ -z "${power}" ]] && power="n/a"
    [[ -z "${quality}" ]] && quality="n/a"
    info_array[3]="${power}"
    info_array[7]="${quality}"
  else
    info_array[3]="(please install iwconfig)"
    info_array[7]="(please install iwconfig)"
  fi
}

function get_sys() {
  # $1 (required) wireless interface device name.
  # Determine device type USB or PCI, and obtain the vendor name.
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
  else
    info_array[0]="n/a"
    info_array[1]="n/a"
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
  local tcpip

  tcpip=$( ip addr show "$1" | grep "inet " | awk '{print $2}' )
  tcpip=$( echo "${tcpip}" | cut -d'/' -f1 )

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
}

function info_prn() {
  # $1 Style (required)
  # $2 Text
  # $3 Text
  case $1 in
    1) printf "%-${IFNAMSIZ}s  %-60s\n" "$2" "$3" ;; 
    2) printf "%-${IFNAMSIZ}s  %-19s  %-39s\n" " " "$2" "$3" ;;
    3) printf "%-${IFNAMSIZ}s  %s\n" " " "$2" ;;
  esac
}

function info() {
  # $1 (required) wireless interface device name.  
  get_sys "$1"
  get_iw_link "$1"
  get_iw_info "$1"
  get_ip "$1"
  get_iwconfig "$1"
  info_prn 1 "$1" "${info_array[0]}"
  info_prn 2 "Interface:" "${info_array[1]}"
  info_prn 2 "Kernel Driver:" "${info_array[2]}"
  info_prn 2 "Power Management:" "${info_array[3]}"
  info_prn 2 "MAC Address:" "${info_array[4]}"
  if [[ "${info_array[5]}" != "none" ]]; then
    info_prn 2 "TCP/IP Address:" "${info_array[5]}"
    info_prn 2 "SSID:" "${info_array[6]}"
    info_prn 2 "Link Quality:" "${info_array[7]}"
    info_prn 2 "Signal Strength:" "${info_array[8]}"
    info_prn 2 "Transmit Power:" "${info_array[9]}"
    info_prn 2 "Frequency:" "${info_array[10]}"
    info_prn 2 "Channel Number:" "${info_array[11]}"
    info_prn 2 "Channel Width:" "${info_array[12]}"
    info_prn 2 "Connection Speed:" "${info_array[13]}"
  else
    info_prn 3 "not connected"
  fi
  echo
}


# ----
# Main
# ----

# Check for command line arguments
if [[ $# -gt 2 ]]; then
  err1 ${LINENO}  "Invalid combination of line arguments." \
       "Try \`${iam} --help' for more information."
fi 

for item in $@; do
  case "${item}" in
    -h|--help) help; exit ;;
    -v|--version) version; exit ;;
    -p|--privacy) privacy=1; shift ;;
    -*|--*) err1 ${LINENO} "Invalid option: ${1}" \
                 "Try \`${iam} --help' for more information." ;; 
  esac
done

# At this point $1 must either a valid wireless device name, or empty.
# No further command line argument should exist.

# Get a list of all available wlan interfaces
ifaces=$( ls /sys/class/ieee80211/*/device/net/ | grep -v ieee80211 | awk NF )
ifaces=$( echo "${ifaces}" | sort )

if [[ -z $1 ]]; then
  if [[ -z ${ifaces} ]]; then
    err1 ${LINENO} "No wireless devices detected."
    exit 1
  else
    for item in ${ifaces}; do
      info ${item}
    done
  fi
else
  if echo "${ifaces}" | grep -q -w -- "$1"; then
    info $1
    exit
  else
    err1 ${LINENO} "Unknown interface: ${1}" \
         "Try \`${iam} --help' for more information."
  fi
fi

## END 3348120795
