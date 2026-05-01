#!/usr/bin/env bash
set -euo pipefail
SELF_NAME="$1"
shift

# Имена контейнеров из docker-compose (ровно один активный vLLM на GPU).
# Соответствует пяти моделям исследования: qwen3, gemma4, yandexgpt, phi-4, deepseek-r1.
VLLM_CONTAINERS_RE='qwen3-coder-30b-awq|gemma4-26b-awq|yandexgpt-5-lite-8b|phi-4|deepseek-r1-32b-awq'

running=$(curl --silent --unix-socket /var/run/docker.sock http://localhost/containers/json || true)
count=$(printf '%s' "$running" | grep -Eo '"Names":\[[^]]+\]' | grep -E "$VLLM_CONTAINERS_RE" | grep -v "$SELF_NAME" | wc -l || true)

if [ "$count" -gt 0 ]; then
  echo "[guard] Обнаружен уже запущенный контейнер другой модели."
  echo "[guard] Разрешён только один контейнер vLLM-модели одновременно на данном GPU."
  echo "[guard] Остановите текущую модель и запустите нужную заново (docker compose stop / up)."
  exit 1
fi

exec vllm serve "$@"
