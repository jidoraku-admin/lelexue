#!/usr/bin/env bash
# 构建乐乐学 Web 版（契约见 docs/architecture/shared/hub-contract.md 第 6 节）。
#
# - hub 构建到根路径 /，是用户入口（apps/hub）。
# - 学科 Web 版构建到子路径 /<学科代码>/（英语 /english/，数学 /math/ 等），
#   仅用于开发预览，构建时 --base-href 必须与子路径一致。
# - 输出目录可直接作为 Cloudflare Pages 项目 lelexue 的发布目录。
#
# 用法：scripts/web/build_web.sh [输出目录，默认 dist/web]
# 需要 flutter 在 PATH 中，或通过 FLUTTER 指定可执行文件。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/dist/web}"
FLUTTER="${FLUTTER:-flutter}"
SUBJECTS=(english math chinese physics chemistry)

# 试用构建：设置 HUB_DEV_USER_ID 时使用 profile 模式并注入测试 UserId，
# 否则为 release 构建（生产模式，hub 未登录，学科入口不可进入）。
# 注意：release 模式下 currentDevUserId() 恒为 null（apps/hub/lib/identity.dart）。
BUILD_MODE="--release"
DEFINE_ARGS=()
if [ -n "${HUB_DEV_USER_ID:-}" ]; then
  BUILD_MODE="--profile"
  DEFINE_ARGS=("--dart-define=HUB_DEV_USER_ID=${HUB_DEV_USER_ID}")
  echo "试用构建：profile 模式，HUB_DEV_USER_ID=${HUB_DEV_USER_ID}"
fi

if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  echo "未找到 flutter：请加入 PATH 或设置 FLUTTER=/path/to/flutter" >&2
  exit 1
fi

# 构建一个 Flutter 应用，把产物复制到 $OUT 下的指定子目录。
# $1 应用目录名（apps/ 下）  $2 base href  $3 输出子目录（空表示根）
build_app() {
  local app="$1" base="$2" sub="$3"
  echo "==> 构建 apps/$app，base href: $base"
  (cd "$ROOT/apps/$app" && "$FLUTTER" build web "$BUILD_MODE" --base-href "$base" ${DEFINE_ARGS[@]+"${DEFINE_ARGS[@]}"})
  local dest="$OUT${sub:+/$sub}"
  mkdir -p "$dest"
  cp -R "$ROOT/apps/$app/build/web/." "$dest/"
}

rm -rf "$OUT"
mkdir -p "$OUT"

build_app hub "/" ""

for s in "${SUBJECTS[@]}"; do
  if [ -f "$ROOT/apps/$s/web/index.html" ]; then
    build_app "$s" "/$s/" "$s"
  else
    echo "跳过 $s：apps/$s/web/index.html 不存在" >&2
  fi
done

# Cloudflare Pages 的重写规则按顺序匹配：学科子路径在前，hub 根回退在后，
# 避免学科深链接被 hub 的回退规则吞掉。
{
  for s in "${SUBJECTS[@]}"; do
    [ -f "$OUT/$s/index.html" ] && echo "/$s/* /$s/index.html 200"
  done
  echo "/* /index.html 200"
} > "$OUT/_redirects"

echo "完成：$OUT"
