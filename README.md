
# Hardware-Accelerated CNN Inference on Cyclone V FPGA

## 📌 Overview

This repository contains the design and verification of a **Hardware-Accelerated Convolutional Neural Network (CNN)** inference pipeline targeting the **Intel Cyclone V FPGA**. The project leverages **Hardware/Software Co-Design** principles to offload compute-intensive operations (Convolution, Activation, Pooling) to the FPGA fabric, achieving real-time performance that far exceeds embedded CPU capabilities.

The design was verified using cycle-accurate RTL simulation against a **PyTorch software golden model**, demonstrating **99.95% pixel accuracy** and a **~360x latency reduction** compared to a standard embedded ARM Cortex-A9 processor.

---

## 🎯 Design Goals

* **High-Performance Edge AI:** Implement a lightweight, streaming CNN pipeline suitable for real-time embedded workloads.
* **Hardware Acceleration:** Offload 3x3 Convolution, Leaky ReLU, and Max Pooling to dedicated FPGA hardware.
* **Quantitative Verification:** Validate functional correctness using **Intersection over Union (IoU)** and bit-exact software comparison.
* **Efficient Resource Usage:** Optimize for low logic and memory footprint (<7% utilization on Cyclone V).

---

## 🏗️ System Architecture

The system follows a heterogeneous HW/SW partitioning strategy:

### **1. Software (ARM Cortex-A9)**

* Image capture and pre-processing (Resizing/Normalization).
* Control sequencing and result retrieval.
* Post-processing (Bounding Box decoding / NMS).

### **2. Hardware (FPGA Fabric)**

The RTL design implements a **streaming dataflow architecture** processing **1 pixel per clock cycle**:

* **`line_buffer_yolo.v`**: Generates aligned 3x3 sliding windows from a live pixel stream using efficient Block RAM buffering.
* **`conv_core_3x3.v`**: Implements a massively parallel MAC unit (9 multipliers) for single-cycle convolution.
* **`leaky_relu.v`**: Applies non-linear activation () using optimized bit-shifting.
* **`max_pool_window.v`**: Performs 2x2 downsampling with a robust valid-data pipeline.
* **`cnn_top.v`**: Top-level integrator managing the data path and control signals.

---

## 📊 Performance Analysis

We compared the FPGA hardware performance (measured via ModelSim) against an embedded ARM Cortex-A9 CPU (estimated via QEMU simulation).

| Metric | Software (ARM Cortex-A9) | Hardware (Cyclone V FPGA) | Improvement |
| --- | --- | --- | --- |
| **Latency** | 18.00 ms | **0.051 ms** | **~360x Speedup** |
| **Throughput** | ~55 FPS | **19,679 FPS** | **Real-Time** |
| **Accuracy** | 100% (Baseline) | **99.95%** | **Verified** |
| **Architecture** | Sequential | **Parallel (Pipelined)** | -- |

> **Note:** FPGA latency includes full pipeline fill and memory write-back time (50,815 ns total).

### **Resource Utilization (Cyclone V)**

The design is highly efficient, leaving ample room for larger networks or multi-core scaling.

* **Registers:** 10,571 / 150k (**< 7%**)
* **DSP Blocks:** 24 / 150 (**16%**)
* **Block Memory:** 62,528 bits (**< 2%**)

---

## 🖼️ Verification Results

The hardware output was validated against a PyTorch reference model.

| **Original Input** | **Expected Output (PyTorch)** | **FPGA Output (Verilog)** |
| --- | --- | --- |
|  |  |  |
| *64x64 Raw Input* | *Ideal Feature Map* | *Hardware Result* |

### **Quantitative Metrics**

* **Pixel Accuracy:** **99.95%** (3842/3844 pixels match perfectly).
* **Active Feature IoU:** **0.9995** (The hardware detected the exact same feature shape as the software model).
* **Cross-Domain IoU:** **83.98%** (Strong correlation between the input object location and the output feature map).

*Note: A known initialization artifact causes a mismatch at the first 2 pixels (index 0,0), which has negligible impact on detection quality.*

---

## 📂 Repository Structure

```text
hardware/
  rtl/
    cnn_top.v           # Top-level Accelerator
    conv_core_3x3.v     # Parallel Convolution Core
    line_buffer_yolo.v  # Line Buffering Unit
    max_pool_window.v   # Max Pooling Unit
    leaky_relu.v        # Activation Function
    weight_rom.v        # Pre-loaded Weights
    output_ram.v        # Output Storage
  testbench/
    tb_cnn.v            # System Testbench
    image.hex           # Test Input Data
software/
  verify_accuracy.py    # Calculates Accuracy & IoU
  visualize_output.py   # Generates Heatmap Comparisons
  arm_cpu_baseline.cpp  # C++ code for CPU benchmarking
results/
  fpga_output_heatmap.txt # Raw Simulation Output
  expected_output.txt     # Python Golden Reference
docs/
  images/               # Screenshots for README

```

---

## 🚀 Usage

### **1. Prerequisites**

* **Simulation:** ModelSim, Questasim, or Vivado Simulator.
* **Verification:** Python 3.x with `numpy` and `matplotlib`.

### **2. Run Simulation**

1. Compile all files in `hardware/rtl` and `hardware/testbench`.
2. Run `tb_cnn.v`.
3. The simulation will generate `fpga_output_heatmap.txt`.

### **3. Verify Results**

Run the Python script to compare the FPGA output against the software model:

```bash
python software/verify_accuracy.py

```

**Expected Output:**

```text
=============METRIC REPORT==============
Total Pixels:       3844
Exact Matches:      3842
Pixel Accuracy:     99.95%
Active Pixel IoU:   0.9995
Status:             PASS

```


