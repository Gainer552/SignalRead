#!/usr/bin/env bash
set -euo pipefail

# telemetry-mini.sh — concise Ubuntu/Arch telemetry overview

# Colors
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
  B=$(tput bold); R=$(tput setaf 1); G=$(tput setaf 2); Y=$(tput setaf 3); U=$(tput setaf 4); C=$(tput setaf 6); Z=$(tput sgr0)
else B= R= G= Y= U= C= Z=; fi

H(){ printf "\n%s%s%s\n" "$B$U" "$1" "$Z"; printf '────────────────────────────────────────\n'; }
S(){ # label state [info]
  local l="$1" s="$2" i="${3-}" col="$Y"
  case "$s" in enabled|active|opted-in|on|yes) col="$R";;
               not-installed|inactive|opted-out|off|no) col="$G";; esac
  [ -n "$i" ] && i=" ($i)"
  printf "  %s- %-22s:%s %s%s%s%s\n" "$B" "$l" "$Z" "$col" "$s" "$Z" "$i"
}

E(){ systemctl is-enabled "$1" >/dev/null 2>&1 && echo enabled || echo disabled; }
A(){ systemctl is-active  "$1" >/dev/null 2>&1 && echo active  || echo inactive; }
PD(){ dpkg -s "$1" 2>/dev/null|grep -q '^Status: install '&&echo installed||echo not-installed; }
PA(){ pacman -Q "$1" >/dev/null 2>&1&&echo installed||echo not-installed; }
KV(){ # kv KEY FILE
  [ -r "$2" ] || { echo n/a; return; }
  awk -v k="$1" 'BEGIN{IGNORECASE=1} /^[[:space:]]*#/ {next}
    match($0,"^[[:space:]]*"k"[[:space:]]*=[[:space:]]*\"?([^\"#[:space:]]+)",m){print m[1]; exit}' "$2"
}

# OS info
. /etc/os-release 2>/dev/null || true
OS="${PRETTY_NAME:-${ID:-unknown}}"; LIKE="${ID_LIKE:-}"
H "System Summary"
printf "%sOS:%s %s (%s)\n" "$B" "$Z" "$OS" "${LIKE:-?}"
printf "%sHost:%s %s\n" "$B" "$Z" "$(hostnamectl --static 2>/dev/null || hostname)"
printf "%sDate:%s %s\n" "$B" "$Z" "$(date -Is)"
printf "%sLegend:%s %sENABLED/Active%s | %sInstalled/Unknown%s | %sOff/Not installed%s\n" "$B" "$Z" "$R" "$Z" "$Y" "$Z" "$G" "$Z"

# Ubuntu
if [[ "${ID:-}" == "ubuntu" || "$LIKE" == *debian* || "$LIKE" == *ubuntu* ]]; then
  H "Ubuntu Telemetry"
  p=$(PD ubuntu-report); S ubuntu-report ${p/installed/opt-unknown} "pkg:$p"
  p=$(PD popularity-contest); conf=/etc/popularity-contest.conf; part=$(KV PARTICIPATE "$conf")
  if [ "$p" = installed ]; then
    case "$part" in 1|yes|true) S popularity-contest opted-in "PARTICIPATE=$part";;
                                0|no|false) S popularity-contest opted-out "PARTICIPATE=$part";;
                                *) S popularity-contest opt-unknown "PARTICIPATE=$part";; esac
  else S popularity-contest not-installed; fi
  p=$(PD apport); ae=$(KV enabled /etc/default/apport)
  [ "$p" = installed ] && { [[ "$ae" == 1 ]] && S "apport (config)" enabled "enabled=$ae" || [[ "$ae" == 0 ]] && S "apport (config)" disabled "enabled=$ae" || S "apport (config)" opt-unknown "enabled=$ae"; } || S "apport (config)" not-installed
  systemctl list-unit-files 2>/dev/null|grep -q '^apport\.service' && S apport.service "$(E apport.service)" "active:$(A apport.service)"
  p=$(PD whoopsie); [ "$p" = installed ] && S whoopsie.service "$(E whoopsie.service)" "active:$(A whoopsie.service)" || S whoopsie.service not-installed
  mn=/etc/default/motd-news; me=$(KV ENABLED "$mn")
  [ -r "$mn" ] && { [[ "$me" =~ ^(1|yes|true)$ ]] && S motd-news enabled "ENABLED=$me" || [[ "$me" =~ ^(0|no|false)$ ]] && S motd-news disabled "ENABLED=$me" || S motd-news opt-unknown "ENABLED=$me"; } || S motd-news not-installed
  (command -v canonical-livepatch >/dev/null || command -v pro >/dev/null) && S "livepatch tooling" installed "present" || S "livepatch tooling" not-installed
fi

# Arch
if [[ "${ID:-}" == "arch" || "$LIKE" == *arch* || "${ID:-}" == "manjaro" || "${ID:-}" == "artix" ]]; then
  H "Arch Telemetry"
  p=$(PA pkgstats); [ "$p" = installed ] && { S "pkgstats (pkg)" installed; S pkgstats.timer "$(E pkgstats.timer)" "active:$(A pkgstats.timer)"; } || S pkgstats not-installed
fi

# Generic unit hunt
H "Telemetry-like systemd units"
if command -v systemctl >/dev/null 2>&1; then
  pat='telemetry|metrics|report|whoopsie|apport|popularity|motd|livepatch|pkgstats'
  mapfile -t UFS < <(systemctl list-unit-files --type=service --type=timer --no-legend 2>/dev/null|awk '{print $1}'|grep -E "$pat" || true)
  if ((${#UFS[@]}==0)); then echo "  (none found)"; else
    for u in "${UFS[@]}"; do S "$u" "$(E "$u")" "active:$(A "$u")"; done
  fi
else echo "  systemd not detected."; fi
echo
