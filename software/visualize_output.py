import matplotlib.pyplot as plt
import numpy as np
import cv2

def generate_github_plots():
    # Load Image.hex (64x64)
    orig_data = []
    with open("image.hex", 'r') as f:
        for line in f:
            clean = line.split('//')[0].strip()
            if clean: orig_data.append(int(clean, 16))
    orig_img = np.array(orig_data).reshape(64, 64)

    # Load Expected Output (Filter 2)
    exp_flat = np.loadtxt("expected_output.txt", dtype=np.int32)
    exp_f2 = exp_flat.reshape(4, 31, 31)[2]

    # Load FPGA Output (Filter 2)
    fpga_data = []
    with open("fpga_output_heatmap.txt", 'r') as f:
        for line in f:
            val = int(line.strip(), 16)
            chunk = (val >> 32) & 0xFFFF # Filter 2
            if chunk >= 32768: chunk -= 65536
            fpga_data.append(chunk)
    fpga_f2 = np.array(fpga_data).reshape(31, 31)

    # Plot 1: Original
    plt.imsave("docs/original_image.png", orig_img, cmap='gray')
    
    # Plot 2: Expected Heatmap
    plt.imsave("docs/expected_output.png", exp_f2, cmap='viridis')
    
    # Plot 3: FPGA Heatmap
    plt.imsave("docs/fpga_output.png", fpga_f2, cmap='viridis')

    print("✅ PNG images saved to /docs folder for GitHub README.")

if __name__ == "__main__":
    import os
    os.makedirs("docs", exist_ok=True)
    generate_github_plots()