# FEA notes

`fea/legacy_first_FEA_script.m` is the first FEA script. It gave von Mises
stresses of ~0.14 MPa for 120 kN because:

1. No plate thickness: the 2D plane-stress stiffness was implicitly per
   metre of thickness, i.e. a 1 m thick steel plate.
2. 120 kN spread evenly over a whole edge, a fully restrained opposite
   edge: uniform compression, no stress concentration.
3. `griddata` from element centres left the plate border as NaN, then set
   to 0, so the dark/blue borders in its plots were artefacts.
4. Strain colourbar scaled twice (×10⁻³ label and ×10⁻⁴ axis exponent).

`fea/F1_Sled_Plate_FEA.m` replaces it (thickness, design load from the
dynamic model, contact patch, discrete cylinder supports, element-to-node
averaging, mesh-convergence study).

Python cross-check (`tools/python_reference_fea.py`), 20 mm S355 deck,
600 kN design load:

| Load case | Mesh | Max VM (MPa) | VM > 0.1 m from supports (MPa) | SF | Max u (mm) |
|---|---|---|---|---|---|
| Centred | 20×10 | 50.9 | 50.9 | 6.97 | 0.198 |
| Centred | 40×20 | 64.1 | 56.8 | 6.25 | 0.203 |
| Centred | 80×40 | 84.8 | 59.1 | 6.01 | 0.205 |
| Module end | 20×10 | 82.2 | 75.0 | 4.73 | 0.373 |
| Module end | 40×20 | 115.5 | 83.3 | 4.26 | 0.385 |
| Module end | 80×40 | 163.6 | 90.0 | 3.94 | 0.391 |

Max VM grows without limit at the sharp support edges (singularity); the
values away from the supports and the displacements converge.
Not covered: out-of-plane bending of the deck (load applied above the
deck), plate buckling, welds/bolts, fatigue — need a 3D shell model.
