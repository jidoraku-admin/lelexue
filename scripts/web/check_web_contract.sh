#!/usr/bin/env bash
# 检查 Web 构建契约（docs/architecture/shared/hub-contract.md 6.1 节），不需要 Flutter。
#
# - hub 必须有 web/index.html。
# - 每个有 web/index.html 的应用，base 标签必须是 <base href="$FLUTTER_BASE_HREF">。
# - 没有 web/index.html 的学科只提示跳过，不算失败。
#
# 用法：scripts/web/check_web_contract.sh
# 退出码：0 通过；1 有违反契约的应用。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUBJECTS=(english math chinese physics chemistry)
EXPECTED='<base href="$FLUTTER_BASE_HREF">'
fail=0

check_app() {
  local app="$1" required="$2"
  local f="$ROOT/apps/$app/web/index.html"
  if [ ! -f "$f" ]; then
    if [ "$required" = "required" ]; then
      echo "失败 $app：缺少 apps/$app/web/index.html"
      fail=1
    else
      echo "跳过 $app：没有 web/index.html，构建时不包含"
    fi
    return
  fi
  local bases
  bases="$(grep -o '<base[^>]*>' "$f" || true)"
  if [ "$bases" = "$EXPECTED" ]; then
    echo "通过 $app：$bases"
  else
    echo "失败 $app：base 标签应为 $EXPECTED，实际为「${bases:-（无）}」"
    fail=1
  fi
}

check_app hub required
for s in "${SUBJECTS[@]}"; do
  check_app "$s" optional
done

if [ "$fail" -ne 0 ]; then
  echo "Web 构建契约检查未通过"
  exit 1
fi
echo "Web 构建契约检查通过"
