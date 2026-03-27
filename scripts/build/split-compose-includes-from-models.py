#!/usr/bin/env python3
"""
Split generated MediaStack network-model compose files into:
- cleaned single-file model copies
- parent docker-compose.yaml files
- subordinate include/*.yaml files

Expected input files:
- docker-compose.full-vpn.yaml
- docker-compose.mini-vpn.yaml
- docker-compose.no-vpn.yaml

Expected marker format inside each source file:
    #### INCLUDE-START docker-compose.yaml
    ... parent compose body ...
    #### INCLUDE-END docker-compose.yaml

    #### INCLUDE-START secure-access.yaml
    ... include compose body ...
    #### INCLUDE-END secure-access.yaml

Why this script exists:
- The network-model generator keeps the include markers in place on purpose.
- This splitter is the later packaging step that turns one marked model file into:
  * a parent docker-compose.yaml
  * an include/ directory of subordinate compose files
- It also writes cleaned copies of the original full/mini/no single-file models with the
  marker lines removed, so all exported files are plain compose YAML.

Important behavior:
- The docker-compose.yaml block becomes the parent compose file.
- Every later block becomes ./include/<marker filename>.
- The parent gets an include: section added automatically.
- Only marker lines starting with "#### INCLUDE" are stripped.
  This deliberately does NOT remove the long ################ divider comments.
- If a block does not exist in a model (for example vpn-core.yaml in no-vpn),
  it is simply not emitted for that model and is not referenced by that model's parent compose.

This is a structural packaging step only.
It does not alter routing, ports, labels, images, networks, or service content.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import List, Tuple

# Marker rules are intentionally narrow so we only strip the structured include markers.
# This avoids deleting the long ######## divider comments used throughout the compose files.
START_RE = re.compile(r"^\s*####\s+INCLUDE-START\s+([^\s]+)\s*$")
END_RE = re.compile(r"^\s*####\s+INCLUDE-END\s+([^\s]+)\s*$")
ANY_INCLUDE_MARKER_RE = re.compile(r"^\s*####\s+INCLUDE")
PARENT_NAME = "docker-compose.yaml"


class SplitError(Exception):
    """Raised when marker parsing or output generation fails."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split generated network-model compose files into docker-compose.yaml + include files."
    )
    parser.add_argument(
        "--full-source",
        default="docker-compose.full-vpn.yaml",
        help="Path to generated full-vpn single-file compose.",
    )
    parser.add_argument(
        "--mini-source",
        default="docker-compose.mini-vpn.yaml",
        help="Path to generated mini-vpn single-file compose.",
    )
    parser.add_argument(
        "--no-source",
        default="docker-compose.no-vpn.yaml",
        help="Path to generated no-vpn single-file compose.",
    )
    parser.add_argument(
        "--output-root",
        default="./generated-includes",
        help="Root folder to write model outputs into.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Allow writing into an existing non-empty output root.",
    )
    return parser.parse_args()


def ensure_root(path: Path, force: bool) -> None:
    if path.exists():
        if not path.is_dir():
            raise SplitError(f"Output root exists and is not a directory: {path}")
        if any(path.iterdir()) and not force:
            raise SplitError(f"Output root is not empty: {path} (use --force to allow writing)")
    else:
        path.mkdir(parents=True, exist_ok=True)


def parse_blocks(text: str, source_name: str) -> List[Tuple[str, List[str]]]:
    """Extract ordered include blocks from one model source file."""
    blocks: List[Tuple[str, List[str]]] = []
    current_name: str | None = None
    current_lines: List[str] = []

    for lineno, line in enumerate(text.splitlines(keepends=True), start=1):
        start = START_RE.match(line.rstrip("\n"))
        end = END_RE.match(line.rstrip("\n"))

        if start:
            if current_name is not None:
                raise SplitError(
                    f"Nested include block in {source_name} at line {lineno}: {start.group(1)}"
                )
            current_name = start.group(1)
            current_lines = []
            continue

        if end:
            if current_name is None:
                raise SplitError(
                    f"Include end without start in {source_name} at line {lineno}: {end.group(1)}"
                )
            end_name = end.group(1)
            if end_name != current_name:
                raise SplitError(
                    f"Mismatched include end in {source_name} at line {lineno}: "
                    f"expected {current_name}, got {end_name}"
                )
            blocks.append((current_name, current_lines.copy()))
            current_name = None
            current_lines = []
            continue

        if current_name is not None:
            current_lines.append(line)

    if current_name is not None:
        raise SplitError(f"Unclosed include block in {source_name}: {current_name}")
    if not blocks:
        raise SplitError(f"No include blocks found in {source_name}")

    return blocks


def strip_include_markers(lines: List[str]) -> List[str]:
    """
    Remove only structured include marker lines.

    We intentionally leave normal comment banners and section dividers alone.
    """
    return [line for line in lines if not ANY_INCLUDE_MARKER_RE.match(line.rstrip("\n"))]


def build_parent(parent_lines: List[str], include_names: List[str]) -> List[str]:
    """
    Append an include: section to the parent docker-compose body.

    The parent block is taken exactly from the marker section in the model source,
    then we add include paths for all subordinate blocks found in that same model.
    """
    out = list(parent_lines)
    if out and out[-1].strip() != "":
        out.append("\n")

    out.append("include:\n")
    for name in include_names:
        out.append(f"  - path: ./include/{name}\n")
    out.append("\n")
    return out


def write_text(path: Path, lines: List[str]) -> None:
    """Write one generated YAML file after marker cleanup."""
    path.parent.mkdir(parents=True, exist_ok=True)
    cleaned_lines = strip_include_markers(lines)
    path.write_text("".join(cleaned_lines), encoding="utf-8", newline="")


def write_cleaned_model_copy(model_name: str, source_path: Path, text: str, output_root: Path) -> None:
    """
    Write a cleaned single-file copy of the model source with marker lines removed.

    This gives maintainers a plain compose copy of each model as well as the split include layout.
    """
    cleaned_dir = output_root / "cleaned-models"
    cleaned_dir.mkdir(parents=True, exist_ok=True)
    cleaned_name = f"docker-compose.{model_name}.yaml"
    cleaned_path = cleaned_dir / cleaned_name
    cleaned_text = "".join(strip_include_markers(text.splitlines(keepends=True)))
    cleaned_path.write_text(cleaned_text, encoding="utf-8", newline="")
    print(f"[INFO] Wrote cleaned model copy: {cleaned_path}", flush=True)


def process_model(model_name: str, source_path: Path, output_root: Path) -> None:
    if not source_path.exists():
        raise SplitError(f"Source file not found for {model_name}: {source_path}")

    print("")
    print(f"[INFO] Processing {model_name}: {source_path}", flush=True)
    text = source_path.read_text(encoding="utf-8")

    # First write a cleaned single-file model copy so the exported model file no longer carries markers.
    write_cleaned_model_copy(model_name, source_path, text, output_root)

    # Then parse the same source into parent/include blocks.
    blocks = parse_blocks(text, source_path.name)

    names = [name for name, _ in blocks]
    if PARENT_NAME not in names:
        raise SplitError(
            f"Parent block '{PARENT_NAME}' not found in {source_path.name}. Found: {', '.join(names)}"
        )

    seen = set()
    dups = []
    for name in names:
        if name in seen:
            dups.append(name)
        seen.add(name)
    if dups:
        raise SplitError(f"Duplicate block names in {source_path.name}: {', '.join(sorted(set(dups)))}")

    parent_lines: List[str] | None = None
    include_blocks: List[Tuple[str, List[str]]] = []
    for name, lines in blocks:
        if name == PARENT_NAME:
            parent_lines = lines
        else:
            include_blocks.append((name, lines))

    assert parent_lines is not None

    model_dir = output_root / model_name
    include_dir = model_dir / "include"
    model_dir.mkdir(parents=True, exist_ok=True)
    include_dir.mkdir(parents=True, exist_ok=True)

    include_names = [name for name, _ in include_blocks]
    parent_out = build_parent(parent_lines, include_names)
    parent_path = model_dir / PARENT_NAME
    write_text(parent_path, parent_out)
    print(f"[INFO] Wrote parent: {parent_path}", flush=True)

    for name, lines in include_blocks:
        include_path = include_dir / name
        write_text(include_path, lines)
        print(f"[INFO] Wrote include: {include_path}", flush=True)

    print("")
    print(
        f"[DONE] {model_name}: cleaned model + parent + {len(include_blocks)} include file(s) generated in {model_dir}",
        flush=True,
    )


def main() -> int:
    args = parse_args()
    output_root = Path(args.output_root)
    ensure_root(output_root, args.force)

    process_model("full-vpn", Path(args.full_source), output_root)
    process_model("mini-vpn", Path(args.mini_source), output_root)
    process_model("no-vpn", Path(args.no_source), output_root)

    print("\n[DONE] All three model files were cleaned and split successfully.", flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SplitError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
