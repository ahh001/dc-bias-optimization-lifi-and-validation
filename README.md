# DC Bias Optimization in DCO-OFDM Li-Fi Systems

This repository contains the implementation of a Li-Fi communication system combining MATLAB-based simulation, machine learning models, and real-time hardware validation using Arduino.

---

### Project Overview

The goal of this work is to optimize DC bias in DCO-OFDM Li-Fi systems using hybrid machine learning techniques. The study includes:

- Simulation-based dataset generation (MATLAB)
- Appply different machine learning models (Python)
- Real-time validation using Li-Fi hardware (Arduino + Photodiode)

---

# System Flow 

1. MATLAB Simulation
   - Generate DCO-OFDM signals
   - Create dataset for ML models

2. Machine Learning Models (Python)
   - Train multiple models
   - Compare performance
   - Select best model

3. Hardware Implementation (Arduino)
   - Transmit data using LED (Li-Fi)
   - Receive data using photodiode
   - Extract signal features (Mean, Min, Max, Std, BER, Bias)

4. Validation
   - Apply ML models on real hardware data
   - Verify consistency with simulation results

---

# Repository Structure

---
# How to Use
## 1. Generate Dataset
Run the MATLAB script:
---
## 2. Train ML Models
Run Models: 
---
## 3. Hardware Experiment
- Upload transmitter code to Arduino (LED side)
- Upload receiver code to Arduino (photodiode side)
- Collect output via Serial Monitor
- Save data as CSV for ML processing
---
## 4. Test Hardware Dataset on ML Models
- Load the hardware-generated dataset (CSV)
- Apply the same trained ML models
