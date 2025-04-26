#!/usr/bin/env python3
"""
fix_tex_assets.py ──────────────────────────────────────────────────────────
  • Parses report.tex (and any \input'd .tex files) to collect every file
    referenced via:
        \includegraphics{...}
        \input{...}
        \lstinputlisting{...}
  • Verifies that the file exists relative to the project root.
  • If it does NOT exist, tries to find a single obvious candidate and either
        (a) renames the candidate  →  expected_path
        OR  (b) copies the candidate, depending on --copy flag.
  • Writes a short report of what was fixed and what is still unresolved.

Typical usage
-------------
$ python fix_tex_assets.py                  # rename missing assets
$ python fix_tex_assets.py --copy           # copy instead of rename
$ python fix_tex_assets.py --dry            # just report

The script makes NO changes outside the project directory.
"""

from __future__ import annotations
import argparse, re, shutil, sys
from pathlib import Path
from collections import defaultdict

# ------------------------------------------------------------
# Settings you might tweak
# ------------------------------------------------------------
PROJECT_ROOT   = Path.cwd()
TEX_MAIN       = PROJECT_ROOT / "report.tex"
SEARCH_EXTS    = [".png", ".pdf", ".jpg", ".tex", ".csv", ".m", ".py"]
CANDIDATE_DIRS = [
    PROJECT_ROOT / "figures",
    PROJECT_ROOT / "Analysis",
    PROJECT_ROOT / "Analysis" / "Analysis1",
    PROJECT_ROOT / "analysis",
    PROJECT_ROOT / "appendix",
]

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
INC_PATTERNS = [
    r'\\includegraphics(?:\[[^\]]*])?{([^}]+)}',
    r'\\lstinputlisting(?:\[[^\]]*])?{([^}]+)}',
    r'\\input{([^}]+)}'
]
COMPILED_RE = [re.compile(p) for p in INC_PATTERNS]

def tex_deps(tex_file: Path) -> set[Path]:
    """Return a set of relative paths referenced in a .tex file."""
    deps = set()
    text = tex_file.read_text(encoding="utf8", errors="ignore")
    for cre in COMPILED_RE:
        for m in cre.finditer(text):
            deps.add(Path(m.group(1)))
    # recurse into \input'ed .tex files
    for dep in list(deps):
        if dep.suffix in {"", ".tex"}:
            f = (PROJECT_ROOT / dep).with_suffix(".tex")
            if f.exists():
                deps |= tex_deps(f)
    return deps

def find_candidate(missing: Path) -> Path | None:
    """Return a *single* best-guess candidate file for a missing asset."""
    base = missing.stem.lower()           # stem without extension
    for d in CANDIDATE_DIRS:
        for ext in SEARCH_EXTS:
            cand = d / (base + ext)
            if cand.exists():
                return cand
    return None

def fix_asset(missing: Path, candidate: Path, copy=False, dry=False):
    dst = PROJECT_ROOT / missing
    dst.parent.mkdir(parents=True, exist_ok=True)
    action = "copied" if copy else "moved"
    if dry:
        print(f"[DRY] would {action}: {candidate}  →  {dst}")
        return
    if copy:
        shutil.copy2(candidate, dst)
    else:
        shutil.move(candidate, dst)
    print(f"[OK]  {action:6s}: {candidate.relative_to(PROJECT_ROOT)}  →  {missing}")

# ------------------------------------------------------------
# main
# ------------------------------------------------------------
def main():
    p = argparse.ArgumentParser(description="Auto-fix missing LaTeX assets")
    p.add_argument("--copy", action="store_true",
                   help="copy instead of rename (default: rename)")
    p.add_argument("--dry",  action="store_true",
                   help="dry-run: just report, no changes")
    args = p.parse_args()

    # 1. collect every referenced file
    deps = tex_deps(TEX_MAIN)
    missing = [p for p in deps if not (PROJECT_ROOT / p).exists()]

    if not missing:
        print("✓ All referenced assets already exist — nothing to do.")
        return

    still_missing: list[Path] = []
    print(f"→ Found {len(missing)} missing asset(s). Attempting to fix…")

    for m in missing:
        cand = find_candidate(m)
        if cand:
            fix_asset(m, cand, copy=args.copy, dry=args.dry)
        else:
            still_missing.append(m)

    # summary
    if still_missing:
        print("\nThe following assets could not be resolved; please inspect manually:")
        for pth in still_missing:
            print("  ·", pth)
    else:
        print("✓ All missing assets repaired.")

if __name__ == "__main__":
    main()