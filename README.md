# Round-Robin Arbiter (C & Verilog Implementation)

## Overview
This repository contains a **fair, starvation-free round-robin arbiter** implemented in both **C (behavioral reference model)** and **Verilog (synthesizable RTL)**.

The design was developed as part of a **Shared Resource Arbiter** problem, where multiple independent requesters compete for access to a single shared resource. The arbiter guarantees:
- At most one grant per cycle
- Exactly one grant if any request is active
- Fairness and starvation freedom for persistent requests
- Deterministic, cycle-accurate behavior
- No use of fixed-priority arbitration

---

## Arbitration Strategy

The arbiter uses a **rotating-priority (round-robin)** mechanism:

- A pointer (`last_granted_index`) tracks the most recently granted requester.
- On each cycle, arbitration begins from the **next requester** in circular order.
- If no request is found before reaching the end, the search **wraps around** to index 0.
- The first active request encountered is granted.
- The pointer updates **only when a grant occurs**, preserving fairness.

This approach guarantees that any requester holding its request high will eventually be granted access.

---

## Repository Structure

├── arbiter.c # C reference model

├── arbiter.v # Verilog round-robin arbiter (RTL)

├── tb_round_robin_arbiter.v # Verilog testbench

└── README.md # This file


## C Implementation

### Purpose
- Acts as a **behavioral reference model**
- Demonstrates cycle-accurate arbitration logic
- Useful for algorithm validation and debugging

### Key Properties
- Scalable to arbitrary N
- Deterministic arbitration
- Explicit wrap-around handling
- Includes random traffic testing

### How to Compile and Run
```bash
gcc arbiter.c -o arbiter
./arbiter
```

## Verilog Implementation
### Design Characteristics
-Synthesizable, Verilog-2005 compatible

-Parameterized number of requesters (N)

-No fixed-priority encoder

-Explicit reset semantics

-One-hot grant output

### Key Signals

-req[N-1:0] : Request vector

-gnt[N-1:0] : Grant vector (one-hot)

-last_granted_index : Rotating priority pointer

### Testbench

The Verilog testbench validates:

-Single-grant enforcement

-No grant when no requests are active

-Correct rotating priority behavior

-Correct wrap-around behavior

-Deterministic cycle-by-cycle operation

### How to Implement 
```bash
iverilog -o out arbiter.v tb_round_robin_arbiter.v
vvp out
```
VIEW THE LOGS TO SEE RESULTS
