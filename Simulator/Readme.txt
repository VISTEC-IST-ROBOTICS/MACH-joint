# MACH-joint Full Energy Breakdown Simulator

MATLAB-based interactive simulator for visualizing the deformation, kinematics, and energy distribution of a MACH-joint compliant mechanism composed of four helical links.

The simulator provides:
- Real-time 3D visualization
- Helical link deformation analysis
- Bending and twisting energy distribution
- Interaction force and moment estimation using energy gradients

---

# Features

- Interactive GUI using MATLAB `uifigure`
- Real-time deformation visualization
- Side-view and 3D-view rendering
- Per-link elongation tracking
- Curve axis angle monitoring
- Strain energy calculation
- Twisting energy calculation
- Numerical interaction force estimation
- Color-mapped deformation visualization

---

# System Overview

The MACH-joint consists of four helical links arranged at phase shifts:

- 0
- π/2
- -π/2
- π

Each link deforms according to:
- bending curvature
- axial displacement
- helix winding parameter

The simulator evaluates:
- geometric deformation
- axial strain
- twisting deformation
- total system energy

---

# Requirements

- MATLAB R2020b or newer recommended
- No additional toolboxes required

---

# Running the Simulator

Run the MATLAB script:

```matlab
MACH_joint_simulator