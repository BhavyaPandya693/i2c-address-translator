# FPGA Build and Synthesis Guide

This document explains how to build, synthesize, and deploy the I²C Address Translator design on an FPGA using any mainstream tool such as **Intel Quartus**, **Xilinx Vivado**, or **Lattice Diamond**.  
The flow is vendor-independent and applies to all FPGA boards.

---

## 1. Requirements

You will need:

- An FPGA development board (Intel, Xilinx, or Lattice)
- FPGA toolchain installed:
  - Intel **Quartus Prime**
  - Xilinx **Vivado**
  - Lattice **Diamond/Radiant**
- USB-Blaster / JTAG programming cable
- Logic analyzer or oscilloscope (recommended)
- Pull-up resistors for I²C buses (typically **4.7 kΩ**)

The design uses only:

- Simple synchronous FSMs  
- Counters  
- Shift registers  

This ensures compatibility with all FPGA families.

---

## 2. Add Source Files to the Project

Add all RTL files from:
## RTL Directory Structure

- `i2c_address_translator.v` (top module)
- `slave_fsm.v`
- `master_fsm.v`
- `i2c_bitbang_master.v`
- `i2c_slave_core.v`


Set **i2c_address_translator.v** as the **Top Module**.

---

## 3. Pin Assignments

Assign FPGA pins to match your board headers:

### Required I/O:

| Signal | Direction | Notes |
|--------|-----------|-------|
| `sda_main` | inout | Connect to upstream I²C master SDA |
| `scl_main` | inout or input | Connect to upstream SCL |
| `sda_bus0` | inout | Downstream bus 0 SDA |
| `scl_bus0` | output or inout | Downstream bus 0 SCL |
| `sda_bus1` | inout | Downstream bus 1 SDA |
| `scl_bus1` | output or inout | Downstream bus 1 SCL |
| `clk` | input | Typically 25–100 MHz FPGA system clock |
| `reset_n` | input | Active-low reset |

Each I²C bus must also have:

- External pull-up resistors (3.3 V), 4.7kΩ recommended  
- Ensure **open-drain** behavior on SDA/SCL pins

---

## 4. Synthesis Settings

No special constraints are required, but the following should be considered:

### Recommended:

- **SCL frequency target:**  
  - Standard Mode: **100 kHz**  
  - Fast Mode: **400 kHz**

- Ensure system clock is high enough:  
  Example: 50 MHz FPGA clock → bit-bang master divides this down.

### Timing Constraints:

For advanced users, apply:

### Create_clock -name sys_clk -period 20.0 [get_ports clk]


(or match your board’s frequency)

---

## 5. Build Steps (Quartus & Vivado)

### Quartus:

1. Create a new project  
2. Add all RTL files  
3. Assign pins  
4. Compile (Processing → Start Compilation)  
5. Connect board through USB-Blaster  
6. Program using `.sof` file

### Vivado:

1. Create RTL project  
2. Add source files  
3. Set top module  
4. Run synthesis → implementation  
5. Generate bitstream  
6. Open Hardware Manager  
7. Program device

---

## 6. Hardware Testing Procedure

#### 1. Power the FPGA board  
Ensure pull-ups are properly connected.

#### 2. Connect external I²C master to upstream pins  
Example: Raspberry Pi, Arduino, or another FPGA.

#### 3. Connect sensors to downstream buses  
Both sensors must share the same physical address (e.g., **0x48**).

#### 4. Power-on reset  
FPGA should come up in IDLE states.

#### 5. Perform test transactions  
Master performs:\
-Read from 0x49\
-Read from 0x4A


Expected:

- FPGA converts:
  - 0x49 → 0x48 (Bus 0)
  - 0x4A → 0x48 (Bus 1)
- Correct bus toggles SDA/SCL  
- Sensors respond independently  

---

## 7. Debugging on Hardware

### If downstream busses do not toggle:
- Check bus mapping table  
- Check master FSM enable signal  
- Verify pull-ups on both buses  

### If upstream master gets NACK:
- Wrong virtual address  
- Address not in LUT  
- Timing mismatch between master and FPGA  

### If waveforms look distorted:
- Weak pull-ups  
- Incorrect pin configuration (not open-drain)  
- Too long wires → capacitance issues  

---

## 8. Resource Utilization (Typical)

For a small FPGA like Cyclone IV / Artix-7:

| Resource | Usage |
|---------|--------|
| LUTs | ~300–600 |
| Registers | ~200–300 |
| Block RAM | None |
| DSP | None |
| I/O Pins | 6–10 |

Usage may vary depending on optional features.

---

## 9. Notes for Real Hardware Performance

- Ensure clock domain is clean and stable  
- Avoid very long I²C cables (limit capacitance)  
- Check that downstream sensors operate within voltage levels of FPGA  
- For >400 kHz, redesign bit-bang master to support Fast+ mode  

---

## 10. Conclusion

Once programmed, the FPGA acts as a transparent address translator.  
The upstream master communicates normally using virtual addresses, and the FPGA handles all remapping, forwarding, and data integrity.

This completes the FPGA build and deployment process.

