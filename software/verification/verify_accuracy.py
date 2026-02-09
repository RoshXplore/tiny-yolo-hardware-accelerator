import numpy as np

def calculate_hardware_metrics():
    try:
        # Load Expected Output (Ground Truth from PyTorch)
        exp_flat = np.loadtxt("expected_output.txt", dtype=np.int32)
        exp_imgs = exp_flat.reshape(4, 31, 31)

        # Load FPGA Output (Parsing 64-bit Hex from RTL simulation)
        fpga_flat = []
        with open("fpga_output_heatmap.txt", "r") as f:
            for line in f:
                hex_str = line.strip()
                if not hex_str: continue
                full_val = int(hex_str, 16)
                for i in range(4):
                    # Extract 16-bit signed integers from the packed hex
                    chunk = (full_val >> (i * 16)) & 0xFFFF
                    if chunk >= 32768: chunk -= 65536
                    fpga_flat.append(chunk)
        
        # Reshape Interleaved (Pixel, Channel) to (Channel, Pixel)
        arr = np.array(fpga_flat).reshape(-1, 4).T
        fpga_imgs = arr.reshape(4, 31, 31)
        
        # Metrics
        matches = np.sum(exp_imgs == fpga_imgs)
        total = exp_imgs.size
        accuracy = (matches / total) * 100
        
        print(f"{'VERIFICATION REPORT':=^40}")
        print(f"Total Pixels:       {total}")
        print(f"Exact Matches:      {matches}")
        print(f"Mismatches:         {total - matches}")
        print(f"Pixel Accuracy:     {accuracy:.4f}%")
        print("-" * 40)
        
        if accuracy > 99.0:
            print("✅ STATUS: PASS")
        else:
            print("❌ STATUS: FAIL")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    calculate_hardware_metrics()