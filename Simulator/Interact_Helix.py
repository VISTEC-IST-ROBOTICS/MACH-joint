import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from matplotlib.gridspec import GridSpec
import matplotlib.cm as cm

# ===== Constants =====
s_lamda = 1.0
L_0 = s_lamda * 35.97
r = s_lamda * 11.0
k_link = s_lamda * 5.0

# Twisting Constants
E_mod = 2300.0  # MPa
b = 1.97  # mm
I_area = (b ** 4) / 12  # mm^4
phi_init = 0.69  # rad
k_tw = (4.5 * E_mod * I_area) / L_0


# ===== Fast Energy Helper (Optimized for Gradients) =====
def compute_total_energy(q_f, q_b, dT_z):
    q_b = max(q_b, 1e-5)
    # Using fewer points for gradient calculation to maintain high FPS
    u = np.linspace(0, q_f, 20)
    v = np.linspace(0, q_b, 20)

    val_sqrt = L_0 ** 2 - r ** 2 * q_f ** 2
    T_z = np.sqrt(val_sqrt) if val_sqrt > 0 else 0.0
    R = max((T_z + dT_z) / q_b, 1e-6)
    shifts = [0, np.pi / 2, -np.pi / 2, np.pi]

    U_total = 0
    for shift in shifts:
        Sx = r * np.cos(u + shift)
        Sy = R * np.cos(v) - R + r * np.sin(u + shift) * np.cos(v)
        Sz = R * np.sin(v) + r * np.sin(u + shift) * np.sin(v)

        # Numerical arc length
        dL = np.sqrt(np.diff(Sx) ** 2 + np.diff(Sy) ** 2 + np.diff(Sz) ** 2)
        L_b = np.sum(dL)

        eps_b = (L_0 - L_b)
        # Twisting logic
        phi_c = np.arctan2(np.sqrt(max(0, L_b ** 2 - (r * q_f) ** 2)), (r * q_f))

        U_total += 0.5 * k_link * (eps_b ** 2) + 0.5 * k_tw * (phi_c - phi_init) ** 2
    return U_total


# ===== Figure Setup =====
fig = plt.figure('MACH-joint Full Analysis', figsize=(14, 9))
gs = GridSpec(3, 2, figure=fig, height_ratios=[1, 1, 1], hspace=0.4, wspace=0.25)
fig.subplots_adjust(bottom=0.15, top=0.92, left=0.08, right=0.95)

axSide = fig.add_subplot(gs[2, 0])
axIso = fig.add_subplot(gs[2, 1], projection='3d')
axBar = fig.add_subplot(gs[0, 0])
axPhi = fig.add_subplot(gs[1, 0])
axEngB = fig.add_subplot(gs[0, 1])
axEngT = fig.add_subplot(gs[1, 1])

# Plot handles
lines_side = [axSide.plot([], [], lw=1.5)[0] for _ in range(4)]
center_side, = axSide.plot([], [], 'b--', alpha=0.6)
lines_iso = [axIso.plot([], [], [], lw=1.5)[0] for _ in range(4)]
center_iso, = axIso.plot([], [], [], 'b--', alpha=0.6)

x_pos = np.arange(4)
bars_eps = axBar.bar(x_pos, np.zeros(4), edgecolor='k')
bars_phi = axPhi.bar(x_pos, np.zeros(4), edgecolor='k')
bars_engB = axEngB.bar(x_pos, np.zeros(4), edgecolor='k')
bars_engT = axEngT.bar(x_pos, np.zeros(4), edgecolor='k')

# Labels and Limits
axSide.set(title='Side View (y-z)', xlim=(-22, 22), ylim=(0, 42))
axIso.set(title='3D Isometric View', xlim=(-20, 20), ylim=(-20, 20), zlim=(0, 40))
axIso.view_init(elev=15, azim=65)

axBar.set(title='Link Elongation', ylabel='$\epsilon_b$ [mm]', ylim=(-6, 6))
axPhi.set(title='Pitch Angle', ylabel='$\phi$ [rad]', ylim=(0, 1.6))
axEngB.set(title='Bending Energy', ylabel='$U_b$ [mJ]', ylim=(0, 110))
axEngT.set(title='Twisting Energy', ylabel='$U_{tw}$ [mJ]', ylim=(0, 110))

for ax in [axBar, axPhi, axEngB, axEngT]:
    ax.set_xticks(x_pos)
    ax.set_xticklabels(['0', '$\pi/2$', '$-\pi/2$', '$\pi$'])
    ax.grid(True, axis='y', alpha=0.3)

force_text = fig.text(0.5, 0.02, "", ha='center', fontsize=11, fontweight='bold',
                      bbox=dict(facecolor='white', alpha=0.8, edgecolor='gray'))

# ===== Sliders =====
ax_q = fig.add_axes([0.15, 0.10, 0.3, 0.02])
ax_qb = fig.add_axes([0.55, 0.10, 0.3, 0.02])
ax_dTz = fig.add_axes([0.55, 0.06, 0.3, 0.02])

slider_q = Slider(ax_q, 'q ', np.pi / 2, 3.0, valinit=0.8 * np.pi)
slider_qb = Slider(ax_qb, '$q_b$ ', 0.0001, 1.0, valinit=0.0004)
slider_dTz = Slider(ax_dTz, '$dT_z$ ', -5.0, 5.0, valinit=0.0)


# ===== Update Function =====
def update(val):
    q_f = slider_q.val
    q_b = max(slider_qb.val, 1e-5)
    dT_z = slider_dTz.val

    u = np.linspace(0, q_f, 60)
    v = np.linspace(0, q_b, 60)

    val_sqrt = L_0 ** 2 - r ** 2 * q_f ** 2
    T_z = np.sqrt(val_sqrt) if val_sqrt > 0 else 0.0
    R = max((T_z + dT_z) / q_b, 1e-6)
    shifts = [0, np.pi / 2, -np.pi / 2, np.pi]

    eps_vals, phi_vals = [], []

    for k, shift in enumerate(shifts):
        Sx = r * np.cos(u + shift)
        Sy = R * np.cos(v) - R + r * np.sin(u + shift) * np.cos(v)
        Sz = R * np.sin(v) + r * np.sin(u + shift) * np.sin(v)

        dL = np.sqrt(np.gradient(Sx, u) ** 2 + np.gradient(Sy, u) ** 2 + np.gradient(Sz, u) ** 2)
        L_b = np.trapezoid(dL, x=u)

        eps = L_0 - L_b
        phi = np.arctan2(np.sqrt(max(0, L_b ** 2 - (r * q_f) ** 2)), (r * q_f))

        eps_vals.append(eps)
        phi_vals.append(phi)

        color = cm.turbo(min(abs(eps) / 4.0, 1.0))
        lines_side[k].set_data(Sy, Sz)
        lines_side[k].set_color(color)
        lines_iso[k].set_data_3d(Sx, Sy, Sz)
        lines_iso[k].set_color(color)

    # Centerline logic
    cy, cz = R * np.cos(v) - R, R * np.sin(v)
    center_side.set_data(cy, cz)
    center_iso.set_data_3d(np.zeros_like(v), cy, cz)

    # Energy calculations
    eps_vals = np.array(eps_vals)
    phi_vals = np.array(phi_vals)
    ub_vals = 0.5 * k_link * (eps_vals ** 2)
    utw_vals = 0.5 * k_tw * (phi_vals - phi_init) ** 2

    # Update Bars
    for k in range(4):
        c = cm.turbo(min(abs(eps_vals[k]) / 4.0, 1.0))
        bars_eps[k].set_height(eps_vals[k]);
        bars_eps[k].set_color(c)
        bars_phi[k].set_height(phi_vals[k]);
        bars_phi[k].set_color(c)
        bars_engB[k].set_height(ub_vals[k]);
        bars_engB[k].set_color(c)
        bars_engT[k].set_height(utw_vals[k]);
        bars_engT[k].set_color(c)

    # Gradients for Interaction Forces
    d = 0.001
    F_z = (compute_total_energy(q_f, q_b, dT_z + d) - compute_total_energy(q_f, q_b, dT_z - d)) / (2 * d)
    M_b = (compute_total_energy(q_f, q_b + d, dT_z) - compute_total_energy(q_f, q_b - d, dT_z)) / (2 * d * 1000)

    force_text.set_text(
        f"F_z: {F_z:+.3f} N  |  M_b: {M_b:+.3f} N.m  | Total Energy: {np.sum(ub_vals + utw_vals):.2f} mJ")
    fig.canvas.draw_idle()


slider_q.on_changed(update)
slider_qb.on_changed(update)
slider_dTz.on_changed(update)

update(0)
plt.show()