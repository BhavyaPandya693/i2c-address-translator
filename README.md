# i2c-address-translator
FPGA based i2c address translator.\
A hardware module that dynamically remaps I²C addresses so multiple identical I²C devices (same default address) can coexist on a single bus. The FPGA acts as an upstream I²C slave and a downstream I²C master and transparently forwards reads/writes while translating addresses.\
