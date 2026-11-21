#!/usr/bin/env python3
"""把 Unit 1 的词表与句型从 docs/data 导出为客户端资源 apps/english/assets/data/unit1.json。

只读取 docs/data，写入客户端资源目录。导出前先运行 validate_unit1.py 的检查逻辑：
当前有 5 条词条不在附录3词头中（见 #44 核对事项），导出仍会进行，但输出会标注 validation。
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "data"
OUT = ROOT / "apps" / "english" / "assets" / "data" / "unit1.json"


def main():
    vocab = json.load(open(DATA / "english-g3a-vocab.json", encoding="utf-8"))
    sentences = json.load(open(DATA / "english-g3a-sentences.json", encoding="utf-8"))
    check = subprocess.run([sys.executable, str(ROOT / "scripts/english/validate_unit1.py")],
                           capture_output=True, text=True)
    out = {
        "unit": "Unit 1",
        "title": "Greetings",
        "source": vocab["source"],
        "validation": "passed" if check.returncode == 0 else "failed: 见 #44 待核对",
        "words": vocab["units"]["Unit 1"],
        "sentences": sentences["units"]["Unit 1"],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"写入 {OUT.relative_to(ROOT)}：词 {len(out['words'])}，句型 {len(out['sentences'])}，validation={out['validation']}")


if __name__ == "__main__":
    main()
