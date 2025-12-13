# Simulation-Based Design and Verification of an I2C Address Translator System

## 1. Introduction

Inter-Integrated Circuit (I²C) is a widely used serial communication protocol for connecting multiple low-speed peripherals using a shared two-wire bus. In many practical systems, a controller may need to communicate with multiple devices while maintaining a layer of abstraction between logical addressing (used by firmware or higher-level controllers) and physical addressing (actual slave addresses on the bus).

This project presents the **design, implementation, and simulation-based verification** of an **I²C Address Translator System**. The system translates logical I²C addresses into physical slave addresses and enables seamless communication between a master and multiple slaves without modifying the master-side addressing scheme.

The entire design is implemented in **Verilog HDL** and verified through **functional simulation**, focusing on clarity, modularity, and educational value rather than full protocol compliance.

---

## 2. Project Objectives

The key objectives of this project are:

- To design a modular I²C-based system using Verilog HDL
- To implement an address translation layer between the controller and I²C master
- To model I²C master and slave behavior at the transaction level
- To verify correct logical-to-physical address mapping through simulation
- To observe and analyze I²C bus behavior using waveform inspection

---

## 3. System Architecture

The overall system consists of the following major blocks:

1. **Upstream Controller FSM** – Generates logical I²C transactions
2. **I²C Address Translator** – Maps logical addresses to physical slave addresses
3. **I²C Master** – Drives the I²C bus (SCL and SDA)
4. **Multiple I²C Slaves** – Respond to physical addresses
5. **Top-Level Integration Module** – Connects all components
6. **Testbench** – Provides clock, reset, and simulation control

### 3.1 Block-Level Overview

- The upstream controller issues read requests using *logical addresses*.
- The address translator converts logical addresses into corresponding *physical slave addresses*.
- The I²C master performs the actual bus-level communication.
- Multiple slaves are connected to the shared SDA and SCL lines using open-drain behavior.

---

## 4. Module Descriptions

### 4.1 I²C Master Module

The `i2c_master` module models a simplified I²C master interface. It accepts:

- Start signal
- 7-bit slave address
- Read/Write control
- Write data

And produces:

- Read data
- Busy and done status signals
- Acknowledgement error indication

The module drives the serial clock (`SCL`) and serial data (`SDA`) lines and interacts with slaves using open-drain signaling.

> **Note:** The master implementation is intentionally simplified for functional demonstration and does not implement full I²C features such as clock stretching or arbitration.

---

### 4.2 I²C Address Translator Module

The `i2c_addr_translator` module is the core contribution of this project. It performs:

- Logical-to-physical address mapping
- Control handshaking between upstream controller and downstream I²C master

#### Address Mapping

Logical addresses are compared against predefined parameters:

- `logical0 → physical0`
- `logical1 → physical1`
- `logical2 → physical2`

If no valid mapping exists, the transaction is terminated gracefully.

#### Finite State Machine

The translator FSM consists of four states:

- **IDLE** – Waiting for upstream request
- **LAUNCH_DN** – Launching downstream transaction
- **WAIT_DN** – Waiting for I²C master completion
- **DONE** – Reporting completion upstream

This FSM ensures proper synchronization and status propagation between system layers.

---

### 4.3 I²C Slave Module

Each `i2c_slave` module models a basic I²C slave device with:

- Configurable 7-bit address
- Open-drain SDA behavior
- Support for single-byte read and write operations

The slave uses separate FSMs triggered on:

- `posedge SCL` for data sampling
- `negedge SCL` for SDA driving

Each slave returns a constant, predefined data byte during read operations, allowing easy identification during waveform analysis.

---

### 4.4 Top-Level Integration Module

The `i2c_top_module` integrates:

- Address translator
- I²C master
- Three I²C slave instances
- Upstream control FSM

The upstream FSM sequentially issues read transactions to three logical addresses, demonstrating correct address translation and slave selection.

---

## 5. Testbench Description

The testbench (`tb_i2c_top_module`) is designed for **system bring-up and waveform-based verification**.

### Key Features:

- Generates a 50 MHz clock
- Applies an active-low reset
- Enables VCD waveform dumping
- Does not inject manual stimulus beyond reset

The system behavior is driven entirely by the internal controller FSM, making the testbench simple, robust, and focused on integration verification.

---

## 6. Simulation and Verification

Simulation is performed using a Verilog simulator (e.g., Icarus Verilog / EDA Playground).

### Observed Behavior:

- Logical addresses are correctly mapped to physical slave addresses
- Only the addressed slave responds on the SDA line
- Read data returned matches the predefined slave data
- Busy and done signals transition as expected

Waveform inspection confirms correct sequencing of:

- Address phase
- Acknowledgement phase
- Data transfer phase

---

## 7. Results and Analysis

### Obtained Results

- Successful communication between master and multiple slaves
- Correct logical-to-physical address translation
- Proper open-drain SDA behavior
- Clean FSM transitions across all modules

### Limitations

- Single-byte transactions only
- Simplified START/STOP detection
- No support for repeated START or clock stretching

These limitations are acceptable given the project’s educational and demonstrative scope.

---

## 8. Conclusion

This project successfully demonstrates the design and simulation-based verification of an **I²C Address Translator System** using Verilog HDL. The modular approach, combined with FSM-based control and waveform-driven verification, provides a clear understanding of I²C communication and address abstraction.

The design highlights how intermediate translation layers can be integrated into digital systems without altering existing masters or slaves, a concept applicable in embedded systems, SoC integration, and FPGA-based prototyping.

---

## 9. Future Work

Possible extensions include:

- Multi-byte read/write support
- Full I²C protocol compliance
- Clock stretching and arbitration handling
- Parameterized number of slaves
- Self-checking testbench with assertions

---

## 10. References
## References

1. NXP Semiconductors, *UM10204 – I²C-bus Specification and User Manual*.

2. Linux Kernel Documentation, *I²C Address Translators*,
   https://docs.kernel.org/i2c/i2c-address-translators.html

3. Hackaday, *LTC4316: The I²C “Babelfish” Address Translator*,
   https://hackaday.com/2017/02/17/ltc4316-is-the-i2c-babelfish/

4. AMD Adaptive Support Community, *I²C Address Translation Code in Verilog*,
   https://adaptivesupport.amd.com/s/question/0D52E00006hpbSrSAI/i2c-address-translation-code-in-verilog

5. Kashish Singh, *I²C Controller Using Verilog*,
   Medium,
   https://medium.com/@singhkashish170203/i2c-controller-using-verilog-bf7f77e9e861

6. Nexperia, *AN90044 – I²C Bus Address Translation and Multiplexing*,
   https://assets.nexperia.com/documents/application-note/AN90044.pdf
