#!/usr/bin/env python3
"""校验英语三年级上册 Unit 1 的数据接入（#7 第一周任务 1）。

检查项：
- 词表 Unit 1 的每条词条必须有 en、zh、page 字段，且非空、无重复。
- 句型 Unit 1 必须非空，且每条为字符串。
- 词表词条须能在附录3词头中找到（短语按词拆分后匹配）。

只读取 docs/data 下的文件，不修改任何数据。失败时以非零状态退出。
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "data"
UNIT = "Unit 1"


def load(name):
    with open(DATA / name, encoding="utf-8") as f:
        return json.load(f)


def main():
    errors = []
    vocab = load("english-g3a-vocab.json")
    sentences = load("english-g3a-sentences.json")
    appendix = load("english-g3a-appendix-vocab.json")

    items = vocab["units"].get(UNIT, [])
    if not items:
        errors.append(f"词表中没有 {UNIT} 的词条")

    seen = set()
    for i, item in enumerate(items):
        for key in ("en", "zh", "page"):
            if key not in item or item[key] in ("", None):
                errors.append(f"{UNIT} 第 {i + 1} 条缺少或为空字段：{key}")
        en = str(item.get("en", "")).strip().lower()
        if en in seen:
            errors.append(f"{UNIT} 词条重复：{en}")
        seen.add(en)

    headwords = {h.lower().replace("_", " ") for h in appendix["headwords"]}
    missing = []
    for item in items:
        en = str(item.get("en", "")).strip().lower().rstrip(".!?")
        if en in headwords:
            continue
        # 整条不在词头中时，按空格拆分逐词匹配（如 "stand up" 拆为 stand、up）
        for token in en.split():
            token = token.strip(".,!?")
            if token and token not in headwords:
                missing.append(en)
                break
    for en in sorted(set(missing)):
        errors.append(f"词条 {en!r} 在附录3词头中找不到（整条与逐词均不匹配）")

    sents = sentences["units"].get(UNIT, [])
    if not sents:
        errors.append(f"句型中没有 {UNIT} 的条目")
    for s in sents:
        if not isinstance(s, str) or not s.strip():
            errors.append(f"{UNIT} 句型条目为空或不是字符串")

    print(f"{UNIT}：词条 {len(items)} 条，句型 {len(sents)} 条")
    if errors:
        print("校验未通过：")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("校验通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
