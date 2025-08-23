---
title: sugiura-hiromiti/oso
source: https://deepwiki.com/sugiura-hiromiti/oso
author:
  - "[[DeepWiki]]"
published:
created: 2025-08-20
description: This document provides a comprehensive overview of the OSO Operating System, an experimental pure Rust operating system primarily targeting aarch64 architecture. OSO represents a ground-up implementat
tags:
  - clippings
aliases:
  - sugiura-hiromiti/oso
status: bm
---
[Get free private DeepWikis in Devin](https://deepwiki.com/private-repo)

Menu

## OSO Operating System Overview

Relevant source files
- [Cargo.lock](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/Cargo.lock)
- [Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/Cargo.toml)
- [README-en.md](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README-en.md)
- [README.md](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md)
- [memo.md](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md)
- [oso\_error/Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_error/Cargo.toml)
- [oso\_kernel/Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_kernel/Cargo.toml)
- [oso\_loader/Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_loader/Cargo.toml)
- [oso\_no\_std\_shared/Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_no_std_shared/Cargo.toml)
- [oso\_proc\_macro\_logic/Cargo.toml](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_proc_macro_logic/Cargo.toml)

## Purpose and Scope

This document provides a comprehensive overview of the OSO Operating System, an experimental pure Rust operating system primarily targeting aarch64 architecture. OSO represents a ground-up implementation that leverages Rust's type safety and abstraction capabilities while maintaining direct hardware control through custom UEFI bootloader and kernel components.

This overview covers the system's architecture, core components, development infrastructure, and execution flow. For detailed information about specific subsystems, see: [Core System Components](https://deepwiki.com/sugiura-hiromiti/oso/2-core-system-components), [Development Infrastructure](https://deepwiki.com/sugiura-hiromiti/oso/3-development-infrastructure), [UEFI Subsystems](https://deepwiki.com/sugiura-hiromiti/oso/4-uefi-subsystems), and [Development Environment](https://deepwiki.com/sugiura-hiromiti/oso/5-development-environment).

## System Architecture

OSO follows a modular architecture built around a custom UEFI bootloader and kernel, supported by an extensive procedural macro system and development toolchain. The system prioritizes standards compliance while maintaining zero external runtime dependencies.

### High-Level Component Architecture

```
Shared InfrastructureCode GenerationBuild SystemRuntime ExecutionUEFI Firmware
(OVMF)oso_loader
UEFI Bootloader
bootaa64.efioso_kernel
OS Kernel
kernel_main()xtask
cargo run -p xtaskQEMU
qemu-system-aarch64disk.img
FAT32 filesystemoso_proc_macro
Public APIoso_proc_macro_logic
Implementationfonts_data!
status_from_spec!
test_elf_*oso_no_std_shared
Core utilitiesoso_dev_util
Workspace management
```

**Sources:**[README.md 44-94](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L44-L94) [Cargo.toml 1-7](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/Cargo.toml#L1-L7) [memo.md 108-134](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L108-L134)

### Runtime Execution Flow

```
"oso_kernelkernel_main()""ELF Parseroso_kernel.elf""UEFI GOP Protocol""oso_loaderefi_image_entry_point""OVMF Firmware""oso_kernelkernel_main()""ELF Parseroso_kernel.elf""UEFI GOP Protocol""oso_loaderefi_image_entry_point""OVMF Firmware""Disable interruptsInitialize kernelEnter WFI loop""Boot bootaa64.efi""Configure graphics output""Load oso_kernel.elf""Return entry point 0x40010120""Exit UEFI boot services""Jump to kernel_main()""wfe instruction(Wait for Event)"
```

**Sources:**[memo.md 108-134](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L108-L134) [memo.md 798-884](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L798-L884) [oso\_loader/Cargo.toml 1-36](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_loader/Cargo.toml#L1-L36)

## Core Runtime Components

The OSO system consists of two primary runtime components that execute in sequence during the boot process.

### UEFI Bootloader (oso\_loader)

The `oso_loader` serves as a custom UEFI application responsible for loading and launching the kernel. It implements comprehensive ELF parsing and graphics initialization.

**Key Features:**

- UEFI Graphics Output Protocol (GOP) support with multiple pixel formats
- Complete ELF64 file parsing and loading
- Memory management through UEFI boot services
- Device tree acquisition and configuration

**Dependencies:**`oso_error`, `oso_no_std_shared`, `oso_proc_macro`

**Supported Graphics Formats:** RGB, BGR, Bitmask, Block Transfer Only (default)

### OS Kernel (oso\_kernel)

The `oso_kernel` represents the core operating system functionality, entered via the `kernel_main()` function at address `0x40010120`.

**Architecture Support:**

- **Primary target:** aarch64 (ARM64) - full implementation
- **Secondary target:** x86\_64 - partial support for debugging

**Module Structure:**

- `app`: Application execution subsystem
- `base`: Fundamental kernel libraries
- `driver`: Hardware device control

**Sources:**[README.md 46-74](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L46-L74) [oso\_loader/Cargo.toml 14-17](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_loader/Cargo.toml#L14-L17) [oso\_kernel/Cargo.toml 6-9](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_kernel/Cargo.toml#L6-L9)

## Development Infrastructure

OSO employs a sophisticated development infrastructure centered around procedural macros and automated build systems.

### Procedural Macro System

The macro system enables compile-time code generation from external specifications and resources.

```
External SourcesImplementationMacro Typesfonts_data!
Embed font filestest_elf_*
ELF validationstatus_from_spec!
UEFI spec parsingwrapper
Function generationoso_proc_macro
proc-macro = trueoso_proc_macro_logic
Core implementationoso_dev_util_helper
File operationsUEFI Specification
HTML scrapingFont Files
Binary embedding
```

**Sources:**[oso\_proc\_macro\_logic/Cargo.toml 6-21](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/oso_proc_macro_logic/Cargo.toml#L6-L21) [README.md 86-93](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L86-L93)

### Build System (xtask)

The `xtask` crate provides comprehensive build automation for the multi-target, UEFI-based system.

**Build Process:**

1. Cross-compilation for `aarch64-unknown-none-elf` (kernel) and `aarch64-unknown-uefi` (bootloader)
2. FAT32 disk image creation and binary copying
3. QEMU emulation with OVMF firmware integration
4. Multi-platform CI/CD through GitHub Actions

**Supported Platforms:** macOS ARM64, Linux ARM64 (with partial x86\_64 support)

**Sources:**[README.md 75-82](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L75-L82) [README.md 95-112](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L95-L112)

## Technical Characteristics

### Language and Dependencies

OSO maintains strict dependency minimization:

- **Runtime:** Pure Rust with no external crates
- **Development:** External crates only for development tooling (`xtask`, procedural macros)
- **Standards Compliance:** Follows UEFI 2.9+ specification and ELF64 format

### Memory and Platform Requirements

**Build Requirements:**

- Nightly Rust 1.90.0+
- QEMU 10+
- Platform-specific disk utilities (`hdiutil` on macOS)

**Runtime Environment:**

- UEFI 2.9+ firmware (OVMF for emulation)
- ARM64 Cortex-A72 (primary) or x86\_64 (partial)
- Minimum memory for UEFI boot services

### Architectural Philosophy

The system embodies several key principles:

- **Active Reinvention:** Implementation from primary sources rather than existing code
- **Rust-First Design:** Leverages advanced Rust features for system programming
- **Standards Adherence:** Strict compliance with established specifications
- **Educational Focus:** Serves as reference for aarch64 OS development

**Sources:**[README.md 28-43](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L28-L43) [README.md 95-102](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/README.md#L95-L102) [memo.md 6-17](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L6-L17)

## Execution Environment

The OSO system executes within a carefully orchestrated environment spanning UEFI firmware through kernel initialization.

### QEMU Configuration

For aarch64 targets:

```
qemu-system-aarch64 -machine virt -cpu cortex-a72 
-drive if=pflash,format=raw,readonly=on,file=/tmp/aarch64/code.fd
-drive if=pflash,format=raw,readonly=off,file=target/xtask/ovmf_vars
-drive file=target/xtask/disk.img,format=raw,if=none,id=hd0
-device virtio-blk-device,drive=hd0
```

### Memory Layout

The kernel is loaded at base address `0x40000000` with entry point at `0x40010120`, following the ELF64 program headers for segment loading and memory mapping.

**Sources:**[memo.md 108-134](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L108-L134) [memo.md 798-884](https://github.com/sugiura-hiromiti/oso/blob/f11ce661/memo.md#L798-L884)