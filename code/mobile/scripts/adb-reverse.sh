#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-reverse}"
TARGET_DEVICE="${2:-}"
PORTS=(3001 3002 3003)

if [[ -n "${ANDROID_HOME:-}" ]]; then
  SDK_ROOT="$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  SDK_ROOT="$ANDROID_SDK_ROOT"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  SDK_ROOT="$HOME/Library/Android/sdk"
else
  SDK_ROOT="$HOME/Android/Sdk"
fi

ADB="$SDK_ROOT/platform-tools/adb"
if [[ ! -x "$ADB" ]]; then
  ADB="adb"
fi

DEVICES=()
while IFS= read -r line; do
  DEVICES+=("$line")
done < <("$ADB" devices | awk 'NR>1 && /[[:space:]]device$/ {print $1}')

if [[ -n "$TARGET_DEVICE" ]]; then
  found=0
  for d in "${DEVICES[@]}"; do
    if [[ "$d" == "$TARGET_DEVICE" ]]; then
      found=1
      break
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "Dispositivo '$TARGET_DEVICE' nao conectado via adb." >&2
    exit 1
  fi
  DEVICES=("$TARGET_DEVICE")
fi

if [[ ${#DEVICES[@]} -eq 0 ]]; then
  echo "Nenhum dispositivo conectado."
  [[ "$ACTION" == "reverse" ]] && exit 1
  exit 0
fi

case "$ACTION" in
  reverse)
    for device in "${DEVICES[@]}"; do
      echo ">>> $device"
      for port in "${PORTS[@]}"; do
        "$ADB" -s "$device" reverse "tcp:$port" "tcp:$port"
        echo "    tcp:$port -> tcp:$port"
      done
    done
    echo ""
    echo "Pronto."
    ;;
  list)
    "$ADB" devices
    echo ""
    echo "Reverses ativos:"
    for device in "${DEVICES[@]}"; do
      echo ">>> $device"
      "$ADB" -s "$device" reverse --list
    done
    ;;
  clean)
    for device in "${DEVICES[@]}"; do
      echo ">>> removendo reverses em $device"
      "$ADB" -s "$device" reverse --remove-all
    done
    echo "Reverses removidos."
    ;;
  *)
    echo "Acao desconhecida: $ACTION" >&2
    exit 1
    ;;
esac
