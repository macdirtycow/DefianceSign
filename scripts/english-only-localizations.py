#!/usr/bin/env python3
"""Keep only English localizations in Localizable.xcstrings."""

import json
from pathlib import Path

def main() -> None:
    path = Path(__file__).resolve().parents[1] / "MapleSign/Resources/Localizable.xcstrings"
    data = json.loads(path.read_text(encoding="utf-8"))
    strings = data.get("strings", {})
    removed = 0

    for key, entry in strings.items():
        locs = entry.get("localizations", {})
        for lang in list(locs.keys()):
            if lang != "en":
                del locs[lang]
                removed += 1

    data["sourceLanguage"] = "en"
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Removed {removed} non-English localizations")

if __name__ == "__main__":
    main()
