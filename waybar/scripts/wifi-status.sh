#!/usr/bin/env bash

# This script gathers detailed Wi-Fi connection information.
# It collects the following fields:
#
# - SSID (Service Set Identifier): The name of the Wi-Fi network you
#   are currently connected to.  Example: "My_Network"
#
# - IP Address: The IP address assigned to the device by the router.
#   This is typically a private IP within the local network.  Example:
#   "192.168.1.29/24" (with subnet mask)
#
# - Router (Gateway): The IP address of the router (default gateway)
#   that your device uses to communicate outside the local network.
#   Example: "192.168.1.1"
#
# - MAC Address: The unique Media Access Control address of the local
#   device's Wi-Fi adapter.  Example: "F8:34:41:07:1B:65"
#
# - Security: The encryption protocol being used to secure your Wi-Fi
#   connection. Common security protocols include:
#   - WPA2 (Wi-Fi Protected Access 2): The most commonly used security
#     standard, offering strong encryption (AES).
#   - WPA3: The latest version, providing even stronger security,
#     especially in public or open networks.
#   - WEP (Wired Equivalent Privacy): An outdated and insecure protocol
#     that should not be used.
#   Example: "WPA2" indicates that the connection is secured using WPA2
#   with AES encryption.
#
# - BSSID (Basic Service Set Identifier): The MAC address of the Wi-Fi
#   access point you are connected to.  Example: "A4:22:49:DA:91:A0"
#
# - Channel: The wireless channel your Wi-Fi network is using. This is
#   associated with the frequency band.  Example: "100 (5500 MHz)"
#   indicates the channel number (100) and the frequency (5500 MHz),
#   which is within the 5 GHz band.
#
# - RSSI (Received Signal Strength Indicator): The strength of the
#   Wi-Fi signal, typically in dBm (decibels relative to 1 milliwatt).
#   Closer to 0 means stronger signal, with values like -40 dBm being
#   very good.  Example: "-40 dBm"
#
# - Signal: The signal quality, which is represented as a percentage,
#   where higher numbers mean better signal.  Example: "100"
#   indicates perfect signal strength.
#
# - Rx Rate (Receive Rate): The maximum data rate (in Mbit/s) at which
#   the device can receive data from the Wi-Fi access point.  Example:
#   "866.7 MBit/s" indicates a high-speed connection on a modern
#   standard.
#
# - Tx Rate (Transmit Rate): The maximum data rate (in Mbit/s) at
#   which the device can send data to the Wi-Fi access point.  Example:
#   "866.7 MBit/s"
#
# - PHY Mode (Physical Layer Mode): The Wi-Fi protocol or standard in
#   use.  Common modes include 802.11n, 802.11ac, and 802.11ax (Wi-Fi
#   6).  Example: "802.11ac" indicates you're using the 5 GHz band with
#   a modern high-speed standard.

if ! command -v nmcli &>/dev/null; then
  echo "{\"text\": \"󰤮 Wi-Fi\", \"tooltip\": \"nmcli utility is missing\"}"
  exit 1
fi

# Check if Wi-Fi is enabled
wifi_status=$(nmcli radio wifi)

if [ "$wifi_status" = "disabled" ]; then
  tooltip="Wi-Fi Disabled"
  icon="󰤮" # Icon for no connection or disabled
  echo "{\"text\": \"${icon}\", \"tooltip\": \"${tooltip}\"}"
  exit 0
fi

wifi_info=$(nmcli -t -f active,ssid,signal,security dev wifi | grep "^yes")

# If no ESSID is found, set a default value
if [ -z "$wifi_info" ]; then
  essid="No Connection"
  signal=0
  tooltip="No Connection"
else
  # Defaults
  ip_address="127.0.0.1"
  security=$(echo "$wifi_info" | awk -F: '{print $4}')
  signal=$(echo "$wifi_info" | awk -F: '{print $3}')

  active_device=$(nmcli -t -f DEVICE,STATE device status |
    grep -w "connected" |
    grep -v -E "^(dummy|lo:)" |
    awk -F: '{print $1}' |
    sed -n '1p')

  if [ -n "$active_device" ]; then
    output=$(nmcli -e no -g ip4.address device show "$active_device")
    ip_address=$(echo "$output" | sed -n '1p')

    essid=$(echo "$wifi_info" | awk -F: '{print $2}')

    # Calculate traffic
    rx_bytes_file="/sys/class/net/${active_device}/statistics/rx_bytes"
    tx_bytes_file="/sys/class/net/${active_device}/statistics/tx_bytes"

    if [ -r "$rx_bytes_file" ] && [ -r "$tx_bytes_file" ]; then
      rx_bytes_start=$(cat "$rx_bytes_file")
      tx_bytes_start=$(cat "$tx_bytes_file")
      sleep 1
      rx_bytes_end=$(cat "$rx_bytes_file")
      tx_bytes_end=$(cat "$tx_bytes_file")

      rx_rate_bytes=$((rx_bytes_end - rx_bytes_start))
      tx_rate_bytes=$((tx_bytes_end - tx_bytes_start))

      # Convert rates to appropriate units
      if [ "$rx_rate_bytes" -ge 1048576 ]; then # Greater than or equal to 1 MB/s
        rx_rate=$(awk "BEGIN {printf \"%.2f Mb/s\", $rx_rate_bytes / 131072}") # Convert to megabits
      else
        rx_rate=$(awk "BEGIN {printf \"%.2f KB/s\", $rx_rate_bytes / 1024}")
      fi

      if [ "$tx_rate_bytes" -ge 1048576 ]; then # Greater than or equal to 1 MB/s
        tx_rate=$(awk "BEGIN {printf \"%.2f Mb/s\", $tx_rate_bytes / 131072}") # Convert to megabits
      else
        tx_rate=$(awk "BEGIN {printf \"%.2f KB/s\", $tx_rate_bytes / 1024}")
      fi
    else
      rx_rate="N/A"
      tx_rate="N/A"
    fi

    tooltip="${essid}\n"
    tooltip+="\nIP Address: ${ip_address}"
    tooltip+="\nSecurity:   ${security}"
    tooltip+="\nStrength:   ${signal} / 100"
    tooltip+="\nDownload:   ${rx_rate}"
    tooltip+="\nUpload:     ${tx_rate}"
  fi
fi

# Determine Wi-Fi icon based on signal strength
if [ "$signal" -ge 80 ]; then
  icon="󰤨" # Strong signal
elif [ "$signal" -ge 60 ]; then
  icon="󰤥" # Good signal
elif [ "$signal" -ge 40 ]; then
  icon="󰤢" # Weak signal
elif [ "$signal" -ge 20 ]; then
  icon="󰤟" # Very weak signal
else
  icon="󰤮" # No signal
fi

echo "{\"text\": \"${icon}\", \"tooltip\": \"${tooltip}\"}"
