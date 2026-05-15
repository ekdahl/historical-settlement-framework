#!/usr/bin/env python3
"""Convert place Markdown files to HTML.

Reads data/places/*/text.md and writes build/places/*/text.html.
"""
import argparse
import os
import sys
from pathlib import Path

try:
    import markdown
except ImportError as exc:
    print("ERROR: The Python package 'markdown' is required.")
    print("Install it with: python -m pip install markdown")
    raise SystemExit(1) from exc


def build_html_page(title: str, body_html: str) -> str:
    return f"""<!DOCTYPE html>
<html lang=\"sv\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>{title}</title>
</head>
<body>
  <article>
{body_html}
  </article>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate HTML from place Markdown files.")
    parser.add_argument("--RepoRoot", default=Path(__file__).resolve().parents[3], help="Repository root path")
    parser.add_argument("--Verbose", action="store_true", help="Show verbose progress")
    args = parser.parse_args()

    repo_root = Path(args.RepoRoot).resolve()
    source_root = repo_root / "data" / "places"
    output_root = repo_root / "build" / "places"

    if args.Verbose:
        print("Converting Markdown to HTML...")
        print(f"  Source: {source_root}")
        print(f"  Output: {output_root}")

    if not source_root.exists():
        print("[WARN] data/places/ not found")
        return 0

    output_root.mkdir(parents=True, exist_ok=True)

    place_folders = [p for p in source_root.iterdir() if p.is_dir()]
    converted = 0

    for place_folder in place_folders:
        source_markdown = place_folder / "text.md"
        if not source_markdown.exists():
            if args.Verbose:
                print(f"  [SKIP] No text.md in {place_folder.name}")
            continue

        output_dir = output_root / place_folder.name
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = output_dir / "text.html"

        markdown_text = source_markdown.read_text(encoding="utf-8")
        html_body = markdown.markdown(markdown_text, output_format="html5", extensions=["extra"])
        html_page = build_html_page(place_folder.name, html_body)
        output_file.write_text(html_page, encoding="utf-8")

        converted += 1
        if args.Verbose:
            print(f"  [OK] Converted {place_folder.name} -> {output_file.relative_to(repo_root)}")

    print(f"[OK] Markdown to HTML conversion complete ({converted} file(s) generated)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
