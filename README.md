Here is the complete, modified `README.md`. It includes the **Usage** section and is formatted for immediate use in your repository.

---

# Hardware-Accelerated CNN Inference using FPGA HW/SW Co-Design

## Overview

This repository contains the design and verification of a hardware-accelerated convolutional neural network (CNN) inference pipeline implemented using FPGA-oriented RTL modules and hardware/software co-design principles.

The project focuses on accelerating compute-intensive CNN operations such as convolution, activation, and pooling in FPGA fabric, while control logic and post-processing are assumed to be handled by a processor. The design is kept platform-agnostic and targets FPGA-based heterogeneous SoCs in general.

Verification is performed using cycle-accurate RTL simulation and software reference comparison.

---

## Design Goals

* Implement a lightweight CNN inference pipeline suitable for edge AI workloads
* Accelerate convolution, activation, and pooling using FPGA-style hardware modules
* Demonstrate correct functionality through RTL simulation
* Quantitatively evaluate detection quality using Intersection over Union (IoU)
* Maintain a clean hardware/software partitioning model

---

## System Architecture

The system is partitioned into software-controlled and hardware-accelerated components.

### Software Responsibilities

* Image loading and preprocessing
* Control and sequencing of CNN execution
* Post-processing (IoU computation / NMS)
* Result inspection and evaluation

### Hardware Responsibilities

* Sliding-window generation using line buffers
* Pipelined 3×3 convolution
* Leaky ReLU activation
* 2×2 max pooling
* Feature map buffering

---

## Hardware Modules

The RTL design is composed of the following synthesizable modules:

* `line_buffer_yolo.v`
Generates aligned 3×3 sliding windows from a streaming pixel input using dual line buffers.


* `conv_core_3x3.v`
Implements a pipelined multiply–accumulate (MAC) unit for 3×3 convolution.


* `leaky_relu.v`
Applies leaky ReLU activation using arithmetic shift for negative values.


* `max_pool_window.v`
Performs 2×2 max pooling with stride 2 using window-based buffering.


* `output_ram.v`
Stores the output feature map for inspection and software-side processing.


* `cnn_top.v`
Top-level integration module coordinating the data path and control flow.



---

## Verification Methodology

The design is verified using RTL simulation with ModelSim.

* Input images and weights are loaded from memory initialization files.
* The CNN pipeline processes the image in a streaming manner.
* Output feature maps are written to a RAM module.
* Results are read back and compared against a software reference implementation.

All modules are simulated together as an integrated system.

---

## Usage

### Prerequisites

* ModelSim or Questasim for RTL simulation
* Python 3.x (with NumPy) for verification

### Simulation Steps

1. **Generate Inputs:** Run `python software/cpu_reference.py` to generate `image.hex` and `weights.hex`.
2. **Run Simulation:**
```bash
vlog hardware/rtl/*.v hardware/testbench/tb_cnn.v
vsim -c -do "run -all" tb_cnn

```


3. **Verify Results:** Run `python software/post_processing.py` to parse `fpga_output_heatmap.txt` and calculate IoU.

---

## Detection Evaluation

Detection quality is evaluated using the Intersection over Union (IoU) metric.

* **Intersection Pixels:** 48
* **Union Pixels:** 88
* **IoU Score:** 0.5455

An IoU score above 0.5 indicates correct spatial localization for the tested input and validates functional correctness of the hardware pipeline.

---

## Performance Analysis

Due to the absence of physical FPGA hardware, performance metrics are analytically estimated.

* Pipelined architecture processes one pixel per clock cycle
* Convolution operations are suitable for DSP-based implementation
* Line buffers and feature maps map naturally to block RAM
* Projected throughput demonstrates more than 2× speedup over a CPU-only CNN implementation

These estimates are based on typical FPGA operating frequencies and standard resource mapping assumptions.

---

## Limitations

* No physical FPGA deployment was performed
* Power consumption is not measured
* Current implementation demonstrates a single-filter CNN pipeline
* Detection head and full multi-class YOLO output are not implemented in hardware

---

## Future Work

* Multi-channel and multi-filter CNN support
* Hardware-based detection head (1×1 convolution)
* Deployment on FPGA-based heterogeneous SoCs
* Integration with camera input and real-time video stream
* Hardware/software co-optimization using HLS

---

## Repository Structure

```text
hardware/
  rtl/
    line_buffer_yolo.v
    conv_core_3x3.v
    leaky_relu.v
    max_pool_window.v
    output_ram.v
    cnn_top.v
  testbench/
    tb_cnn.v
software/
  cpu_reference.py
  post_processing.py
results/
  fpga_output_heatmap.txt
  iou_report.txt

```

---

## Summary

This project demonstrates a complete, verified CNN inference pipeline designed using FPGA-oriented hardware principles. The work emphasizes correct dataflow, pipelined computation, and clean HW/SW partitioning, validated through RTL simulation and quantitative evaluation.
