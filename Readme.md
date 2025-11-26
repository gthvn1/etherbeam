# Project Overview

This project implements a user‑space network stack split across **Go**
and **Gleam**, designed for fast, safe, and flexible packet processing.

The architecture is:

    eth0 <--> Go (raw socket) <--> UNIX Datagram Socket <--> Gleam Logic
                           ^                                      |
                           |__________ reply raw frame ___________|

------------------------------------------------------------------------

## 🔥 Purpose

- Capture **real Ethernet frames** from a network interface (e.g., `eth0`, `veth0`).
- Forward those frames to a **Gleam server** for decoding and decision-making.
- Gleam produces a **raw Ethernet reply frame**.
- Go injects that reply back onto the real network interface.

This approach allows you to write protocol logic (ARP, ICMP, DHCP,
custom protocols) in **safe, elegant Gleam**, while Go handles the
privileged raw socket operations.

------------------------------------------------------------------------

## 🚀 Why This Architecture?

### ✔ Same Ethernet Frames

The frames delivered to Gleam are **byte‑for‑byte the same** as those
received from `eth0`. UNIX datagram sockets deliver raw bytes unchanged.

### ✔ No Framing Protocol Needed

UNIX *datagram* sockets preserve message boundaries:

- 1 datagram = 1 Ethernet frame
- No length prefix
- No metadata
- No TCP problems (frame splitting / merging)

### ✔ Safety

- Go handles unsafe raw socket operations.
- Gleam stays pure, functional, and safe---no NIFs, no unsafe memory.

### ✔ Performance

- UNIX domain sockets are extremely fast (faster than TCP localhost).
- Frame sizes (\<2 KB) fit perfectly within UDS message limits.
- Kernel‑level zero copy for local IPC.

------------------------------------------------------------------------

## 🧱 High-Level Components

### 1. **Go Raw Socket Binder**

- Opens an `AF_PACKET` raw socket bound to a real interface (`eth0`).
- Reads full Ethernet frames.
- Sends a frame as a datagram to the Gleam process via UNIX DGRAM socket.
- Waits for a possible reply frame from Gleam.
- Injects the reply onto the real NIC using `Sendto`.

### 2. **Gleam Packet Logic**

- Listens on a UNIX DGRAM socket.
- Receives one Ethernet frame per datagram.
- Decodes L2/L3/L4 models (ARP, IPv4, ICMP, etc.).
- Computes a reply frame (if needed).
- Sends reply as a datagram to the Go endpoint.

------------------------------------------------------------------------

## 🛠 Quick Start

### 1. Create UNIX Datagram Socket Paths

    /tmp/raw_to_gleam.sock
    /tmp/gleam_to_raw.sock

Go writes to one and reads from the other. Gleam does the reverse.

------------------------------------------------------------------------

### 2. Start Go Raw Binder

The Go binary:

- binds `eth0`
- reads frames
- sends them to `/tmp/raw_to_gleam.sock`
- receives any replies from `/tmp/gleam_to_raw.sock`
- pushes replies back to the NIC

Run it with:

``` sh
just run_raw_binder
```

------------------------------------------------------------------------

### 3. Start Gleam Server

The Gleam server:

- binds `/tmp/gleam_to_raw.sock`
- reads frames from `/tmp/raw_to_gleam.sock`
- decodes & decides
- responds with a raw Ethernet frame

Run:

``` sh
just run_etherbeam
```

------------------------------------------------------------------------

### 4. Build & Run

- We are using [just](https://github.com/casey/just)
- To have all recipes:
```sh
just --list
Available recipes:
    build
    build_etherbeam
    build_raw_binder
    default
    run
    run_etherbeam
    run_raw_binder
```

Run:
```sh
just run
```

------------------------------------------------------------------------

## 🧪 Example Applications

- **ARP responder**
- **Ping/ICMP echo responder**
- **DHCP server**
- **Custom L2/L3 simulation**
- **Virtual network appliance**
- **User‑space firewall**
- **Educational packet decoder**

------------------------------------------------------------------------

## 📝 Notes & Gotchas

### CRC/FCS

Linux strips the FCS field on receive; this is normal.

### Root Permissions

Raw sockets require `CAP_NET_RAW`.

### MTU

All Ethernet frames (\<1500 bytes) easily fit inside UDS datagram
messages.

### Concurrency

Gleam can spawn 1 process per frame---great for parallelism.
