#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(cd "$SCRIPT_DIR/.." && pwd)"

DEVICE="${DEVICE:-}"
PICK="${PICK:-0}"
SKIP_REVERSE="${SKIP_REVERSE:-0}"
API_PORT="${API_PORT:-3001}"
WORKER_PORT="${WORKER_PORT:-3002}"
CHAT_PORT="${CHAT_PORT:-3003}"

DEFINES_FILE="$SCRIPT_DIR/../dart_defines.json"
if [[ "$SKIP_REVERSE" == "1" ]] && [[ -f "$DEFINES_FILE" ]]; then
  API_BASE_URL="$(python3 -c "import json; d=json.load(open('$DEFINES_FILE')); print(d.get('API_BASE_URL',''))")"
  WORKER_BASE_URL="$(python3 -c "import json; d=json.load(open('$DEFINES_FILE')); print(d.get('WORKER_BASE_URL',''))")"
  CHAT_BASE_URL="$(python3 -c "import json; d=json.load(open('$DEFINES_FILE')); print(d.get('CHAT_BASE_URL',''))")"
  echo ">>> Usando URLs do Cloud Run (dart_defines.json)"
else
  API_BASE_URL="http://127.0.0.1:$API_PORT"
  WORKER_BASE_URL="http://127.0.0.1:$WORKER_PORT"
  CHAT_BASE_URL="http://127.0.0.1:$CHAT_PORT"
  echo ">>> Usando URLs locais (localhost)"
fi

declare -a DEVICE_IDS=()
declare -a DEVICE_NAMES=()
declare -a DEVICE_TYPES=()

while IFS= read -r line; do
  [[ "$line" != *"•"* ]] && continue
  # accept android, ios, and simulator devices
  [[ "$line" != *"android"* ]] && [[ "$line" != *"ios"* ]] && continue
  name="$(echo "$line" | awk -F '•' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  id="$(echo "$line" | awk -F '•' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  type="$(echo "$line" | awk -F '•' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$id" ]] && continue
  DEVICE_NAMES+=("$name")
  DEVICE_IDS+=("$id")
  DEVICE_TYPES+=("$type")
done < <(flutter devices 2>/dev/null | tail -n +2)

if [[ ${#DEVICE_IDS[@]} -eq 0 ]]; then
  echo "Nenhum dispositivo Flutter encontrado." >&2
  exit 1
fi

pick_device() {
  echo ""
  echo "Dispositivos disponiveis:"
  for i in "${!DEVICE_IDS[@]}"; do
    printf "  [%d] %s (%s)\n" "$((i + 1))" "${DEVICE_NAMES[$i]}" "${DEVICE_IDS[$i]}"
  done
  echo ""
  read -r -p "Escolha o numero do dispositivo: " choice
  local index=$((choice - 1))
  if [[ $index -lt 0 || $index -ge ${#DEVICE_IDS[@]} ]]; then
    echo "Opcao invalida." >&2
    exit 1
  fi
  SELECTED_ID="${DEVICE_IDS[$index]}"
  SELECTED_NAME="${DEVICE_NAMES[$index]}"
  SELECTED_TYPE="${DEVICE_TYPES[$index]}"
}

SELECTED_ID=""
SELECTED_NAME=""
SELECTED_TYPE=""

if [[ -n "$DEVICE" ]]; then
  for i in "${!DEVICE_IDS[@]}"; do
    if [[ "${DEVICE_IDS[$i]}" == "$DEVICE" || "${DEVICE_NAMES[$i]}" == "$DEVICE" ]]; then
      SELECTED_ID="${DEVICE_IDS[$i]}"
      SELECTED_NAME="${DEVICE_NAMES[$i]}"
      SELECTED_TYPE="${DEVICE_TYPES[$i]}"
      break
    fi
  done
  if [[ -z "$SELECTED_ID" ]]; then
    echo "Dispositivo '$DEVICE' nao encontrado. Use 'make flutter-devices'." >&2
    exit 1
  fi
elif [[ "$PICK" == "1" || ${#DEVICE_IDS[@]} -gt 1 ]]; then
  pick_device
else
  SELECTED_ID="${DEVICE_IDS[0]}"
  SELECTED_NAME="${DEVICE_NAMES[0]}"
  SELECTED_TYPE="${DEVICE_TYPES[0]}"
fi

echo ""
echo ">>> Rodando em: $SELECTED_NAME ($SELECTED_ID)"
echo ""

# adb reverse only applies to Android devices
if [[ "$SKIP_REVERSE" != "1" ]] && [[ "$SELECTED_TYPE" == *"android"* ]]; then
  bash "$SCRIPT_DIR/adb-reverse.sh" reverse "$SELECTED_ID"
  echo ""
fi

flutter run -d "$SELECTED_ID" \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="WORKER_BASE_URL=$WORKER_BASE_URL" \
  --dart-define="CHAT_BASE_URL=$CHAT_BASE_URL"
