# CNN Accelerator in Verilog

A simple CNN-style image processing pipeline implemented in Verilog and verified using RTL simulation.

This project implements the core operations commonly used in convolutional neural networks:

* 3×3 Convolution
* Leaky ReLU Activation
* Max Pooling
* Streaming Line Buffer Architecture

The design was simulated and verified using ModelSim/QuestaSim, with outputs compared against a reference software model generated in Python.

---

# Project Overview

The goal of this project was to understand how basic CNN operations can be implemented directly in hardware using Verilog.

Instead of executing convolution sequentially like software running on a CPU, the hardware processes image data in a streaming and pipelined manner. Different stages of the pipeline operate simultaneously, allowing continuous processing of incoming pixels.

The design focuses on:

* understanding RTL-based CNN computation,
* streaming image processing,
* hardware pipelining,
* and verification against software-generated outputs.

---

# Processing Pipeline

```text
Input Image
     ↓
Line Buffer
     ↓
3×3 Convolution
     ↓
Leaky ReLU
     ↓
Max Pooling
     ↓
Output RAM
```

---

# Architecture Explanation

## 1. Line Buffer (`buffer.v`)

Convolution requires access to neighboring pixels around the current pixel.
Since image pixels arrive sequentially, the design uses a line buffer to generate sliding 3×3 windows.

The buffer stores previous image rows and continuously outputs a valid 3×3 neighborhood for convolution.

### Example Window

```text
P1 P2 P3
P4 P5 P6
P7 P8 P9
```

This allows the convolution module to process pixels continuously without repeatedly accessing external memory.

---

## 2. Convolution Core (`conv_core_3x3.v`)

This module performs a 3×3 convolution operation.

Each output pixel is computed as:

```text
Output =
(P1×W1) + (P2×W2) + ... + (P9×W9)
```

where:

* `P` = input pixels
* `W` = kernel weights

The module performs parallel multiply-accumulate operations to compute convolution outputs efficiently in hardware.

---

## 3. Leaky ReLU Activation (`leaky_relu.v`)

After convolution, the output passes through a Leaky ReLU activation function.

The activation is defined as:

```text
f(x) = x          if x > 0
f(x) = 0.1x       if x < 0
```

This helps preserve small negative values instead of completely zeroing them out.

In hardware, the negative scaling is implemented using shift-based arithmetic to simplify logic.

---

## 4. Max Pooling (`max_pool_window.v`)

The pooling module performs 2×2 max pooling.

It reduces the feature-map dimensions by selecting the maximum value from each 2×2 region.

### Example

```text
1 3
5 2
```

Output:

```text
5
```

Pooling helps reduce data size while preserving dominant features.

---

## 5. Output Storage (`output_ram.v`)

Processed feature-map outputs are written into output RAM during simulation.

The stored outputs are later compared against reference software outputs for verification.

---

## 6. Top-Level Module (`cnn_top.v`)

This module connects all processing stages together:

* line buffer,
* convolution,
* activation,
* pooling,
* and output storage.

It acts as the complete CNN processing pipeline.

---

# Verification Results

The hardware output was verified against a reference software model generated in Python/PyTorch.

## Visual Verification

The images below compare:

* the original input image,
* the expected software-generated output,
* and the output produced by the Verilog simulation.

|          **Original Input**          |     **Expected Output (PyTorch)**     |       **RTL Output (Verilog)**      |
| :----------------------------------: | :-----------------------------------: | :---------------------------------: |
| ![Original](docs/original_image.png) | ![Expected](docs/expected_output.png) | ![RTL Output](docs/fpga_output.png) |
|          *64×64 Input Image*         |        *Reference Feature Map*        |         *Simulation Output*         |

---

## Quantitative Metrics

* **Pixel Accuracy: 99.95%**

* 3842 out of 3844 pixels matched the software reference output.

* **Active Feature IoU: 0.9995**

* Confirms strong agreement between the software and RTL outputs.

> Minor mismatches near the first output pixels are caused by pipeline initialization during the initial clock cycles.

---

# Directory Structure

```text
├── cnn_top.v
├── buffer.v
├── conv_core_3x3.v
├── leaky_relu.v
├── max_pool_window.v
├── output_ram.v
├── weights_rom.v
├── tb_cnn.v
├── tb_debug.v
├── docs/
│   ├── original_image.png
│   ├── expected_output.png
│   └── fpga_output.png
└── software/
    └── verification/
        └── verify_accuracy.py
```

---

# Running the Simulation

## Using ModelSim / QuestaSim

Compile all Verilog files:

```bash
vlog *.v
```

Start simulation:

```bash
vsim tb_cnn
```

Run the simulation:

```bash
run -all
```

The simulation generates output feature-map data which can be used for verification.

---

# Step 2: Verify Accuracy

Run the Python verification script to compare the Hardware Output against the Software Golden Model.

```bash
python software/verification/verify_accuracy.py
```

## Expected Output

```text
=============METRIC REPORT==============
Total Pixels:       3844
Exact Matches:      3842
Pixel Accuracy:     99.95%
Active Pixel IoU:   0.9995
Status:             PASS
```

---

# Testbenches

## `tb_cnn.v`

Main RTL testbench used for:

* loading image data,
* driving the CNN pipeline,
* and generating output feature maps.

## `tb_debug.v`

Used for debugging intermediate signals and validating module behavior during development.

---


# Future Improvements

Possible future extensions include:

* Multi-channel convolution support
* Parameterised kernel sizes
* Multiple convolution layers
* AXI-stream interface integration
* FPGA deployment and hardware validation
* Fixed-point optimization

---

# Tools Used

* Verilog HDL
* ModelSim 
* Python
* NumPy
* PyTorch
* Google Colab


---

# Author

Roshan Sharma
