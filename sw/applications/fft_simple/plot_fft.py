#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# Read the CSV file
df = pd.read_csv('fft_results.csv')

# Create figure with subplots
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

# Plot real and imaginary parts
ax1.plot(df['Index'], df['Real'], 'b-', label='Real')
ax1.plot(df['Index'], df['Imaginary'], 'r-', label='Imaginary')
ax1.set_title('FFT Results - Real and Imaginary Parts')
ax1.set_xlabel('Frequency Index')
ax1.set_ylabel('Amplitude')
ax1.grid(True)
ax1.legend()

# Plot magnitude
ax2.plot(df['Index'], df['Magnitude'], 'g-')
ax2.set_title('FFT Results - Magnitude Spectrum')
ax2.set_xlabel('Frequency Index')
ax2.set_ylabel('Magnitude')
ax2.grid(True)

# Adjust layout and save
plt.tight_layout()
plt.savefig('fft_plot.png')
plt.close()

print("Plot saved as 'fft_plot.png'") 