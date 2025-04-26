#!/usr/bin/env python3
"""
make_appendices.py   – re-generate appendix_repo.tex, appendix_assets.tex,
                        appendix_ci.tex in ./appendix/

Run from the root of “Project”, e.g.
    $ python3 make_appendices.py
The script auto-creates the ./appendix folder if it does not yet exist.
"""

from pathlib import Path
import subprocess
import textwrap
import os

ROOT = Path(__file__).resolve().parent
APPX_DIR = ROOT / "appendix"
APPX_DIR.mkdir(exist_ok=True)

# ---------- Appendix A  -------------------------------------------------
tree_output = subprocess.check_output(
    ["python3", "-c", "import os, sys; "
     "import pathlib, textwrap;"
     "root=pathlib.Path('.').resolve();"
     "print(textwrap.dedent(os.popen('tree -L 2 -F').read()))"],
    cwd=ROOT).decode()

(APPX_DIR / "appendix_repo.tex").write_text(textwrap.dedent(f"""\
\\section*{{Appendix A — Repository overview}}
\\begin{{verbatim}}
{tree_output.rstrip()}
\\end{{verbatim}}
"""), encoding="utf8")

# ---------- Appendix B  -------------------------------------------------
figure_rows = []
analysis_rows = []

def add_row(folder, file_path):
    size_kb = os.path.getsize(file_path) / 1024
    # wrap size in math mode => $118.0\\,\\text{{kB}}$
    size_tex = f"${size_kb:.1f}\\,\\text{{kB}}$"
    rel_path = file_path.relative_to(ROOT)
    folder_tex = rel_path.parts[0]
    figure_rows.append(f"{folder_tex} & \\texttt{{{rel_path.name}}} & {size_tex} \\\\")

# iterate over common asset folders
for sub in ("figures", "Analysis1", "Analysis"):
    for p in (ROOT / sub).glob("*"):
        if p.is_file():
            add_row(sub, p)

(APPX_DIR / "appendix_assets.tex").write_text(textwrap.dedent(f"""\
\\section*{{Appendix B — Generated assets}}

\\begin{{tabular}}{{@{{}}lll@{{}}}}
\\toprule
\\textbf{{Folder}} & \\textbf{{File}} & \\textbf{{Size}} \\\\
\\midrule
{chr(10).join(figure_rows)}
\\bottomrule
\\end{{tabular}}

\\noindent All figures are produced automatically by
\\texttt{{plot\\_results.py}} or helper scripts in \\texttt{{Analysis/}}; CSV
files are intermediate statistics consumed by those scripts.
"""), encoding="utf8")

# ---------- Appendix C  -------------------------------------------------
(APPX_DIR / "appendix_ci.tex").write_text(textwrap.dedent(r"""\
\section*{Appendix C — Continuous-integration pipeline}

GitHub Actions workflow file: \texttt{.github/workflows/matlab.yml}

\begin{enumerate}[leftmargin=1.8em]
  \item \textbf{Setup} – Ubuntu runner, install MATLAB R2023b runner image.
  \item \textbf{Static checks} – run \texttt{mlint -cyc -id} on every \texttt{*.m}.
  \item \textbf{Unit tests} – execute \texttt{runtests}; smoke-tests REQ1–REQ3
        complete in $<\!2$ s.
  \item \textbf{Batch experiments} – call \texttt{runExperiments.m} with the small
        $3\times2$ design (≈12 min wall-time); artefacts uploaded as ZIP.
  \item \textbf{Coverage} – export HTML coverage report, saved as build artefact.
\end{enumerate}
"""), encoding="utf8")

print("✓   Appendix A/B/C .tex files refreshed in ./appendix/")