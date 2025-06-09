---
title: Writing A RISC-V OS From Scratch
source: https://hackaday.com/2025/01/09/writing-a-risc-v-os-from-scratch/
author:
  - "[[Hackaday]]"
published: 2025-01-10
created: 2025-05-22
description: If you read Japanese, you might have seen the book “Design and Implementation of Microkernels” by [Seiya Nuda]. An appendix covers how to write your own operating system for RISC-V in a…
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
If you read Japanese, you might have seen the book “ *Design and Implementation of Microkernels* ” by \[Seiya Nuda\]. An appendix covers how to write your own operating system for RISC-V in about 1,000 lines of code. Don’t speak Japanese? An [English version](https://operating-system-in-1000-lines.vercel.app/en) is available free on the Web and on [GitHub](https://github.com/nuta/operating-system-in-1000-lines).

The author points out that the original Linux kernel wasn’t much bigger (about 8,500 lines). The OS allows for paging, multitasking, a file system, and exception handling. It doesn’t implement interrupt handling, timers, inter-process communication, or handling of multiple processors. But that leaves you with something to do!

The online book covers everything from booting using OpenSBI to building a command line shell. Honestly, we’d have been happier with some interrupt scheme and any sort of crude way to communicate and synchronize across processes, but the 1,000 line limit is draconian.

Since the project uses QEMU as an emulation layer, you don’t even need any special hardware to get started. Truthfully, you probably won’t want to use this for a production project, but for getting a detailed understanding of operating systems or RISC-V programming, it is well worth a look.

If you want something more production-ready, you have [choices](https://hackaday.com/2024/11/13/making-sense-of-real-time-operating-systems-in-2024/). Or, [stop using an OS at all](https://hackaday.com/2024/10/15/antirtos-no-rtos-needed/).

![](https://analytics.supplyframe.com/trackingservlet/impression?action=pageImpression&zone=HDay_article&extra=title%3DWriting+a+RISC-V+OS+From+Scratch)