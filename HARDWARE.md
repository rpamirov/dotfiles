# Server Hardware

Hardware inventory captured on 2026-09-06 (Europe/Moscow).

## Summary

| Host | Address | Platform | CPU allocation | RAM | GPU | Total VRAM | Root storage |
|---|---|---|---|---:|---|---:|---|
| `desktop` | `localhost` | ASUS PRIME H610M-A D4 | Intel Core i5-12400F, 6 cores / 12 threads | 31 GiB | 1× GeForce RTX 3060 | 12,288 MiB | 500 GB NVMe |
| `EMP-GPU05-01` | `192.168.31.171` | VMware VM | 64 vCPUs, AMD EPYC 7713 host CPU | 251 GiB | 1× RTX A5000 | 24,564 MiB | 300 GB virtual disk |
| `EMP-GPU05-02` | `192.168.31.172` | VMware VM | 128 vCPUs, AMD EPYC 7713 host CPU | 503 GiB | 2× RTX A5000 | 49,128 MiB | 300 GB virtual disk |

## Localhost (`desktop`)

### System

- OS: Ubuntu 24.04.4 LTS
- Kernel: Linux 7.0.0-31-generic
- Architecture: x86-64
- Motherboard: ASUS PRIME H610M-A D4
- Firmware: version 0601, dated 2021-11-22
- Bare-metal host; Intel VT-x is available

### CPU and memory

- CPU: 12th Gen Intel Core i5-12400F
- Topology: 1 socket, 6 cores, 2 threads per core, 12 logical CPUs
- Maximum reported CPU frequency: 4.4 GHz
- Cache: 288 KiB L1d, 192 KiB L1i, 7.5 MiB L2, 18 MiB L3
- NUMA: 1 node
- RAM: 31 GiB
- Swap: 8 GiB

### GPU

- GPU 0: NVIDIA GeForce RTX 3060
- VRAM: 12,288 MiB
- Power limit: 170 W
- NVIDIA driver: 580.173.02

### Storage

- `nvme0n1`: Kingston SNVS500G, 500 GB NVMe; root filesystem is approximately 457 GiB ext4
- `sda`: WDC WD10EZEX-00BBHA0, 1 TB SATA HDD; `/DATA` is approximately 916 GiB ext4
- Local `/DATA` is not the NFS mount used by servers 171 and 172

## Server 171 (`EMP-GPU05-01`)

### System

- Address: `192.168.31.171`
- OS: Ubuntu 22.04.5 LTS
- Kernel: Linux 6.8.0-106-generic
- Architecture: x86-64
- Virtualization: VMware, full virtualization

### CPU and memory

- Reported host CPU: AMD EPYC 7713 64-Core Processor
- VM allocation: 64 vCPUs
- vNUMA: 1 node containing vCPUs 0-63
- RAM: 251 GiB
- Swap: none

### GPU

- GPU 0: NVIDIA RTX A5000
- VRAM: 24,564 MiB
- Power limit: 230 W
- NVIDIA driver: 570.86.15

### Storage

- Root disk: 300 GB VMware virtual disk; root filesystem is approximately 294 GiB ext4
- `/DATA`: NFSv4 mount from `192.168.31.174:/DATA`, approximately 8.0 TiB total
- Shared model directory: `/DATA/SQA/LLM`

## Server 172 (`EMP-GPU05-02`)

### System

- Address: `192.168.31.172`
- OS: Ubuntu 22.04.5 LTS
- Kernel: Linux 6.8.0-111-generic
- Architecture: x86-64
- Virtualization: VMware, full virtualization

### CPU and memory

- Reported host CPU: AMD EPYC 7713 64-Core Processor
- VM allocation: 128 vCPUs
- vNUMA: 2 nodes: vCPUs 0-63 and 64-127
- RAM: 503 GiB
- Swap: 2 GiB

### GPUs

- GPU 0: NVIDIA RTX A5000, 24,564 MiB VRAM, 230 W
- GPU 1: NVIDIA RTX A5000, 24,564 MiB VRAM, 230 W
- Total VRAM: 49,128 MiB
- NVIDIA driver: 575.57.08
- GPU-to-GPU topology: `PHB`; traffic crosses a PCIe host bridge
- No NVLink connection is exposed to the VM

### Storage

- Root disk: 300 GB VMware virtual disk; root filesystem is approximately 294 GiB ext4
- `/DATA`: NFSv4 mount from `192.168.31.174:/DATA`, approximately 8.0 TiB total
- Shared model directory: `/DATA/SQA/LLM`

## Qwen3.8-Flash-Next test results

Tests were run on 2026-09-06 with llama.cpp build 10826, commit `73a43d1f6`, and the shared model:

`/DATA/SQA/LLM/models/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf`

The three-shard `UD-IQ4_XS` model is approximately 93.7 GB. It is much larger than the available VRAM on either server, so most expert layers must run on the CPU. The large per-layer token embedding (PLE) tensor was kept in system RAM.

### Stable configurations

| Host | Context | CPU expert layers | Microbatch | KV cache | Result |
|---|---:|---:|---:|---|---|
| 171 | 131,072 | 40 of 48 | 1,024 | Q8 K/V | Stable |
| 172 | 131,072 | 32 of 48 | 512 | Q8 K/V | Stable; 31 CPU layers failed by approximately 972 MiB during compute-buffer allocation |
| 172 | 262,144 | 36 of 48 | 512 | Q8 K/V | Stable |

Common Flash-Next settings:

- `--load-mode none --lazy-mode off` to load the model into resident memory instead of streaming it repeatedly from NFS
- `--fit off` with explicit expert-layer placement to prevent VRAM overcommit
- `--override-tensor per_layer_token_embd=CPU` to keep the PLE tensor in RAM
- `--split-mode layer`; row splitting was unavailable because the CUDA devices did not support split buffers
- `--tensor-split 1,1` on server 172
- Flash attention enabled, one parallel slot, Q8 K/V cache

### Throughput

| Host and model | Context | Prompt processing | Generation |
|---|---:|---:|---:|
| 171 current Qwen3.6 35B-A3B `UD-Q4_K_XL` with MTP | 131,072 | Not recorded | 8.49 tok/s |
| 171 Qwen3.8-Flash-Next `UD-IQ4_XS` | 131,072 | Not recorded | 0.84 tok/s |
| 171 Qwen3.8-27B dense `UD-Q4_K_M` | 131,072 | 979.54 tok/s | 32.90 tok/s |
| 172 current Qwen3.8 27B `UD-Q8_K_XL` with MTP and thinking | 262,144 | Not recorded | 11.67 tok/s |
| 172 Qwen3.8-Flash-Next `UD-IQ4_XS` | 131,072 | 236.42 tok/s | 1.04 tok/s |
| 172 Qwen3.8-Flash-Next `UD-IQ4_XS` | 262,144 | 203.24 tok/s | 0.92 tok/s |
| 172 Qwen3.8-27B dense `UD-Q6_K` | 262,144 | 1,287.66 tok/s | 27.11 tok/s |

The dense Qwen3.8 measurements used the same 5,660-token prompt and 128 forced output tokens as the Flash comparison. Q4 on 171 loaded in approximately 34 seconds and Q6 on 172 in approximately 44 seconds. Both used automatic fit, Flash Attention, one slot, Q8 K/V cache, and a 512-token microbatch.

The two Flash-Next measurements on server 172 used the same 5,660-token prompt followed by 128 forced output tokens. Increasing context capacity from 131K to 256K reduced prompt throughput by 14.0%, generation throughput by 11.5%, and increased total benchmark time from 146.63 to 166.43 seconds (13.5%).

The current-model baseline measurements used a separate 128-token generation workload and therefore are indicative rather than a strict apples-to-apples comparison. Nevertheless, the difference is decisive: Flash-Next was approximately 10 times slower than the current model on server 171 and 12.7 times slower than the current Q8 plus MTP setup on server 172. The large amount of CPU expert offload is the dominant bottleneck.

### Recommendation

- Use Qwen3.8-27B `UD-Q4_K_M` as the server 171 default at 131K context. Its measured 32.9 tok/s generation rate is fast enough that a Qwen3.6 MoE replacement is unnecessary.
- Use Qwen3.8-27B `UD-Q6_K` as the server 172 default at 256K context. It measured 27.1 tok/s while retaining more weight precision than Q4; the existing Q8 model remains a quality reference if its additional memory use is acceptable.
- If Flash-Next is required for capability testing, use 131K on server 171 and 256K on server 172. The 172 context-size penalty is moderate, but interactive generation remains only about 0.92 tok/s.
- The Flash tests did not use MTP. Standard upstream llama.cpp at the tested revision supports the base Flash-Next model, but not the experimental Flash-Next MTP approach shown by MTPLX-based demonstrations.

## Notes

- CPU socket/core fields reported inside the VMware guests describe the virtual topology. The reliable capacity figures are the vCPU counts and vNUMA assignments above.
- Servers 171 and 172 share the same `/DATA` NFS filesystem, so model files stored under `/DATA/SQA/LLM` need to be downloaded only once.
- RAM, swap, disk usage, GPU utilization, and clock/power states are runtime values and will change; this document records installed or allocated capacity rather than transient utilization.
