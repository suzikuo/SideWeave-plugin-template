#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    if manifest.get("version") != args.version:
        raise SystemExit(f"manifest version {manifest.get('version')} does not match tag {args.version}")
    if manifest.get("id") in {"", "example-weather"} or manifest.get("publisher") == "example-publisher":
        raise SystemExit("Replace the template id and publisher before publishing")
    excluded = {".git", ".github", "dist", "target", "tools", "README.md", ".gitignore"}
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", ZIP_DEFLATED) as archive:
        for path in sorted(root.rglob("*")):
            relative = path.relative_to(root)
            if any(part in excluded for part in relative.parts) or path.is_dir():
                continue
            archive.write(path, relative.as_posix())


if __name__ == "__main__":
    main()
