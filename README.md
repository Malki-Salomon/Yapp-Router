# Verification Environment for the YAPP Router

A UVM-based verification environment for a multi-channel **YAPP packet router**.
The environment drives directed and constrained-random traffic (including error
scenarios), configures the DUT through a host bus and a UVM register model, and
checks every packet with a reference model and a scoreboard fed by monitors.

Simulation is done with **Cadence Xcelium** (`xrun`) on Linux; waveforms are
debugged in **SimVision**.

---

## Highlights

- Multi-UVC testbench: YAPP input agent, 3 channel output agents, HBUS master agent, clock-and-reset agent.
- Directed and random stimulus built from layered sequences and sequencers.
- Error injection: bad parity, illegal address (3), oversized packets, router disabled.
- Reference model + scoreboard with per-channel queues and packet comparison.
- Virtual (multi-channel) sequencer that coordinates HBUS configuration and YAPP traffic.
- UVM register model (`yapp_router_regs`) with built-in reset / access / mem-walk tests and a custom functional register test.
- Functional coverage on the YAPP monitor (packet length x address x parity cross) and on the channel monitor.
- Testbench configuration through `uvm_config_db` (virtual interfaces, channel IDs, default sequences, type overrides).

---

## The DUT

`router_rtl/yapp_router.sv` - a YAPP router that receives packets on one input
port and forwards them to one of three output channels according to the packet address.

**YAPP packet** (`yapp/sv/yapp_packet.sv`)

| Field     | Width     | Notes                                              |
|-----------|-----------|----------------------------------------------------|
| `addr`    | 2 bits    | 0-2 = channel 0-2 (valid), 3 = illegal             |
| `length`  | 6 bits    | payload size, 1-63                                 |
| `payload` | 8 bits x N| dynamic array                                      |
| `parity`  | 8 bits    | XOR of header and payload; may be corrupted on purpose |

**Router behavior modelled by the reference model**

- A packet is forwarded only if the router is enabled, `length <= max packet size`, and the address is 0-2.
- Otherwise it is dropped (the model counts: dropped while disabled, oversized, illegal address).
- Host bus (HBUS) registers: max packet size (`0x1000`), router enable (`0x1001`), plus per-address packet counters and error counters (`0x1009`-`0x100b` for addr 0-2, etc.) exposed through the register model.

---

## Architecture

```
                         router_tb (uvm_env)
 ┌──────────────────────────────────────────────────────────────────────┐
 │  router_mcsequencer (virtual sequencer)                                │
 │      ├── yapp_seqr ──┐          ┌── hbus_seqr ──┐                      │
 │                      ▼          ▼               │                      │
 │  yapp_env          hbus_env (master)  ◄─ reg2hbus adapter ◄─ yapp_rm   │
 │   driver/mon        driver/mon                  (register model)       │
 │      │                  │ bus monitor                                  │
 │      │ item_send_port   │ item_collected_port                          │
 │      ▼                  ▼                                              │
 │  router_module_env                                                     │
 │   router_reference ──vld_yapp_out──► router_scoreboard ◄── chan0/1/2   │
 │   (yapp_in, hbus_in)                  (yapp_in, chanN_in)   monitors   │
 │                                                                        │
 │  chan0_env / chan1_env / chan2_env   (rx agents: monitor + response    │
 │                                       driver/sequencer)                │
 │  clock_and_reset_env                 (clock period + reset generation) │
 └──────────────────────────────────────────────────────────────────────┘
                                  │ virtual interfaces
                              hw_top (clkgen, interfaces, yapp_router DUT)
```

### Data flow and checking

1. The **YAPP monitor** samples packets at the DUT input and sends them to the **reference model** (`router_reference.yapp_in`).
2. The **HBUS monitor** sends register writes to the reference model (`hbus_in`) so it knows the current max packet size and enable bit.
3. The reference model forwards only packets the DUT should pass (`vld_yapp_out`) to the **scoreboard**, which queues them per channel according to address.
4. Each **channel monitor** delivers the packet actually observed at the DUT output; the scoreboard pops the matching expected packet and compares `addr`, `length`, `payload` and `parity` (via `uvm_comparer`).
5. At `report_phase` the scoreboard prints received / correct / incorrect packet counts and any packets still left in the queues.

---

## Repository layout

```
.
├── yapp/                 YAPP input UVC
│   ├── sv/               packet, sequences, sequencer, driver, monitor (+coverage), agent, env, interface (+assertion)
│   └── tb/               standalone UVC bring-up testbench
├── channel/              Channel (output) UVC - Rx agent, packet, response item, response sequences
│   ├── sv/
│   └── tb/               standalone demo testbench
├── hbus/                 HBUS UVC - master/slave agents, transaction, sequences, monitor, reg adapter
│   ├── sv/
│   └── tb/               standalone demo testbench
├── clock_and_reset/      Clock-and-reset UVC - config, item, driver, sequences (clk10_rst5_seq, count clocks)
│   ├── sv/
│   └── tb/               standalone demo testbench
├── router/sv/            Router module env: reference model, scoreboard, packet_compare, router_module package
├── router_rtl/           DUT: yapp_router.sv
└── tb/                   Top-level testbench
    ├── tb_top.sv         top module, vif registration, run_test()
    ├── hw_top.sv         DUT + interfaces + clock generator
    ├── clkgen.sv         clock generator
    ├── router_tb.sv      top UVM env (agents, scoreboard, reference model, register model)
    ├── router_mcsequencer.sv / router_mcseqs_lib.sv   virtual sequencer and virtual sequences
    ├── router_test_lib.sv   test library
    ├── reset_test.sv        standalone reset-test example
    ├── rm_integration.txt   notes on integrating the register model
    ├── yapp_router_regs_*.dat   register model configuration / HDL paths
    └── run.f             Xcelium command file
```

---

## Sequences

| UVC | Sequences |
|-----|-----------|
| **YAPP** (`yapp_tx_seqs.sv`) | `yapp_5_packets`, `yapp_1_seq`, `yapp_012_seq` (one packet per valid address), `yapp_111_seq`, `yapp_repeat_addr_seq`, `yapp_incr_payload_seq`, `yapp_rnd_seq`, `six_yapp_seq`, `yapp_exhausetive_seq`, `seq_with_err` (bad parity / illegal address / length sweep), `yapp_cross_seq` (length x address x parity sweep) |
| **HBUS** (`hbus_master_seqs.sv`) | `hbus_write_seq`, `hbus_read_seq`, `hbus_set_yapp_regs_seq`, `hbus_get_yapp_regs_seq`, `hbus_small_packet_seq` (max size 20, enabled), `hbus_set_default_regs_seq` (max size 63, enabled), `hbus_read_max_pkt_seq`, `hbus_read_enable_seq`, `hbus_set_get_regs_seq` |
| **Channel** (`channel_rx_seqs.sv`) | `channel_rx_resp_seq` (responds forever whenever data is valid), `channel_rx_long_resp_seq` |
| **Clock & reset** | `clock_and_reset_sequence`, `clk10_rst5_seq`, `clock_and_reset_count_clocks_sequence` |
| **Virtual** (`router_mcseqs_lib.sv`) | `router_simple_mcseq` - HBUS config, YAPP traffic, reconfiguration and read-back, in one coordinated flow |

Sequences use objections via `yapp_base_seq` so the test ends when stimulus completes
(the base test also sets a 200 ns drain time).

---

## Tests (`tb/router_test_lib.sv`)

| Test | Purpose |
|------|---------|
| `base_test` | Builds `router_tb`, prints topology, checks config usage |
| `active_agent_test` | Runs `yapp_5_packets` on the YAPP sequencer |
| `simple_test` | Type override to `short_yapp_packet`; `yapp_012_seq` + channel responders + clock/reset |
| `test_uvc_integration` | Error sequence (`seq_with_err`) with HBUS configuration (small-packet limit) |
| `test_mcsequncer` | Drives the whole environment from the virtual sequencer (`router_simple_mcseq`) |
| `cross_test` | `yapp_cross_seq` - full length x address x parity sweep |
| `uvm_reset_test` | UVM built-in `uvm_reg_hw_reset_seq` on the register model |
| `uvm_mem_walk_test` | UVM built-in `uvm_mem_walk_seq` |
| `reg_access_test` | Register front-door / back-door (`write`/`read`/`poke`/`peek`) and `uvm_reg_access_seq` |
| `reg_function_test` | Functional register test: enable via HBUS, send traffic, check per-address counters against predicted values |

---

## Running a simulation

### Prerequisites

- Linux, Cadence Xcelium (`xrun`) and SimVision
- UVM library - set `UVMHOME` to its install directory (`run.f` uses `-uvmhome $UVMHOME`)
- The generated register-model sources `reg_verifier_dir/uvmreg/` (`cdns_uvmreg_utils_pkg.sv`, `yapp_router_regs_rdb.sv`) referenced by `tb/run.f` - these are **not included in this repository** and must be generated (from the register description files in `tb/`) before compiling

### Run

```bash
export UVMHOME=<path to UVM install>
cd tb
xrun -f run.f +UVM_TESTNAME=reg_function_test +UVM_VERBOSITY=UVM_MEDIUM
```

`run.f` already sets `-timescale 1ns/1ns`, include directories and the compile order
(UVC packages and interfaces, DUT, register model, then `tb_top.sv`, `clkgen.sv`, `hw_top.sv`).
`tb_top.sv` calls `run_test("base_test")`; the `+UVM_TESTNAME` plusarg overrides it, so pick any test from the table above, for example:

```bash
xrun -f run.f +UVM_TESTNAME=test_mcsequncer
xrun -f run.f +UVM_TESTNAME=cross_test +SVSEED=random
```

Useful options: `+UVM_VERBOSITY=UVM_LOW|UVM_MEDIUM|UVM_HIGH|UVM_FULL`, `+SVSEED=<n|random>`,
and `-coverage all -covoverwrite` for coverage collection.

### Waveform debug in SimVision

Add access and a database dump, then open it:

```bash
xrun -f run.f +UVM_TESTNAME=simple_test -access +rwc -gui          # interactive
# or dump from a probe script / $shm_open and open afterwards:
simvision waves.shm
```

UVM transaction recording is enabled in the testbench (`recording_detail`), so
YAPP/HBUS/channel transactions can be viewed next to the signals in SimVision.

### Standalone UVC testbenches

Each UVC folder has its own `tb/run.f` for bring-up of that UVC in isolation
(e.g. `cd channel/tb && xrun -f run.f`).

---

## Testbench configuration

- **Virtual interfaces** are set in `tb_top.sv` with `uvm_config_db` typedefs (`yapp_vif_config`, `channel_vif_config`, `hbus_vif_config`, `clock_and_reset_vif_config`).
- **Channel IDs** (0/1/2) and **HBUS** `num_masters`/`num_slaves` are set in `router_tb::build_phase`.
- **Default sequences** are attached per sequencer with `uvm_config_wrapper::set(...)` in each test.
- **Factory overrides** (e.g. `yapp_packet` -> `short_yapp_packet`) change stimulus without touching the environment.
- **Register model** is created, locked, and bound to the HBUS sequencer through `hbus_reg_adapter` with auto-predict enabled (see `tb/rm_integration.txt`).

---

## Known notes

- The UVC sources and the RTL are based on the Cadence "SystemVerilog Accelerated Verification with UVM" training material (see file headers).
- The DUT header lists known RTL limitations (e.g. parity is not updated in the last-packet memory).
- `tb/reset_test.sv` duplicates `uvm_reset_test` from `router_test_lib.sv` and is not part of the compile list.
