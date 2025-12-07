# i2c-address-translator
FPGA based i2c address translator.\
A hardware module that dynamically remaps I²C addresses so multiple identical I²C devices (same default address) can coexist on a single bus. The FPGA acts as an upstream I²C slave and a downstream I²C master and transparently forwards reads/writes while translating addresses.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Repository Structure](#repository-structure)
- [How to Simulate](#how-to-simulate)
- [How to Build on FPGA](#how-to-build-on-fpga)
- [Documentation](#documentation)
- [Author](#author)

## Overview

Many I²C sensors share the same default 7-bit address (for example, 0x48). If two identical sensors are connected on the same bus the master cannot communicate individually with each sensor. This project presents an FPGA-based translator that remaps a *virtual* address to a *physical* device address and forwards transactions seamlessly.

## Features

- Acts as upstream I²C Slave and downstream I²C Master
- Translates virtual → physical 7-bit addresses
- Supports Read and Write transactions
- Maintains I²C timing (100 kHz and 400 kHz)
- Modular RTL (FSMs, shift registers, counters)
- Simulation-ready with testbenches

## Repository Structure

i2c-address-translator/\
├─ README.md\
├─ docs/\
│  ├─ ARCHITECTURE.md\
│  ├─ FSM.md\
│  ├─ ADDRESS_TRANSLATION.md\
│  ├─ SIMULATION.md\
│  ├─ FPGA_BUILD.md\
│  └─ DESIGN_CHALLENGES.md\
├─ rtl/\
│  ├─ i2c_address_translator.v    <-- top module\
│  ├─ slave_fsm.v\
│  ├─ master_fsm.v\
│  ├─ i2c_bitbang_master.v        <-- downstream master engine\
│  └─ i2c_slave_core.v\
├─ tb/\
│  ├─ tb_top.v\
│  ├─ tb_master_model.v\
│  └─ tb_slave_models.v\
├─ sim/                            <-- EDA Playground project files\
│  └─ eda_playground_project.txt\
└─ report/\
   └─ resource_report.txt

## How to Simulate

### EDA Playground (recommended)
1. Go to https://edaplayground.com  
2. Create a new Verilog project and upload files from `rtl/` and `tb/`  
3. Set `tb/tb_top.v` as the top module and run (Icarus Verilog or Verilator)

### Local (Icarus Verilog)
```bash
iverilog -o simv tb/tb_top.v rtl/*.v
vvp simv
gtkwave dump.vcd

```
## How to Build on FPGA

1. Create a new project in Quartus/Vivado.
2. Add `rtl/*.v` and set `i2c_address_translator.v` as top module.
3. Add clock constraint (example for 50 MHz): `create_clock -name clk -period 20.0 [get_ports clk]`
4. Assign pins for SDA/SCL and add pull-ups (2.2k–4.7kΩ) on each bus.
5. Synthesize, program, and validate with a microcontroller master.

## Documentation

See the `docs/` folder for:
- `ARCHITECTURE.md`  
- `FSM.md`  
- `ADDRESS_TRANSLATION.md`  
- `SIMULATION.md`  
- `FPGA_BUILD.md`  
- `DESIGN_CHALLENGES.md`

## Author

**Author:** Bhavya Pandya  

