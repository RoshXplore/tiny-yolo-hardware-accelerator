%%writefile cnn_arm_sim.cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <chrono>
#include "image_data.h"

// --- Standard Tiny-YOLO-style Weights (Simplified for Benchmark) ---
// We use integer math to match your FPGA implementation
const int KERNEL_SIZE = 3;
const int WEIGHTS[3][3] = {
    { -1, 0, 1 },
    { -2, 0, 2 },
    { -1, 0, 1 }
};

// --- 1. Convolution (3x3) ---
int convolve(int r, int c, const std::vector<int>& img, int width) {
    int sum = 0;
    for (int ky = 0; ky < 3; ky++) {
        for (int kx = 0; kx < 3; kx++) {
            int pixel_val = img[(r + ky) * width + (c + kx)];
            sum += pixel_val * WEIGHTS[ky][kx];
        }
    }
    return sum;
}

// --- 2. ReLU Activation ---
int relu(int val) {
    return (val > 0) ? val : 0;
}

int main() {
    // Convert input array to vector for easier handling
    std::vector<int> image(input_image, input_image + (IMG_W * IMG_H));
    std::vector<int> conv_output(IMG_W * IMG_H, 0);
    std::vector<int> pool_output((IMG_W/2) * (IMG_H/2), 0);

    std::cout << "Starting Software Inference on ARM Cortex-A9 Simulation..." << std::endl;

    // === START TIMER ===
    auto start = std::chrono::high_resolution_clock::now();

    // 1. CONVOLUTION & RELU LAYER
    for (int y = 0; y < IMG_H - 2; y++) {
        for (int x = 0; x < IMG_W - 2; x++) {
            int conv_val = convolve(y, x, image, IMG_W);
            conv_output[y * IMG_W + x] = relu(conv_val);
        }
    }

    // 2. MAX POOLING LAYER (2x2)
    int pool_idx = 0;
    for (int y = 0; y < IMG_H - 2; y += 2) {
        for (int x = 0; x < IMG_W - 2; x += 2) {
            int max_val = -999999;
            // Check 2x2 window
            max_val = std::max(max_val, conv_output[y * IMG_W + x]);         // Top-Left
            max_val = std::max(max_val, conv_output[y * IMG_W + (x + 1)]);   // Top-Right
            max_val = std::max(max_val, conv_output[(y + 1) * IMG_W + x]);   // Bottom-Left
            max_val = std::max(max_val, conv_output[(y + 1) * IMG_W + (x + 1)]); // Bottom-Right

            pool_output[pool_idx++] = max_val;
        }
    }

    // === STOP TIMER ===
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);

    std::cout << "Inference Complete." << std::endl;
    std::cout << "Output Size: " << pool_idx << " pixels" << std::endl;
    std::cout << "Time Taken: " << duration.count() << " microseconds (" << duration.count() / 1000.0f << " ms)" << std::endl;

    return 0;
}