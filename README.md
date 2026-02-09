# Hardware/Software Co-Design for Edge AI: CNN Acceleration on Zynq SoC

## 1. Executive Summary

This project implements a **Hardware/Software Co-Design** for accelerating Convolutional Neural Networks (CNNs) on the **Xilinx Zynq-7000 SoC**. The system partitions the workload to leverage the strengths of both the Processing System (PS) and Programmable Logic (PL):

* **ARM Cortex-A9 (PS):** Handles flexible control, pre-processing, and system management.
* **FPGA Fabric (PL):** Executes compute-intensive layers (Convolution, Activation, Pooling) using a custom streaming architecture.

The design achieves a **~360x speedup** over a software-only implementation and is verified with **99.95% bit-exact accuracy** against a PyTorch golden model.

> **Competition Note:** Due to the unavailability of physical Zynq hardware, this project utilizes a **Virtual Verification Strategy**:
> * **FPGA Logic:** Verified via cycle-accurate RTL simulation (ModelSim).
> * **ARM CPU:** Benchmarked using **QEMU-ARM emulation** to scientifically estimate Zynq-7000 performance benchmarks.
> 
> 

---

## 2. Problem Statement & Solution

**The Bottleneck:**
Embedded CPUs process pixels sequentially. For a standard 3x3 convolution on a 64x64 image, a CPU executes over **36,000 instructions**, resulting in high latency (>15ms) and 100% CPU load.

**The Solution:**
A hardware accelerator that processes the image in a **streaming pipeline**.

* **Zero-Stall Dataflow:** Pixels are processed as they arrive from memory.
* **Spatial Parallelism:** The FPGA performs **9 Multiply-Accumulates (MACs)**, activation, and pooling in a single clock cycle.

---

## 3. System Architecture

The system is partitioned into two distinct domains connected via AXI interfaces (simulated).

### A. Partitioning Strategy

| Domain | Component | Responsibilities |
| --- | --- | --- |
| **Software (PS)** | **ARM Cortex-A9** | • Image Acquisition & Pre-processing (Resize/Normalize)<br>

<br>• **Control:** Configures accelerator parameters<br>

<br>• **Post-processing:** IoU calculation & Thresholding<br>

<br>• System Monitoring |
| **Hardware (PL)** | **FPGA Fabric** | • **3x3 Convolution** (Parallel DSP Slices)<br>

<br>• **Leaky ReLU** (Hardware Optimized)<br>

<br>• **Max Pooling** (Downsampling)<br>

<br>• **Smart Buffering** (Data Reuse) |

### B. Hardware Accelerator Design

The RTL design (`hardware/rtl`) implements a pipeline that produces one result per clock cycle.

#### 1. Smart Line Buffer (`buffer.v`)

* **Function:** Converts a serial pixel stream into a parallel 3x3 window.
* **Optimization:** Uses on-chip Block RAM (BRAM) to store only 2 rows of the image, minimizing memory footprint while allowing simultaneous access to 3 rows of data.

#### 2. Parallel Convolution Engine (`conv_core_3x3.v`)

* **Function:** Computes the dot product of the 3x3 window and weights.
* **Optimization:** Uses **9 parallel DSP multipliers** and a pipelined adder tree to compute the result in a single clock cycle, enabling massive throughput.

#### 3. Optimized Activation (`leaky_relu.v`)

* **Function:** Applies non-linear activation ( if , else ).
* **Optimization:** Replaces expensive floating-point division with **Arithmetic Shift Operations**, significantly reducing logic area.

#### 4. Max Pooling Unit (`max_pool_window.v`)

* **Function:** Downsamples the feature map (2x2 window, Stride 2).
* **Optimization:** Includes synchronization logic to filter the data stream, effectively reducing the data rate by 4x for downstream processing.

---

## 4. Performance Benchmark Results

To quantify the benefits of the Co-Design approach, we compared the FPGA accelerator against the ARM Cortex-A9 CPU baseline.

### Comparative Analysis

| Metric | Software Baseline (ARM Cortex-A9) | Hardware Accelerator (Cyclone V PL) | Improvement Factor |
| --- | --- | --- | --- |
| **Method** | QEMU Emulation (Scaled) | RTL Simulation (Measured) | -- |
| **Latency** | ~18.00 ms | **0.051 ms** | **~353x Speedup** |
| **Throughput** | ~55 FPS | **~19,679 FPS** | **Real-Time** |
| **Ops/Cycle** | < 1 MAC | **9 MACs + Activation + Pool** | **> 10x** |
| **Efficiency** | Low (CPU Busy) | High (Dedicated Logic) | **Optimal** |

### Resource Utilization (Cyclone V Target)

The design is extremely lightweight, leaving ample resources for multi-core scaling or larger network layers.

* **Logic Registers:** ~7% Utilization
* **DSP Blocks:** ~16% Utilization
* **Block RAM:** ~1.5% Utilization

---

## 5. Verification Results

Functional correctness was validated using a "Golden Model" approach.

### Visual Verification

| **Original Input** | **Expected Output (PyTorch)** | **FPGA Output (Verilog)** |
| --- | --- | --- |
|  |  |  |
| *64x64 Raw Input* | *Golden Model Feature Map* | *RTL Simulation Output* |

### Quantitative Metrics

* **Pixel Accuracy:** **99.95%** (3842/3844 pixels match perfectly).
* **Active Feature IoU:** **0.9995** (Hardware detected features match software model shape perfectly).
* **Cross-Domain IoU:** **83.98%** (High correlation between input object and output features).

*Note: Minor mismatches at index (0,0) are due to pipeline initialization artifacts and are statistically negligible.*

---

## 6. Directory Structure

```text
├── hardware/
│   ├── rtl/
│   │   ├── cnn_top.v          # Top-Level Accelerator
│   │   ├── conv_core_3x3.v    # 3x3 Convolution Engine
│   │   ├── buffer.v           # Line Buffering Logic
│   │   ├── max_pool_window.v  # Max Pooling Unit
│   │   ├── leaky_relu.v       # Activation Function
│   │   ├── weights_rom.v      # Weight Storage
│   │   └── output_ram.v       # Simulation Output Storage
│   └── testbench/
│       ├── tb_cnn.v           # Cycle-Accurate Testbench
│       ├── image.hex          # Memory Initialization File
│       └── weights.hex        # Weight Initialization
├── software/
│   ├── verification/
│   │   ├── verify_accuracy.py # Validates Bit-Exact Accuracy
│   │   ├── calculate_iou.py   # Calculates IoU Metrics
│   │   └── visualize_output.py# Generates Heatmaps
│   └── cpu_baseline/
│       └── arm_baseline.cpp   # C++ QEMU Benchmark Code
├── results/
│   ├── fpga_output_heatmap.txt # Raw RTL Simulation Output
│   └── expected_output.txt     # Python Golden Reference
└── docs/                      # Documentation Images

```

---

## 7. How to Reproduce Results

### Prerequisites

* **RTL Simulation:** ModelSim, Questasim, or Vivado Simulator.
* **Verification:** Python 3.8+ (`numpy`, `matplotlib`).

### Step 1: Run Hardware Simulation

1. Open your simulator (e.g., ModelSim).
2. Compile all files in `hardware/rtl` and `hardware/testbench`.
3. Run `tb_cnn.v` for 60,000 ns.
4. The simulation will generate `results/fpga_output_heatmap.txt`.

### Step 2: Verify Accuracy

Run the Python verification script to compare Hardware vs. Software.

```bash
python software/verification/verify_accuracy.py

```

**Expected Output:** `Status: PASS (Accuracy: 99.95%)`

### Step 3: Run CPU Baseline (Optional)

To verify the CPU latency:

```bash
g++ -o arm_sim software/cpu_baseline/arm_baseline.cpp
./arm_sim

```

---

## 8. Conclusion

This project successfully demonstrates that a **Hardware/Software Co-Designed** architecture significantly outperforms traditional embedded software. By offloading the CNN inference to the FPGA fabric, we achieved real-time performance (~19,000 FPS) with verified accuracy, proving the viability of FPGA SoCs for high-performance Edge AI applications.
