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
