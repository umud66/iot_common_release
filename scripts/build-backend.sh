#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${BACKEND_DIR:-${ROOT_DIR}/sources/backend}"
DIST_DIR="${DIST_DIR:-${ROOT_DIR}/dist}"
VERSION="${VERSION:-dev}"
COMMIT_SHA="${GITHUB_SHA:-local}"
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! -f "${BACKEND_DIR}/go.mod" ]]; then
  echo "未找到后端源码：${BACKEND_DIR}" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}/bin" "${DIST_DIR}/checksums"

cd "${BACKEND_DIR}"

echo "运行后端测试"
go test ./...

build_one() {
  local app="$1"
  local package_path="$2"
  local goos="$3"
  local goarch="$4"
  local ext=""
  if [[ "${goos}" == "windows" ]]; then
    ext=".exe"
  fi
  local output="${DIST_DIR}/bin/seacontroll-${app}-${goos}-${goarch}${ext}"
  echo "编译 ${app} ${goos}/${goarch}"
  CGO_ENABLED=0 GOOS="${goos}" GOARCH="${goarch}" go build \
    -trimpath \
    -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT_SHA} -X main.buildTime=${BUILD_TIME}" \
    -o "${output}" \
    "${package_path}"
}

# 中文注释：默认覆盖常见服务器平台，用户本地 Mac 也可以直接运行 darwin 产物调试。
for target in linux/amd64 linux/arm64 darwin/arm64; do
  goos="${target%/*}"
  goarch="${target#*/}"
  build_one http ./http/cmd "${goos}" "${goarch}"
  build_one mqtt ./mqtt/cmd "${goos}" "${goarch}"
done

cd "${DIST_DIR}/bin"
sha256sum * > "${DIST_DIR}/checksums/SHA256SUMS"

package_one() {
  local app="$1"
  local goos="$2"
  local goarch="$3"
  local binary="seacontroll-${app}-${goos}-${goarch}"
  local package_name="seacontroll-${app}-${VERSION}-${goos}-${goarch}"
  local archive_binary="seacontroll-${app}"
  cp "${DIST_DIR}/bin/${binary}" "${DIST_DIR}/bin/${archive_binary}"
  (cd "${DIST_DIR}/bin" && tar -czf "${DIST_DIR}/${package_name}.tar.gz" "${archive_binary}")
  rm -f "${DIST_DIR}/bin/${archive_binary}"
}

for target in linux/amd64 linux/arm64 darwin/arm64; do
  goos="${target%/*}"
  goarch="${target#*/}"
  package_one http "${goos}" "${goarch}"
  package_one mqtt "${goos}" "${goarch}"
done

echo "构建完成：${DIST_DIR}"
