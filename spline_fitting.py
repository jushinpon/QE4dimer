
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import PchipInterpolator
from sklearn.metrics import r2_score, mean_squared_error
import sys

# Command line usage:
# python script.py input.txt "Plot Title" output.png output.txt threshold
if len(sys.argv) != 6:
    print("Usage: python script.py input.txt \"Plot Title\" output.png output.txt threshold")
    sys.exit(1)

file_path = sys.argv[1]
plot_title = sys.argv[2]
output_image = sys.argv[3]
output_info = sys.argv[4]
cutoff_threshold = float(sys.argv[5])  # e.g., 0.001

# Load data
data = np.loadtxt(file_path, comments="#")
distances, energies = data[:, 0], data[:, 1]
r_min_data = distances[0]
r_max_data = distances[-1]
E_max_data = energies[-1]

# Fit monotonic spline (PCHIP)
spline = PchipInterpolator(distances, energies, extrapolate=True)

# Exponential decay function for extrapolation beyond max
def exponential_tail(r, r0, E0, k=1.5):
    return E0 * np.exp(-k * (r - r0))

# Define hybrid function: spline + exp decay
def hybrid_spline(r):
    e_spline = spline(r)
    exp_part = exponential_tail(r, r_max_data, E_max_data)
    return np.where(r > r_max_data, exp_part, e_spline)

# Dense evaluation over range [r_min, 10 Å]
r_dense = np.linspace(r_min_data, 10.0, 3000)
E_dense = hybrid_spline(r_dense)

# Metrics
spline_pred = spline(distances)
r2_spline = r2_score(energies, spline_pred)
rmse_spline = np.sqrt(mean_squared_error(energies, spline_pred))

# r_min and improved rcut detection with 10 Å cap
r_min = r_dense[np.argmin(E_dense)]
rcut_candidates = [(r, abs(e)) for r, e in zip(r_dense, E_dense)
                   if r > r_min and abs(e) < cutoff_threshold]
rcut = rcut_candidates[0][0] if rcut_candidates else 10.0

# Plot
plt.figure(figsize=(8, 5))
plt.plot(distances, energies, 'bo', label='Input Data')
plt.plot(r_dense, E_dense, 'm-', label=f'Hybrid Spline+Exp (R²={r2_spline:.4f}, RMSE={rmse_spline:.2e})')
plt.axvline(rcut, color='m', linestyle=':', label=f'rcut ≈ {rcut:.2f} Å')
plt.xlabel("Distance (Å)")
plt.ylabel("Energy (eV)")
plt.title(plot_title)
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig(output_image)

# Save summary info
with open(output_info, "w") as f:
    f.write("### Hybrid Monotonic Spline + Exponential Tail Fit Summary ###\n")
    f.write(f"r_min (Å): {r_min:.4f}\n")
    f.write(f"rcut (Å): {rcut:.4f}\n")
    f.write(f"R²: {r2_spline:.6f}\n")
    f.write(f"RMSE: {rmse_spline:.6e}\n")
    f.write(f"Energy threshold for rcut: {cutoff_threshold:.6e}\n")
