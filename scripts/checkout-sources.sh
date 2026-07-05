#!/usr/bin/env bash
set -euo pipefail

# 中文注释：本脚本只负责拉取源码到 sources/，release 仓库本身不保存源码。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/release.config"
SOURCES_DIR="${ROOT_DIR}/sources"

if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
fi

BACKEND_REPO="${BACKEND_REPO:-umud66/iot_common_server}"
BACKEND_REF="${BACKEND_REF:-master}"
SOURCE_TOKEN="${SOURCE_TOKEN:-}"

mkdir -p "${SOURCES_DIR}"

repo_url() {
  local repo="$1"
  if [[ -n "${SOURCE_TOKEN}" ]]; then
    printf 'https://x-access-token:%s@github.com/%s.git' "${SOURCE_TOKEN}" "${repo}"
  else
    printf 'https://github.com/%s.git' "${repo}"
  fi
}

checkout_repo() {
  local name="$1"
  local repo="$2"
  local ref="$3"
  local dir="${SOURCES_DIR}/${name}"
  rm -rf "${dir}"
  echo "拉取 ${name}: ${repo}@${ref}"
  git clone --depth 1 --branch "${ref}" "$(repo_url "${repo}")" "${dir}"
}

checkout_repo backend "${BACKEND_REPO}" "${BACKEND_REF}"
