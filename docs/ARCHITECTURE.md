# ARCHITECTURE — I²C Address Translator

## Overview
The FPGA-based I²C Address Translator sits between an upstream I²C master and multiple downstream I²C devices with identical addresses. It maps a *virtual address* to a *physical device address* so the master can talk to multiple identical devices without address conflicts.

---

## Block Diagram (ASCII)

![Untitled Diagram(1)](https://github.com/user-attachments/assets/94833e20-32fa-4126-ac35-7c4116664971)
