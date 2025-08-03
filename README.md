# Multi-Core RC4 Decryption Circuit

A high-performance, multi-core RC4 decryption and brute-force cracking circuit implemented on FPGA using VHDL and SystemVerilog.

**Academic Integrity Notice**  
- Reuse of any code or implementation details from this project without proper authorization may constitute academic misconduct.  
- If you are a student or educator referencing this project for coursework or research, **you must contact me for permission** before using any part of this work.

## Project Overview

This project implements a parallelized RC4 decryption system on an FPGA, featuring modular design and synchronized finite state machines. It includes both a single-key decryption circuit and a 4-core brute-force keyspace exploration engine.

## Technologies Used

- **SystemVerilog** & **VHDL** - For hardware design
- **Intel Quartus Prime** - Hardware synthesis
- **ModelSim** - Simulation and verification
- **SignalTap** - On-chip debugging and analysis
- **DE1-SoC FPGA Board** - FPGA hardware used for deployment

## Features

- **Single-Key RC4 Decryption**: 
  - Uses on-chip ROM to store an encrypted message
  - User-provided key via FPGA hardware switches
  - Decrypted output written to RAM

- **Finite State Machines (FSMs)**:
  - Modular, cleanly abstracted FSMs for key scheduling (KSA) and pseudo-random generation (PRGA)
  - Inter-module synchronization via start-finish handshake protocol

- **Multi-Core Brute-Force Engine**:
  - 4 parallel decryption cores cycle through the entire keyspace
  - Circuit halts upon successful decryption detection
  - Achieves over **400% speedup** compared to single-core operation

## How It Works

1. **Initialization**: 
   - Encrypted message is pre-loaded into ROM
   - User provides a secret key via slider switches

2. **Decryption Phase**: 
   - FSMs coordinate key scheduling and decryption
   - Decrypted output is written to RAM and can be monitored or extracted

3. **Brute-Force Mode**:
   - Cores independently iterate through keyspace
   - Shared success flag halts the system on valid decryption match

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/ldanh2023/RC4-Decryption-Circuit.git
   cd RC4-Decryption-Circuit