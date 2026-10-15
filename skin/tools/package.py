#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def safe_file(root: Path, relative: str) -> Path:
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise SystemExit(f"missing or unsafe package path: {relative}")
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest_path = root / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("manifestVersion") != 1 or manifest.get("apiVersion") != 1:
        raise SystemExit("manifestVersion and apiVersion must both be 1")
    skin_id = manifest.get("id", "")
    version = manifest.get("version", "")
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", skin_id):
        raise SystemExit("manifest id must be lowercase letters, numbers, '_' or '-' and start with a letter or number")
    if not re.fullmatch(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?", version):
        raise SystemExit("manifest version must use SemVer")
    if manifest.get("type") != "skin" or not manifest.get("publisher") or not manifest.get("key_id"):
        raise SystemExit("set type=skin, publisher, and key_id in manifest.json")
    if skin_id == "example-skin" or manifest.get("publisher") == "your-publisher-id" or manifest.get("key_id") == "replace-with-key-id":
        raise SystemExit("replace the starter id, publisher, and key_id before packaging")
    if manifest.get("requires_trust", False) or manifest.get("capabilities", []):
        raise SystemExit("skin packages must not request native trust or capabilities")

    skin_ui = manifest.get("skinUi")
    if skin_ui:
        asset_root = skin_ui.get("assetRoot", "")
        if not asset_root or Path(asset_root).is_absolute() or ".." in Path(asset_root).parts:
            raise SystemExit("skinUi.assetRoot must be a safe relative directory")
        for surface in ("sidebar", "detail", "control", "preview"):
            entry = skin_ui.get(surface, "")
            if not entry:
                raise SystemExit(f"skinUi.{surface} is required")
            safe_file(root, (Path(asset_root) / entry).as_posix())
    elif not (root / "skin.css").is_file():
        raise SystemExit("provide skin.css or a complete skinUi definition")

    output = Path(args.output) if args.output else root / "dist" / f"{skin_id}-{version}.zip"
    if not output.is_absolute():
        output = Path.cwd() / output
    output.parent.mkdir(parents=True, exist_ok=True)
    excluded = {".git", "dist", "tools", "README.md", ".gitignore"}
    with ZipFile(output, "w", ZIP_DEFLATED) as archive:
        for path in sorted(root.rglob("*")):
            relative = path.relative_to(root)
            if path.is_dir() or any(part in excluded for part in relative.parts):
                continue
            archive.write(path, relative.as_posix())
    print(f"Created skin package: {output}")


if __name__ == "__main__":
    main()
