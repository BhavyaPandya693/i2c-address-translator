# Address Translation Mechanism

## 1. Overview

The FPGA functions as an address remapper.  
When the upstream I²C master sends a transaction to a **virtual address**, the FPGA internally rewrites the request and forwards it to a **physical device address** on a selected downstream bus.

Example:

| Virtual Address | Physical Device Address | Downstream Bus |
|-----------------|------------------------|----------------|
| `0x49`          | `0x48`                 | Bus 1         |
| `0x4A`          | `0x48`                 | Bus 2         |

This allows multiple identical sensors (with the same factory address) to coexist on the same system.

---

## 2. Why Address Translation Is Needed

Many I²C devices have **fixed addresses**, like 0x48.  
If two of these sensors are connected to a single bus, the master cannot distinguish them.

Traditional solutions:
- Use hardware ADDR pins → often limited  
- Use analog muxes → breaks continuous reads  
- Use software bit-banging → slow and inefficient

**FPGA address translation solves this cleanly:**
- The master sends commands to `virtual` addresses (unique)
- FPGA forwards the frames to real devices without the master knowing

---

## 3. Address Mapping Table

Inside the FPGA, we maintain a small LUT:
![address_translator](https://github.com/user-attachments/assets/8d841b29-1133-4d5c-a3f6-9d9b669c24f4)

This table can be:
- Hardcoded (simple project)
- Configurable via registers (advanced version)
- Loaded at runtime (bonus points for evaluation)

---

## 4. Translation Flow (Detailed)

### **Step 1 — Upstream master sends address + R/W**
Slave FSM captures:
[7-bit address][R/W]

If the address matches any **virtual address** in the mapping table:
- FPGA **ACKs** the master  
- FPGA takes control (claims the transaction)

Otherwise:
- FPGA **NACKs** the master (not our transaction)

---

### **Step 2 — FPGA selects downstream physical device**
From mapping table:

![address_translator_2](https://github.com/user-attachments/assets/21f44123-ee73-472d-8e7e-d9757d2d5726)


Slave FSM sends a command to Master FSM:

command.type = READ or WRITE\
command.paddr = 0x48\
command.bus_id = 1


---

### **Step 3 — Master FSM generates a new START**
It rewrites the address frame:

- Upstream saw:  

![Untitled Diagram(2)](https://github.com/user-attachments/assets/2325b336-526d-4fb5-b3b1-6f0019be1915)

- Downstream device receives:  

![Untitled Diagram(3)](https://github.com/user-attachments/assets/703ec8b4-db58-4ecf-a998-22dbe967c203)

---

### **Step 4 — Data transfer**
Two possible cases:

#### **Write Operation**
Upstream master → FPGA → Physical device

- Slave FSM receives bytes  
- FPGA remaps → Master FSM forwards to device

#### **Read Operation**
Physical device → FPGA → Upstream master

- Master FSM fetches bytes from device  
- Slave FSM transmits them back to upstream master

---

### **Step 5 — STOP Condition**
- Upstream STOP triggers FPGA cleanup  
- Downstream STOP is sent by Master FSM  
- Transaction ends cleanly

---

## 5. ASCII Diagram

```text
Upstream Master         FPGA Translator                 Downstream Device
---------------        ------------------               ------------------
ADDR = 0x49   --->     Virtual match → map to 0x48 --->  Receives 0x48
                     Bus select = 1
                     Forward request
DATA bytes    --->     Forward bytes              --->   Device writes
                                   (Write case)

Device data   <---     Capture bytes              <---   Device sends
                     Return to upstream
                                   (Read case)
****
```
---
## 6. Example With Two Identical Sensors

Sensors both have the same physical address **0x48**.

### Mapping:

| Device    | Virtual | Physical | Bus   |
|-----------|---------|----------|-------|
| Sensor A  | 0x49    | 0x48     | Bus 0 |
| Sensor B  | 0x4A    | 0x48     | Bus 1 |

### Master communicates:
![example](https://github.com/user-attachments/assets/ac717851-5699-4dd3-92ca-6011364f36f4)

---
## 7. RTL Components Used for Translation

| Module                     | Role                                               |
|---------------------------|-----------------------------------------------------|
| `slave_fsm.v`             | Receives upstream address and checks mapping        |
| `master_fsm.v`            | Generates rewritten downstream frames               |
| `i2c_address_translator.v`| Top-level module linking FSMs + mapping logic       |
| `i2c_bitbang_master.v`    | Generates downstream SCL/SDA timing                 |
| **Mapping LUT**           | Converts virtual → physical address                 |

---
## 8. Future Enhancements

- Runtime programmable address table  
- Support for more than two downstream buses  
- Multi-byte burst forwarding  
- Clock stretching handling  
- Error injection for debugging  
- Full arbitration support  
