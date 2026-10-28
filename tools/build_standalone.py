"""Build single-file MATLAB scripts (case + whole engine) for MATLAB Online.

Usage:  python3 tools/build_standalone.py
Writes standalone/CaseXX_..._STANDALONE.m for every script in cases/.
"""
import glob, os, re

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = sorted(glob.glob(os.path.join(root, 'src', '*.m')))
engine = "".join("\n" + open(f).read().rstrip() + "\n" for f in src)

for case in sorted(glob.glob(os.path.join(root, 'cases', 'Case*.m'))):
    body = open(case).read()
    body = body.replace(
        "here = fileparts(mfilename('fullpath'));\naddpath(fullfile(here, '..', 'src'));\n",
        "% STANDALONE: the whole simulation engine is included at the bottom of this file.\n")
    body = re.sub(r"fullfile\(here, '\.\.', 'results', '(case\d+)'\)", r"fullfile(pwd, 'results_\1')", body)
    assert 'here' not in body.split('% STANDALONE')[1], case
    name = os.path.basename(case).replace('.m', '_STANDALONE.m')
    with open(os.path.join(root, 'standalone', name), 'w') as fh:
        fh.write(body.rstrip() + "\n\n\n%% =====================================================================\n"
                 "%                SIMULATION ENGINE (generated from src/ — do not edit here)\n"
                 "%  =====================================================================\n" + engine)
    print('wrote', name)


# ---------------------------------------------------------------------------
# One file with ALL case studies + summary (for MATLAB Online)
# ---------------------------------------------------------------------------
cases = sorted(glob.glob(os.path.join(root, 'cases', 'Case*.m')))
parts = ["""%% =====================================================================
%  F1 SMART BARRIER — ALL 15 CASE STUDIES IN ONE FILE (generated)
%  ---------------------------------------------------------------------
%  Each crash: Case 1 real barrier | Case 2 TecPro | Case 3 complete system
%  small space (+20 cm) | Case 4 complete system large space (~2.6 m),
%  x 8 external conditions x impact angles, then a summary of all crashes.
%  Documented data, assumptions and sources for each crash are in the
%  header of cases/CaseXX_*.m and in REFERENCES.md of the repository.
%  Results go to ./results_all/. Runtime: several minutes.
%  =====================================================================
clear; clc; close all;
resultsDir = fullfile(pwd, 'results_all');
outs = {};
"""]
for case in cases:
    body = open(case).read()
    lines = [l for l in body.splitlines() if l.startswith('crash.')]
    title = [l for l in body.splitlines() if l.startswith('%  CASE STUDY')][0]
    cid = int(re.search(r'crash\.id\s*=\s*(\d+)', body).group(1))
    parts.append("\n%% " + title.lstrip('% ').strip() + "\ncrash = struct();\n" + "\n".join(lines) +
                 "\nouts{end+1} = runCaseStudy(crash, fullfile(resultsDir, 'case%02d'));\nclose all;\n" % cid)
parts.append("\n%% SUMMARY OF ALL CASE STUDIES\nsummarizeStudies(outs, resultsDir);\n")
with open(os.path.join(root, 'standalone', 'ALL_15_CASES_STANDALONE.m'), 'w') as fh:
    fh.write("".join(parts) + "\n\n%% =====================================================================\n"
             "%                SIMULATION ENGINE (generated from src/ — do not edit here)\n"
             "%  =====================================================================\n" + engine)
print('wrote ALL_15_CASES_STANDALONE.m')


# ---------------------------------------------------------------------------
# Breakpoint study as one file
# ---------------------------------------------------------------------------
bp = open(os.path.join(root, 'breakpoint', 'BreakpointStudy.m')).read()
bp = bp.replace("here = fileparts(mfilename('fullpath'));\naddpath(fullfile(here, '..', 'src'));\noutDir = fullfile(here, '..', 'results', 'breakpoint');",
                "% STANDALONE: the whole simulation engine is included at the bottom of this file.\noutDir = fullfile(pwd, 'results_breakpoint');")
assert "addpath" not in bp
with open(os.path.join(root, 'standalone', 'BreakpointStudy_STANDALONE.m'), 'w') as fh:
    fh.write(bp.rstrip() + "\n\n\n%% =====================================================================\n"
             "%                SIMULATION ENGINE (generated from src/ — do not edit here)\n"
             "%  =====================================================================\n" + engine)
print('wrote BreakpointStudy_STANDALONE.m')
