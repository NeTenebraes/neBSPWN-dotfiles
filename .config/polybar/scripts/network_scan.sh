#!/bin/bash
# ~/.config/polybar/scripts/network_scan.sh
# Descubrimiento rápido de hosts en todas las interfaces IPv4 y notificación solo con IPs.
# Author: NeTenebrae

set -u

CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/polybar_network_scan.txt"
TS_FILE="$CACHE_DIR/polybar_network_scan.timestamp"
LOCK_FILE="$CACHE_DIR/network_scan.lock"
LOG_FILE="$CACHE_DIR/network_scan.debug"

mkdir -p "$CACHE_DIR"

# Tunables
AS_RETRY=1
AS_TIMEOUT=200     # ms
FPING_TIMEOUT=150  # ms
FPING_RETRIES=0

# -------------------- Utils --------------------

list_ifaces_with_ipv4() {
  ip -o -4 addr show scope global | awk '{print $2}' | sort -u
}

get_iface_cidr() {
  local ifc="$1"
  ip -o -4 addr show "$ifc" | awk '{print $4}' | tail -n1
}

get_iface_ip() {
  local ifc="$1"
  local cidr
  cidr="$(get_iface_cidr "$ifc")" || return
  [ -n "$cidr" ] || return
  echo "$cidr" | cut -d/ -f1
}

build_ignore_set() {
  IGNORE_IPS=()
  # Gateways por defecto
  while read -r gw; do [[ -n "$gw" ]] && IGNORE_IPS+=("$gw"); done < <(ip route | awk '/^default/{print $3}')
  # Gateways por interfaz (rutas via)
  while read -r ifc; do
    while read -r gw; do [[ -n "$gw" ]] && IGNORE_IPS+=("$gw"); done < <(ip route show dev "$ifc" | awk '/ via /{for(i=1;i<=NF;i++){if($i=="via"){print $(i+1)}}}')
  done < <(list_ifaces_with_ipv4)
}

in_ignore_set() {
  local ip="$1"
  for g in "${IGNORE_IPS[@]:-}"; do
    [[ "$ip" == "$g" ]] && return 0
  done
  return 1
}

have_cap_net_raw() {
  command -v getcap >/dev/null 2>&1 || return 1
  local bin
  bin="$(command -v arp-scan 2>/dev/null)" || return 1
  getcap "$bin" 2>/dev/null | grep -q 'cap_net_raw' || return 1
  return 0
}

# -------------------- Motores de escaneo --------------------

# arp-scan por interfaz
scan_iface_arpscan_batch() {
  local ifc="$1" my_ip
  my_ip="$(get_iface_ip "$ifc")"
  [ -n "$my_ip" ] || return

  # --localnet descubre la subred de la interfaz; --retry/--timeout aceleran; --ignoredups limpia duplicados
  arp-scan --interface "$ifc" --localnet --retry="$AS_RETRY" --timeout="$AS_TIMEOUT" --ignoredups 2>>"$LOG_FILE" \
  | awk -v IF="$ifc" -v MINE="$my_ip" '
      /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s/ { ip=$1; if (ip != MINE) print IF " | " ip " | arp-scan" }
    '
}

# nmap como respaldo (host discovery ARP)
scan_iface_nmap_batch() {
  local ifc="$1" cidr my_ip
  cidr="$(get_iface_cidr "$ifc")"
  [ -n "$cidr" ] || return
  my_ip="$(echo "$cidr" | cut -d/ -f1)"

  nmap -sn -n -PR --min-parallelism 256 --max-retries 1 --max-rtt-timeout 200ms "$cidr" 2>>"$LOG_FILE" \
  | awk -v IF="$ifc" -v MINE="$my_ip" '
      /^Nmap scan report for / { ip=$NF }
      /Host is up/ { if (ip != "" && ip != MINE) print IF " | " ip " | nmap"; ip="" }
    '
}

# fping como último recurso
scan_iface_fping_batch() {
  local ifc="$1" cidr my_ip
  cidr="$(get_iface_cidr "$ifc")"
  [ -n "$cidr" ] || return
  my_ip="$(echo "$cidr" | cut -d/ -f1)"

  fping -a -q -g -r "$FPING_RETRIES" -t "$FPING_TIMEOUT" "$cidr" 2>>"$LOG_FILE" \
  | awk -v IF="$ifc" -v MINE="$my_ip" '{ if ($1 != MINE) print IF " | " $1 " | fping" }'
}

# -------------------- Lock --------------------

scan_all_batch() {
  echo 1 > "$LOCK_FILE"
  : > "$LOG_FILE"
  mapfile -t IFACES < <(list_ifaces_with_ipv4)

  build_ignore_set

  local use_arpscan=0 use_nmap=0 use_fping=0
  if command -v arp-scan >/dev/null 2>&1 && have_cap_net_raw; then use_arpscan=1
  elif command -v nmap   >/dev/null 2>&1; then use_nmap=1
  elif command -v fping  >/dev/null 2>&1; then use_fping=1
  fi

  TMP_ALL="$(mktemp)"
  > "$TMP_ALL"

  for IF in "${IFACES[@]:-}"; do
    if [ "$use_arpscan" -eq 1 ]; then
      scan_iface_arpscan_batch "$IF" >> "$TMP_ALL" &
    elif [ "$use_nmap" -eq 1 ]; then
      scan_iface_nmap_batch "$IF" >> "$TMP_ALL" &
    elif [ "$use_fping" -eq 1 ]; then
      scan_iface_fping_batch "$IF" >> "$TMP_ALL" &
    fi
  done
  wait

  # Filtrado: excluir gateways y duplicados por IP
  > "$CACHE_FILE"
  while IFS= read -r line; do
    ip="$(echo "$line" | awk -F'\\s*\\|\\s*' '{print $2}')"
    [ -n "$ip" ] || continue
    in_ignore_set "$ip" && continue
    echo "$line"
  done < "$TMP_ALL" \
  | awk -F'\\s*\\|\\s*' '!seen[$2]++' >> "$CACHE_FILE"

  rm -f "$TMP_ALL"
  date +%s > "$TS_FILE"
  rm -f "$LOCK_FILE"
  notify-send "Scan completed" "Report is ready" -i network-wired
}

notify_report() {
  if [ -s "$CACHE_FILE" ]; then
    ips="$(awk -F'\\s*\\|\\s*' '{print $2}' "$CACHE_FILE" | awk 'NF && !seen[$1]++')"
    notify-send "Detected IPs" "$ips" -i network-wired
  else
    notify-send "Detected IPs" "No devices" -i network-wired
  fi
}

relative_time() {
  local ts="$1" now diff d h m s
  now=$(date +%s)
  diff=$(( now - ts ))
  if (( diff < 60 )); then
    echo "${diff}s"
  elif (( diff < 3600 )); then
    m=$(( diff / 60 ))
    echo "${m}m"
  elif (( diff < 86400 )); then
    h=$(( diff / 3600 ))
    echo "${h}h"
  else
    d=$(( diff / 86400 ))
    echo "${d}d"
  fi
}

# -------------------- Animation --------------------

loop() {
  # Frames ASCII
  local scan_frames=( "[  ]" "[==]" "[##]" "[==]" )
  local idle_frames=( ".   " " .  " "  . " "   ." "  . " " .  " )
  local i=0

  while :; do
    local scanning=0
    if [ -f "$LOCK_FILE" ]; then
      scanning=1
    fi

    local frame
    if [ "$scanning" -eq 1 ]; then
      frame="${scan_frames[$(( i % ${#scan_frames[@]} ))]}"
      echo "$frame Running scan $frame"
    else
      frame="${idle_frames[$(( i % ${#idle_frames[@]} ))]}"
      local count="0"
      [ -s "$CACHE_FILE" ] && count=$(awk 'END{print NR}' "$CACHE_FILE")
      local ago="-"
      [ -f "$TS_FILE" ] && ago=$(relative_time "$(cat "$TS_FILE")")
      echo "$frame ${count} IPs | last scan: ${ago}"
    fi

    i=$(( i + 1 ))
    sleep 0.2
  done
}



usage() {
  echo "Usage: $0 {scan|notify|loop|report|help}"
}

case "${1:-}" in
  scan)   scan_all_batch ;;
  notify) notify_report ;;
  loop)   loop ;;
  report) cat "$CACHE_FILE" ;;
  help|*) usage ;;
esac
