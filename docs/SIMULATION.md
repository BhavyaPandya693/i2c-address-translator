# Simulation Guide

This document explains how to simulate the FPGA-based I²C Address Translator using both **EDA Playground** and **local simulation tools** such as **Icarus Verilog**.  
The simulation environment validates correct address translation, FSM operation, and data forwarding behavior.

---

## 1. Testbench Overview

The repository includes the following testbench files:

| File | Description |
|------|-------------|
| `tb_top.v` | Top-level testbench that instantiates the translator and all models |
| `tb_master_model.v` | Behavioral I²C master model driving upstream transactions |
| `tb_slave_models.v` | Simulated downstream I²C slave devices (physical address = 0x48) |

### What simulation verifies:
- Upstream master sends to virtual addresses (`0x49`, `0x4A`)
- FPGA LUT translates to physical address (`0x48`)
- Correct downstream bus is selected (Bus 0, Bus 1)
- Read/Write data is passed correctly
- STOP/START sequences are handled cleanly

---

## 2. Using EDA Playground (Recommended)

This is the easiest way to simulate without installing anything.

### Steps:
1. Open: https://edaplayground.com  
2. Create a **new Verilog project**  
3. Upload the following directories:
   - `rtl/`  
   - `tb/`  
4. Set:
   - **Top Module:** `tb_top`
   - **Simulator:** *Icarus Verilog* or *Verilator*

5. Click **Run** to view console output and generate waveforms.

### Expected Output:
- Master sends write and read transactions  
- FPGA acknowledges only mapped virtual addresses  
- Downstream devices respond correctly  
- DATA_RX and DATA_TX activity visible in waveform  

Waveform file (.vcd) will show:
- Upstream SDA/SCL
- Downstream SDA/SCL for Bus 0 and Bus 1
- Slave FSM and Master FSM states
- Address mapping selection

---

## 3. Running Simulation Locally (Icarus Verilog)

If you prefer local simulation:

### Compile:
```bash
iverilog -o simv tb/tb_top.v rtl/*.v
```
### Run:
```bash
vvp simv
```
### Open Waveform:
```bash
gtkwave dump.vcd
```
### Expected wave signals:

- `sda_main`, `scl_main`
- `sda_bus0`, `scl_bus0`
- `sda_bus1`, `scl_bus1`
- `slave_state`, `master_state`
- Address and data shift registers

# 4. What to Look For in Waveforms

## START Detection
The Slave FSM should transition from:

```
IDLE → ADDR_RX
```

---

## Virtual Address Match
When the upstream master sends:

- `0x49` → FPGA must activate **Bus 0**
- `0x4A` → FPGA must activate **Bus 1**

---

## Correct Downstream Address Frame
The waveform should show the correct translation from **virtual** to **physical** addresses:

```yaml
Virtual: 0x49 → Physical: 0x48
Virtual: 0x4A → Physical: 0x48
```

---

## Read Transactions
Downstream device responds → FPGA forwards the data back to the upstream master.

---

## Write Transactions
Master → FPGA → Device (data forwarding).

---

##  STOP Condition
STOP must cleanly return all FSMs to:

```
IDLE
```
# Example Simulation Time (Conceptual)
```ini
t=0      START
t=+10us  Master sends 0x49
t=+20us  FPGA maps to 0x48 (Bus 0)
t=+30us  Downstream device ACKs
t=+40us  Data bytes exchanged
t=+50us  STOP
```
## 6. Common Issues and Debug Tips

### Slave does not ACK virtual address

Check:

- LUT configuration in `i2c_address_translator.v`
- Bits of address shift register

---

### Downstream bus not toggling

Verify:

- `master_fsm` is triggered correctly  
- Correct bus ID is selected  

---

### No waveform output

Ensure the following exists in `tb_top.v`:

```verilog
$dumpfile("dump.vcd");
$dumpvars;
```
# 7. Simulation Files Summary

| Directory | Purpose                                      |
|----------|-----------------------------------------------|
| `rtl/`   | Design source code                            |
| `tb/`    | Testbench + master/slave behavioral models    |
| `sim/`   | EDA Playground project file reference         |

# 8. Conclusion
Simulation validates correct functionality of the I²C Address Translator before FPGA deployment.
Once behavior matches expected results, the design is ready for synthesis and hardware testing.
