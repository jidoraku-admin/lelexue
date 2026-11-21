#!/usr/bin/env python3
"""把一个单元的数据导出为客户端资源 apps/english/assets/data/<unit>.json。

用法：python3 scripts/english/export_unit.py 1
数据来源：
- docs/data/english-g3a-vocab.json（词表）
- docs/data/english-g3a-sentences.json（句型结构）
- docs/data/english-g3a-quiz.json（句型题与运用题，原创）
Unit 1 额外运行 validate_unit1.py，结果写入 validation；其他单元为 not_checked，待校验脚本补齐。
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "data"
OUT_DIR = ROOT / "apps" / "english" / "assets" / "data"
TITLES = {1: "Greetings", 2: "School things", 3: "Toys", 4: "Friends", 5: "Drinks and fruits", 6: "Food"}


def main(n: int):
    unit = f"Unit {n}"
    vocab = json.load(open(DATA / "english-g3a-vocab.json", encoding="utf-8"))
    sentences = json.load(open(DATA / "english-g3a-sentences.json", encoding="utf-8"))
    quiz = json.load(open(DATA / "english-g3a-quiz.json", encoding="utf-8"))["units"]
    if n == 1:
        check = subprocess.run([sys.executable, str(ROOT / "scripts/english/validate_unit1.py")],
                               capture_output=True, text=True)
        validation = "passed" if check.returncode == 0 else "failed: 见 #44 待核对"
    else:
        validation = "not_checked"
    out = {
        "unit": unit,
        "title": TITLES[n],
        "source": vocab["source"],
        "validation": validation,
        "scenario": quiz[unit]["scenario"],
        "characters": quiz[unit].get("characters", []),
        "words": vocab["units"][unit],
        "sentences": sentences["units"][unit],
        "sentenceQuestions": quiz[unit]["sentenceQuestions"],
        "useQuestions": quiz[unit]["useQuestions"],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"unit{n}.json"
    path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"写入 {path.relative_to(ROOT)}：词 {len(out['words'])}，句型题 {len(out['sentenceQuestions'])}，运用题 {len(out['useQuestions'])}，validation={validation}")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
