#!/usr/bin/env python3
"""
Phase 1 network model generator for MediaStack.

Purpose
-------
This script reads the current master compose source and produces three
single-file model outputs:

- docker-compose.full-vpn.yaml
- docker-compose.mini-vpn.yaml
- docker-compose.no-vpn.yaml

Why phase 1 exists
------------------
This phase is deliberately narrow. It is only proving the mechanical parts of
model generation:

- preserve INCLUDE block markers and section boundaries
- keep the full model unchanged
- move selected services off Gluetun for mini/no models
- restore each moved service's local `ports:` block
- remove matching forwarded ports from the Gluetun service
- drop the whole vpn-core block in the no-vpn model

What this script does *not* try to do yet
-----------------------------------------
- production-hardening every edge case
- include splitting (that is a later step)
- service reordering
- image/version manipulation
- label/env changes
- advanced Gluetun logic beyond the known phase-1 rules
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# ---------------------------------------------------------------------------
# Marker regexes
# ---------------------------------------------------------------------------
# The master compose is divided into logical blocks with explicit comment
# markers. We preserve those markers in generated outputs so a later splitting
# phase can still carve the file into parent/include sections.
START_RE = re.compile(r"^(\s*)#### INCLUDE-START\s+([^\s]+)\s*$")
END_RE = re.compile(r"^(\s*)#### INCLUDE-END\s+([^\s]+)\s*$")

# Service blocks in this compose start at two-space indentation under
# `services:`. We use this to isolate and transform one service at a time.
SERVICE_RE = re.compile(r"^(\s{2})([A-Za-z0-9_.-]+):\s*$")

# ---------------------------------------------------------------------------
# Routing policy
# ---------------------------------------------------------------------------
# Services that remain on VPN in the mini model.
MINI_VPN_KEEP = {"gluetun", "qbittorrent", "sabnzbd"}

# Services that are VPN-routed in the full model but should be moved back to
# direct `mediastack` networking in the mini and/or no models.
FULL_ONLY_VPN = {
    "bazarr", "filebot", "flaresolverr", "jellyfin", "lazylibrarian",
    "lidarr", "mylar", "plex", "prowlarr", "radarr", "seerr", "sonarr",
    "tdarr", "tdarr-node", "whisparr",
}

# All services that are currently routed via Gluetun in the source model.
# In the no-vpn model, all of these are moved direct.
ALL_VPN_ROUTED = FULL_ONLY_VPN | {"qbittorrent", "sabnzbd"}

# ---------------------------------------------------------------------------
# Gluetun port ownership mapping
# ---------------------------------------------------------------------------
# These mappings let us remove forwarded ports from the Gluetun service when a
# service is moved back to direct networking.
#
# GLUETUN_PORT_VARS covers lines that use env vars, for example:
#   - ${WEBUI_PORT_SONARR:?err}:8989
#
# GLUETUN_LITERAL_PORTS covers hard-coded literal ports, used mainly for Plex.
GLUETUN_PORT_VARS: Dict[str, List[str]] = {
    "bazarr": ["WEBUI_PORT_BAZARR"],
    "filebot": ["WEBUI_PORT_FILEBOT"],
    "jellyfin": ["WEBUI_PORT_JELLYFIN"],
    "seerr": ["WEBUI_PORT_SEERR"],
    "lidarr": ["WEBUI_PORT_LIDARR"],
    "mylar": ["WEBUI_PORT_MYLAR"],
    "prowlarr": ["WEBUI_PORT_PROWLARR"],
    "radarr": ["WEBUI_PORT_RADARR"],
    "lazylibrarian": ["WEBUI_PORT_LAZYLIBRARIAN"],
    "sabnzbd": ["WEBUI_PORT_SABNZBD"],
    "sonarr": ["WEBUI_PORT_SONARR"],
    "whisparr": ["WEBUI_PORT_WHISPARR"],
    "qbittorrent": ["WEBUI_PORT_QBITTORRENT", "QBIT_PORT"],
    "flaresolverr": ["FLARESOLVERR_PORT"],
    "tdarr": ["TDARR_SERVER_PORT", "WEBUI_PORT_TDARR"],
    "tdarr-node": [],
    "plex": ["WEBUI_PORT_PLEX"],
}

GLUETUN_LITERAL_PORTS: Dict[str, List[str]] = {
    "plex": [
        "1900:1900/udp",
        "5353:5353/udp",
        "8324:8324",
        "32410:32410/udp",
        "32412:32412/udp",
        "32413:32413/udp",
        "32414:32414/udp",
        "32469:32469",
    ],
}


class ModelError(Exception):
    """Raised for predictable generation/validation failures."""


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments.

    The script intentionally stays simple:
    - one source compose
    - one output directory
    - optional force-overwrite for iterative testing
    """
    p = argparse.ArgumentParser(description="Generate phase 1 MediaStack network model files.")
    p.add_argument("--source", required=True, help="Path to mediastack-master-compose YAML source.")
    p.add_argument("--output-dir", required=True, help="Directory to write generated files.")
    p.add_argument("--force", action="store_true", help="Allow writing into a non-empty output directory.")
    return p.parse_args()


def read_lines(path: Path) -> List[str]:
    """Read the source file preserving line endings.

    We keep original line endings and formatting as much as possible because
    later phases still rely on comment markers and readable diffs.
    """
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def split_include_blocks(lines: List[str]) -> List[Tuple[str, List[str]]]:
    """Split the compose source into top-level INCLUDE blocks.

    Each block includes its own START/END markers. We preserve those markers so
    generated outputs can still be split later.
    """
    blocks: List[Tuple[str, List[str]]] = []
    current_name = None
    current_lines: List[str] = []

    for idx, line in enumerate(lines, start=1):
        sm = START_RE.match(line.rstrip("\n"))
        em = END_RE.match(line.rstrip("\n"))
        if sm:
            if current_name is not None:
                raise ModelError(f"Nested include block at line {idx}: {sm.group(2)}")
            current_name = sm.group(2)
            current_lines = [line]
            continue
        if em:
            if current_name is None:
                raise ModelError(f"End marker without start at line {idx}: {em.group(2)}")
            end_name = em.group(2)
            if end_name != current_name:
                raise ModelError(f"Mismatched end marker at line {idx}: expected {current_name}, got {end_name}")
            current_lines.append(line)
            blocks.append((current_name, current_lines[:]))
            current_name = None
            current_lines = []
            continue
        if current_name is not None:
            current_lines.append(line)

    if current_name is not None:
        raise ModelError(f"Unclosed include block: {current_name}")
    if not blocks:
        raise ModelError("No include blocks found in source file")
    return blocks


def split_service_sections(block_lines: List[str]) -> List[List[str]]:
    """Split a single INCLUDE block into smaller chunks.

    A chunk is either:
    - a block marker line
    - a service definition block
    - or non-service/header text

    This lets us transform individual services without breaking the rest of the
    block structure.
    """
    chunks: List[List[str]] = []
    current: List[str] = []
    for line in block_lines:
        if START_RE.match(line.rstrip("\n")) or END_RE.match(line.rstrip("\n")):
            if current:
                chunks.append(current)
                current = []
            chunks.append([line])
            continue

        m = SERVICE_RE.match(line)
        if m:
            if current:
                chunks.append(current)
            current = [line]
            continue

        if not current:
            current = [line]
        else:
            current.append(line)
    if current:
        chunks.append(current)
    return chunks


def get_service_name(chunk: List[str]) -> str | None:
    """Return the service name for a chunk, or None if it is not a service block."""
    for line in chunk:
        m = SERVICE_RE.match(line)
        if m:
            return m.group(2)
    return None


def uncomment_ports_block(lines: List[str]) -> List[str]:
    """Restore a commented service-local ports block.

    Source pattern expected:
        network_mode: "service:gluetun"
    #    ports:
    #      - ${WEBUI_PORT_X:?err}:1234   # Configured in Gluetun VPN container

    Output pattern wanted:
        networks:
          - mediastack
        ports:
          - ${WEBUI_PORT_X:?err}:1234

    Notes:
    - keep block-style YAML for readability
    - strip the old 'Configured in Gluetun...' comment because it is no longer true
    """
    out: List[str] = []
    in_comment_ports = False
    ports_indent = ""
    item_indent = ""

    for line in lines:
        m_header = re.match(r'^(\s*)#\s*ports:\s*$', line)
        if m_header:
            ports_indent = m_header.group(1)
            item_indent = ports_indent + '  '
            out.append(f"{ports_indent}    ports:\n")
            in_comment_ports = True
            continue

        m_item = re.match(r'^\s*#\s*-\s*(.+?)\s*$', line)
        if in_comment_ports and m_item:
            item = m_item.group(1)
            item = re.sub(r'\s+#\s*Configured in Gluetun VPN container\s*$', '', item)
            item = re.sub(r'\s+#\s*Configured in Gluetun VPN service\s*$', '', item)
            out.append(f"{item_indent}    - {item}\n")
            continue

        if in_comment_ports:
            in_comment_ports = False
            ports_indent = ""
            item_indent = ""

        out.append(line)
    return out


def convert_service_to_direct(chunk: List[str]) -> List[str]:
    """Convert one VPN-routed service back to direct networking.

    Phase-1 transform rules:
    - replace `network_mode: "service:gluetun"` with block-style `networks:`
    - remove a simple `depends_on: gluetun` block if present
    - restore the commented service-local ports block
    """
    out: List[str] = []
    i = 0
    while i < len(chunk):
        line = chunk[i]

        # Replace the Gluetun network stack with the normal MediaStack bridge.
        if 'network_mode: "service:gluetun"' in line:
            indent = re.match(r'^(\s*)', line).group(1)
            out.append(f"{indent}networks:\n")
            out.append(f"{indent}  - mediastack\n")
            i += 1
            continue

        # Remove a minimal depends_on->gluetun block if present.
        if re.match(r'^\s*depends_on:\s*$', line):
            if i + 1 < len(chunk) and re.match(r'^\s+gluetun:\s*$', chunk[i+1]):
                i += 2
                while i < len(chunk) and (re.match(r'^\s{6,}\S', chunk[i]) or chunk[i].strip() == ""):
                    i += 1
                continue

        out.append(line)
        i += 1

    return uncomment_ports_block(out)


def should_convert(service: str, model: str) -> bool:
    """Return True if a service should be moved direct for the target model."""
    if model == 'full':
        return False
    if model == 'mini':
        return service in FULL_ONLY_VPN
    if model == 'no':
        return service in ALL_VPN_ROUTED
    raise ModelError(f"Unknown model: {model}")


def filter_gluetun_ports(chunk: List[str], model: str) -> List[str]:
    """Remove forwarded Gluetun ports that no longer belong in the target model.

    full:
        leave the Gluetun service untouched
    mini:
        keep only the ports needed by gluetun/qbittorrent/sabnzbd
    no:
        Gluetun is removed entirely later, but this still keeps the logic
        consistent if called before that block is dropped
    """
    if model == 'full':
        return chunk[:]

    keep_services = set(MINI_VPN_KEEP) if model == 'mini' else set()
    remove_services = (ALL_VPN_ROUTED - keep_services)
    remove_vars = {v for svc in remove_services for v in GLUETUN_PORT_VARS.get(svc, [])}
    remove_literals = {p for svc in remove_services for p in GLUETUN_LITERAL_PORTS.get(svc, [])}

    out: List[str] = []
    for line in chunk:
        stripped = line.strip()

        # Remove env-var driven forwarded ports by matching the variable name.
        if stripped.startswith('- ${'):
            m = re.search(r'\$\{([A-Z0-9_]+)', line)
            if m and m.group(1) in remove_vars:
                continue

        # Remove literal port lines too, including commented Synology-clash lines.
        literal_match = re.match(r'^\s*#?\s*-\s*([^\s#]+)', line)
        if literal_match:
            raw = literal_match.group(1)
            if raw in remove_literals:
                continue

        out.append(line)
    return out


def transform_block(block_name: str, block_lines: List[str], model: str) -> List[str]:
    """Transform one INCLUDE block for the target model.

    Important rule:
    - We preserve block boundaries.
    - We only rewrite service content *inside* the block.
    - For no-vpn we drop the entire vpn-core block altogether.
    """
    if model == "no" and block_name == "vpn-core.yaml":
        return []

    chunks = split_service_sections(block_lines)
    result: List[str] = []
    for chunk in chunks:
        svc = get_service_name(chunk)
        if svc == 'gluetun':
            result.extend(filter_gluetun_ports(chunk, model))
        elif svc and should_convert(svc, model):
            result.extend(convert_service_to_direct(chunk))
        else:
            result.extend(chunk)
    return result


def ensure_output_dir(path: Path, force: bool) -> None:
    """Create or validate the output directory.

    We require --force for iterative overwrite runs so maintainers do not
    accidentally mix fresh output with stale files.
    """
    if path.exists() and any(path.iterdir()) and not force:
        raise ModelError(f"Output directory is not empty: {path} (use --force to overwrite)")
    path.mkdir(parents=True, exist_ok=True)


def main() -> int:
    """Main program entry point."""
    args = parse_args()
    source = Path(args.source)
    outdir = Path(args.output_dir)
    ensure_output_dir(outdir, args.force)

    lines = read_lines(source)
    blocks = split_include_blocks(lines)

    # Output filenames intentionally stay obvious and boring.
    models = {
        'full': 'docker-compose.full-vpn.yaml',
        'mini': 'docker-compose.mini-vpn.yaml',
        'no':   'docker-compose.no-vpn.yaml',
    }

    for model, filename in models.items():
        out_lines: List[str] = []
        for block_name, block_lines in blocks:
            out_lines.extend(transform_block(block_name, block_lines, model))
        target = outdir / filename
        target.write_text(''.join(out_lines), encoding='utf-8', newline='')
        print(f"[INFO] Wrote {target}")

    print("")
    print("[DONE] Multiple network security models generated.")
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except ModelError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        raise SystemExit(1)
