import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

# --- 1. Define Lennard-Jones potential function ---
def lj_potential(r, epsilon, sigma):
    return 4 * epsilon * ((sigma / r)**12 - (sigma / r)**6)

# --- 2. Load data ---
file_path = "example_Ar_Ar.txt"  # Replace with your filename
data = np.loadtxt(file_path, comments="#")
distances, energies = data[:, 0], data[:, 1]

# --- 3. Fit LJ potential ---
p0 = [0.01, 3.5]
bounds = ([0.00001, 1.0], [10.0, 10.0])
popt, _ = curve_fit(lj_potential, distances, energies, p0=p0, bounds=bounds, maxfev=10000)
epsilon_fit, sigma_fit = popt

# --- 4. Estimate r_min and rcut ---
r_dense = np.linspace(min(distances), max(distances), 5000)
E_dense = lj_potential(r_dense, *popt)
r_min = r_dense[np.argmin(E_dense)]
rcut = next((r for r, e in zip(r_dense, E_dense) if r > r_min and abs(e) < 0.001), r_dense[-1])
rcut_smth = round(rcut - r_min, 4)

# --- 5. Save plot ---
plt.figure(figsize=(8, 5))
plt.plot(distances, energies, 'bo', label='DFT Data')
plt.plot(r_dense, E_dense, 'r-', label='LJ Fit')
plt.axvline(rcut, color='green', linestyle='--', label=f'rcut ≈ {rcut:.2f} Å')
plt.axvline(r_min, color='purple', linestyle='--', label=f'r_min ≈ {r_min:.2f} Å')
plt.xlabel("Distance (Å)")
plt.ylabel("Energy (eV)")
plt.title("Lennard-Jones Fit to Dimer Energy")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("lj_fit_example_Ar_Ar.png")

# --- 6. Write rcut and r_min info to file ---
with open("rcut_info.txt", "w") as f:
    f.write(f"Fitted epsilon (eV): {epsilon_fit:.6f}\n")
    f.write(f"Fitted sigma (Å): {sigma_fit:.6f}\n")
    f.write(f"Minimum energy distance r_min (Å): {r_min:.4f}\n")
    f.write(f"rcut (Å) where |E| < 1 meV beyond r_min: {rcut:.4f}\n")
    f.write(f"Suggested rcut_smth = rcut - r_min: {rcut_smth:.4f}\n")
