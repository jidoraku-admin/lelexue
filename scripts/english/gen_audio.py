#!/usr/bin/env python3
"""用 Piper TTS 为英语内容生成语音（原创合成，不使用教材录音）。

输入：apps/english/assets/data/unit1.json 中的词条，以及 unit1_content.dart 中的英文选项与句型。
输出：apps/english/assets/audio/<slug>.wav，并写入 audio_index.json（文本 → 文件名）。
语音模型：rhasspy/piper-voices 的 en_US-amy-medium（需先下载到 --model 指定的路径）。
遍历 assets/data/unit*.json，多单元共用同一份索引。
"""
import argparse
import json
import pathlib
import re
import unicodedata
import wave

from piper import PiperVoice

ROOT = pathlib.Path(__file__).resolve().parents[2]
ASSETS = ROOT / "apps" / "english" / "assets"


def slug(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def collect() -> list[str]:
    """收集所有单元数据中的英文文本：词条、句型题与运用题的选项，以及英文提示。"""
    phrases = []
    for path in sorted((ASSETS / "data").glob("unit*.json")):
        unit = json.loads(path.read_text(encoding="utf-8"))
        phrases += [w["en"] for w in unit["words"]]
        for key in ("sentenceQuestions", "useQuestions"):
            for q in unit[key]:
                phrases += q["options"]
    return sorted({p for p in phrases if re.search(r"[A-Za-z]", p) and not re.search(r"[\u4e00-\u9fff]", p)})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="/home/claude/voices/en_US-amy-medium.onnx")
    args = ap.parse_args()
    voice = PiperVoice.load(args.model)
    out_dir = ASSETS / "audio"
    out_dir.mkdir(parents=True, exist_ok=True)
    index = {}
    for text in collect():
        name = slug(text) + ".wav"
        with wave.open(str(out_dir / name), "wb") as wav:
            voice.synthesize_wav(text, wav)
        index[text] = name
    (out_dir / "audio_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"生成 {len(index)} 条语音 → {out_dir.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
