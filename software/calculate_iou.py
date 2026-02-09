import numpy as np

def run_iou_check():
    # Load Expected and FPGA data
    exp_flat = np.loadtxt("expected_output.txt", dtype=np.int32)
    exp_imgs = exp_flat.reshape(4, 31, 31)

    fpga_flat = []
    with open("fpga_output_heatmap.txt", "r") as f:
        for line in f:
            full_val = int(line.strip(), 16)
            for i in range(4):
                chunk = (full_val >> (i * 16)) & 0xFFFF
                if chunk >= 32768: chunk -= 65536
                fpga_flat.append(chunk)

    fpga_imgs = np.array(fpga_flat).reshape(-1, 4).T.reshape(4, 31, 31)

    # Intersection over Union (Mask overlap)
    intersection = np.sum((exp_imgs != 0) & (fpga_imgs != 0))
    union = np.sum((exp_imgs != 0) | (fpga_imgs != 0))
    iou_score = intersection / union if union != 0 else 1.0

    print(f"{'IoU METRIC REPORT':=^40}")
    print(f"Active Pixel IoU:   {iou_score:.4f}")
    print(f"Status:             {'PASS' if iou_score > 0.99 else 'FAIL'}")

if __name__ == "__main__":
    run_iou_check()