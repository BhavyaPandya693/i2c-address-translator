
# FSM — Slave & Master State Machines

## Overview
The translator uses two main finite state machines:
- `slave_fsm`: handles communication with upstream I²C master
- `master_fsm`: handles communication with downstream I²C devices

---

## Slave FSM States

| State | Description |
|-------|-------------|
| IDLE | Wait for START condition |
| ADDR_RX | Receive 7-bit address and R/W bit |
| ACK_TX | ACK/NACK response |
| DATA_RX | Receive data from master |
| DATA_TX | Send data to master |
| STOP_WAIT | Wait for STOP |

### Diagram

![fsm(1)](https://github.com/user-attachments/assets/f8b308a2-78ff-4206-aa2f-441997b733bd)


---

## Master FSM States

| State | Description |
|-------|-------------|
| M_IDLE | Waiting for command from slave FSM |
| M_START | Generate START condition |
| M_ADDR | Send physical address |
| M_ACK | Wait for device ACK |
| M_WRITE | Send data to device |
| M_READ | Read data from device |
| M_STOP | Send STOP |

### Flow Example

1. Slave FSM detects 0x49  
2. Slave FSM claims bus and requests downstream read  
3. Master FSM sends START  
4. Master FSM sends physical 0x48  
5. Master FSM reads bytes  
6. Slave FSM forwards them to upstream  

---

