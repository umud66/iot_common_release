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

mkdir -p "${DIST_DIR}/bin" "${DIST_DIR}/checksums" "${DIST_DIR}/config" "${DIST_DIR}/packages"

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

if [[ -d "${ROOT_DIR}/templates" ]]; then
  cp "${ROOT_DIR}/templates"/*.yaml "${DIST_DIR}/config/" 2>/dev/null || true
fi

cd "${DIST_DIR}/bin"
sha256sum * > "${DIST_DIR}/checksums/SHA256SUMS"

package_app() {
  local app="$1"
  local package_dir="${DIST_DIR}/packages/seacontroll-${app}-${VERSION}"
  rm -rf "${package_dir}"
  mkdir -p "${package_dir}/bin" "${package_dir}/config"
  cp "${DIST_DIR}/bin"/seacontroll-${app}-* "${package_dir}/bin/"
  cp "${DIST_DIR}/checksums/SHA256SUMS" "${package_dir}/"
  if [[ -f "${DIST_DIR}/config/seacontroll-${app}.yaml" ]]; then
    cp "${DIST_DIR}/config/seacontroll-${app}.yaml" "${package_dir}/config/"
  fi
  (cd "${DIST_DIR}/packages" && tar -czf "${DIST_DIR}/seacontroll-${app}-${VERSION}.tar.gz" "seacontroll-${app}-${VERSION}")
}

package_app http
package_app mqtt

echo "构建完成：${DIST_DIR}"
