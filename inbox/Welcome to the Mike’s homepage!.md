---
title: Welcome to the Mike’s homepage!
source: https://krinkinmu.github.io/
author:
  - "[[Mike Krinkin]]"
published: 
created: 2025-05-22
description: "Various things I do outside of work: fun, boring, anything really."
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
## AArch64 shared memory synchronization

I’m continuing playing with 64 bit ARM architecture and the next thing I want to try is spinning up multiple CPUs. However before doing that I need to get out of the way the question of synchronizing multiple concurrently running CPUs and that’s what I touch on in this post.

[Read More](https://krinkinmu.github.io/2024/04/20/arm-synchronization.html)

## AArch64 memory and paging

In this post I will return to my exploration of 64 bit ARM architecture and will touch on the exciting topic of virtual memory and AArch64 memory model.

Hopefully, by the end of this post I will have an example of how to configure paging in AArch64 and will gather some basic understanding of the relevant concepts and related topics along the way.

[Read More](https://krinkinmu.github.io/2024/01/14/aarch64-virtual-memory.html)

## U-boot boot script

To wrap up my explorations of U-boot I’d like show how to automatically load a kernel with U-boot on startup.

[Read More](https://krinkinmu.github.io/2023/11/19/u-boot-boot-script.html)

## How U-boot loads Linux kernel

I’m continuing my exploration of how to use U-boot. Last time I covered some basics, this time I will build on that and will dive into a bit more realistic example - how U-boot loads Linux kernel.

[Read More](https://krinkinmu.github.io/2023/08/21/how-u-boot-loads-linux-kernel.html)

## Getting started with U-Boot

A lot of time has passed since I posted last time. Old hobby projects were long forgotten and it’s time to start from scratch, but do it right this time (I wonder if that’s the reason I never finish my hobby projects).

In the past posts I covered already EFI, Qemu, Aarch64. I tried to create a simple EFI bootloader and a simplistic Aarch64 kernel from scratch.

I still didn’t quite abandon the idea of playing with virtualization on Aarch64, but creating everything from scratch, as fun as it is, probably going to delay things even further.

So a new me wants to learn and use some of the existing tools and in this post I will cover the most basic things related to U-boot.

[Read More](https://krinkinmu.github.io/2023/08/12/getting-started-with-u-boot.html)

## Dynamic Memory Allocation Part3

I didn’t post for quite some time. In the [previous post](https://krinkinmu.github.io/2021/02/07/dynamic-memory-allocation-part2.html "the previous post") I covered buddy allocator. Buddy allocator, while begin a an actually practical algorithm, has it’s limitations.

One obvious limitation is that it allocates memory in multiples of the basic block size. Moreover the multiplier has to be a power of 2. That will lead to some memory wasted if you want to allocate a memory chunk that is not a power of 2 multiple of the basic block size.

Another caveat is the data that we need to maintain for bookkeeping. In the specifc implementation I showed I pre-allocated a page structure for each basic block. This page structure is a bit above 16 bytes in size and the smaller the base block is the more such structures we need. Which increases the overhead of the buddy allocator if we want to allocate small chunks of memory.

So here I’m going to cover another approach to memory allocation that is more efficient when working with smaller object sizes.

I take no creadit for the algorithm itself. This post covers a very simplified version of an algorithm proposed by Jeff Bonwick and described in the [The SLAB Allocator](http://www.usenix.org/publications/library/proceedings/bos94/full_papers/bonwick.ps "the slab allocator") paper.

As always the code is available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2022/08/20/dynamic-memory-allocation-part3.html)

## The pain of infinite loops

I’ve been struggling dealing with various Rust quirks in my hobby projects and some day I had enough, purged all the Rust code and moved to C++, just to hit an expected, but still interesting quirk of C++.

[Read More](https://krinkinmu.github.io/2021/12/12/pain-of-infinite-loops.html)

## Dynamic Memory Allocation Part2

In the [previous post](https://krinkinmu.github.io/2020/12/30/dynamic-memory-allocation-part1.html "the previous post") I covered a generic, but rather simplistic approach to dynamic memory allocation. The approach covered there is legitimate, but isn’t particularly fast and I don’t think it gets a lot of practical use.

In this post I’d like to cover a rather interesting algorithm, that on the one hand is not as generic as the one I covered in the [previous post](https://krinkinmu.github.io/2020/12/30/dynamic-memory-allocation-part1.html "the previous post"), but on the other hand it’s quite often used in practice.

As always the code is available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2021/02/07/dynamic-memory-allocation-part2.html)

## A curious case of static memory allocation in Rust

In the [previous post](https://krinkinmu.github.io/2021/01/17/devicetree.html "the previous post") I covered the binary representation of the Flattened DeviceTree or DeviceTree Blob and was already starting to work on memory management for my hobby project, but I got stuck for quite some time trying to come up with a reasonable way to work with statically allocated memory in Rust.

I don’t think that I found an obviously convincing approach here, but what can you do…

As always, I have some sources related to the post on [GitHub](https://github.com/krinkinmu/aarch64), though in this particular post I will be construction a purely hypothetical example, so you will not be able to find the snippets from the post in the repository.

[Read More](https://krinkinmu.github.io/2021/01/29/a-curious-case-of-static-memory-allocation-in-rust.html)

## An Introduction to Devicetree specification

Devicetree is a configuration commonly used to describe hardware present in various platforms. In Linux Devicetree is used for ARMs, MIPSes, RISC-V, XTensa and PowerPC (and probably others).

In this post I’m going to cover the problem that Devicetree is trying to solve, briefly touch on the available alternatives and finally show some code for parsing the binary representation of the Devicetree (a. k. a. Flattened Device Tree or DTB).

All the sources are available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2021/01/17/devicetree.html)

## An interesting conditional probability problem

Occasionally I read university books on math and comuter science to refresh my memory. At work I mostly use some linear and mixed integer programming solvers and ready function fitting implementation, but I don’t get to actually solve math problems that often. So I find it entertaining to go through the study book problems from time to time.

This post is about one simple problem that I for some reason find quite cool.

[Read More](https://krinkinmu.github.io/2021/01/15/an-interesting-probability-problem.html)

## AArch64 Interrupt and Exception handling

In the [previous post](https://krinkinmu.github.io/2021/01/04/aarch64-exception-levels.html "the previous post") I gave a somewhat badly structured introduction to the priviledge levels model in AArch64. That was a preparation to make explanation of the interrupt handling a little bit easier in this post.

So let’s get started and as always you can find all the sources on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2021/01/10/aarch64-interrupt-handling.html)

## AArch64 Exception Levels

I’m continuing my exploration of the AArch64 architecture and this time I will touch on the AArch64 priviledge levels.

Note that AArch64 priviledge model is not exactly the same as the previous iterations of ARM. While there are plenty of similarities, and there is a level of backward compatibility, at the same time, there are some differences as well. So do not assume that things covered here will work the same way for all ARMs.

Finally, I assume that you’re familiar with general GNU Assembler synatax or willing to figure things out as you go. Familiarity with ARM assmebly language will help, though I try to explain all the things I use.

As always the code is available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2021/01/04/aarch64-exception-levels.html)

## Dynamic Memory Allocation Part1

In the [previous post](https://krinkinmu.github.io/2020/12/26/position-independent-executable.html "the previous post") I mentioned that I implemented simplistic dynamic memory allocator and plugged it into Rust. So I thought I could create an introductionary post into dynamic memory allocation algorithms.

This post will cover a basic algorithm of dynamic memory allocation and some practical aspects that we might consider when implementing dynamic memory allocators as a sort of introduction into the problem (thus Part1).

As always the code is available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2020/12/30/dynamic-memory-allocation-part1.html)

## Debugging AArch64 using QEMU and GDB

In the [previous post](https://krinkinmu.github.io/2020/12/13/adding-rust-to-aarch64.html "the previous post") I added Rust to the project and since then I was experimenting with parsing DeviceTree, however while doing that I stumbled on a mistery problem.

In this post I will cover the background that lead to the problem, investigations and finally the solution. There isn’t terribly a lot of code related to this post, but nevertheless all the sources are available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2020/12/26/position-independent-executable.html)

## Adding a little bit of Rust to AARCH64

In the [previous post](https://krinkinmu.github.io/2020/12/05/PL011-HiKey960.html "the previous post") we managed to make PL011 UART work on my [HiKey960](https://www.96boards.org/product/hikey960/ "HiKey960"). We did that using C, but all the cool guys these days use Rust, so let’s see how we can make it work.

The sources for this post are available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2020/12/13/adding-rust-to-aarch64.html)

## ARMs PL011 UART on HiKey960 board

In the [previous post](https://krinkinmu.github.io/2020/11/29/PL011.html "the previous post") we managed to make PL011 UART controller as emulated by QEMU work. Emulation is a useful tool, but it’s just never going to be perfect. So naturally I wanted to try it on the real hardware and used [HiKey960](https://www.96boards.org/product/hikey960/ "HiKey960") board that I have and that happen to have a PL011 compatible UART controller.

The sources for this post are available on [GitHub](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2020/12/05/PL011-HiKey960.html)

## ARMs PL011 UART

In the [previous post](https://krinkinmu.github.io/2020/11/21/EFI-aarch64.html "the previous post") we managed to try our simplistic EFI loader on 64-bit ARM in QEMU and on HiKey960 board. Now I want to try to explore the aarch64 architecture a bit further and maybe create something interesting worth loading on the board.

Since the [previous post](https://krinkinmu.github.io/2020/11/21/EFI-aarch64.html "the previous post") I’ve made a few changes to the EFI loader, you can find them on [GitHub](https://github.com/krinkinmu/efi). The sources for this post are also available on GitHub, but in a [different repository](https://github.com/krinkinmu/aarch64).

[Read More](https://krinkinmu.github.io/2020/11/29/PL011.html)

## UEFI on AARCH64

In the [previous post](https://krinkinmu.github.io/2020/11/15/loading-elf-image.html "the previous post") we covered how an EFI application can load another binary in memory. That’s basically what a bootloader does. In this short post I will show that basically the same code will work on a different architecture.

As usual all the sources are available on [GitHub](https://github.com/krinkinmu/efi).

[Read More](https://krinkinmu.github.io/2020/11/21/EFI-aarch64.html)

Continuing exploring UEFI after some break. Last time I looked at file access, now I’m going to read an ELF file from the file system, load it in memory and transfer control to the ELF image.

As usual all the sources are available on [GitHub](https://github.com/krinkinmu/efi).

[Read More](https://krinkinmu.github.io/2020/11/15/loading-elf-image.html)

## UEFI File access APIs

Continuing exploring UEFI bit by bit. This time I’m going to briefly cover the file access APIs in UEFI. As usual all the sources are available on [GitHub](https://github.com/krinkinmu/efi), however since the [previous post](https://krinkinmu.github.io/2020/10/18/handles-guids-and-protocols.html "the previous post") I’ve made a few changes in the repository that this post will not cover.

[Read More](https://krinkinmu.github.io/2020/10/31/efi-file-access.html)

## Recurrence relations and linear algebra

I recently learned that GitHub markdown doesn’t have native support for rendenring math equations. That seemed quite weird, so I figured that I’d try to look at existing alternatives and flex my tex muscle.

In this post I will try to show an end-to-end example of how to solve linear ordinary recurrence relations and give an intro to all the linear algebra required to do that. Some basic understanding of vector spaces and matrices is still required though.

[Read More](https://krinkinmu.github.io/2020/10/23/recurrence-relations-and-linear-algebra.html)

## UEFI handles, GUIDs and protocols

Continuing exploring UEFI bit by bit. This time I’ll cover a small part about UEFI handles, GUIDs and protocols. All the sources are available on [GitHub.](https://github.com/krinkinmu/efi)

[Read More](https://krinkinmu.github.io/2020/10/18/handles-guids-and-protocols.html)

## Getting started with EFI

I’m trying to explore another relatively new are for me: UEFI. When working on student and hobbt project many people tend to start from legacy BIOS or multiboot to boot their hello world kernels.

On the one hand it makes a lot of sense to use the simplest solution possible. On the other hand EFI complexity serves some purpose and with EFI you get a lot of useful tools right out of the box.

With all that in mind let’s try to cook up something with EFI. Sources for this tutorial are available on [GitHub.](https://github.com/krinkinmu/efi/commit/7c837b6)

[Read More](https://krinkinmu.github.io/2020/10/11/efi-getting-started.html)

## FTDI I2C adapter

In the previous post I covered what USB data transfers we need to configure the [FTDI MPSSE](https://www.ftdichip.com/Products/Cables/USBMPSSE.htm "FTDI MPSSE") cable to work in the MPSSE mode. Now with this knowledge we can continue working on the USB-to-I2C bridge for the kernel.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/09/06/ftdi-i2c.html)

## FTDI protocol

In the previous post I touched a little bit on Vendor and Product IDs and changed the Vendor and Product IDs on the [FTDI MPSSE](https://www.ftdichip.com/Products/Cables/USBMPSSE.htm "FTDI MPSSE") cable that I got. I used the FTDI userspace library, but since the goal is to make a USB driver for the kernel in the end, we need to understand how the FTDI library calls are mapped to actual USB data transfers. This post covers what I did.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/09/05/ftdi-protocol.html)

## FTDI and USB device ID

In a few of the previous articles I was writing a driver for [Nintendo Wiichuk](https://www.olimex.com/Products/Modules/Sensors/MOD-WII/MOD-Wii-UEXT-NUNCHUCK/open-source-hardware "Nintendo Wiichuk"). It was an [I2C](https://en.wikipedia.org/wiki/I%C2%B2C "I2C") input device and the driver was tested on [BeagleBone Black Wireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless"). However there weren’t a lot of opportunities for me to use a joystick on the board, so the experience is somewhat incomplete.

The driver for [Nintendo Wiichuk](https://www.olimex.com/Products/Modules/Sensors/MOD-WII/MOD-Wii-UEXT-NUNCHUCK/open-source-hardware "Nintendo Wiichuk") is not really architecture specific, so I figured that if I was able to connect the joystick to my laptop it would be cool to try it in a game on my laptop. The problem is that I don’t have any exposed [I2C](https://en.wikipedia.org/wiki/I%C2%B2C "I2C") connectors, so I want to try to create an [USB](https://en.wikipedia.org/wiki/USB "USB") to [I2C](https://en.wikipedia.org/wiki/I%C2%B2C "I2C") adapter. And this article is the first step.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/08/02/ftdi.html)

## Nintendo Wiichuk Joystick

In this short note we will build on top of [the previous post](https://krinkinmu.github.io/2020/07/25/input-device.html "the previous post") and add support for the joystick in our \[Nintendo Wiichuck\] device.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/07/26/input-device.html)

## Nintendo Wiichuk interface and input devices

I continue going through [Bootlin](https://bootlin.com/ "Bootlin") training materials on embedded systems and [Linux Kernel](https://www.kernel.org/ "Linux Kernel"). In [the previous post](https://krinkinmu.github.io/2020/07/18/nintendo-wiichuk-i2c.html "the previous post") we configured the second [I2C](https://en.wikipedia.org/wiki/I%C2%B2C "I2C") controller the [BeagleBone Black](https://beagleboard.org/black "BeagleBone Black") or [BeagleBone Black Wireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless") and connected the [Nintendo Wiichuk](https://www.olimex.com/Products/Modules/Sensors/MOD-WII/MOD-Wii-UEXT-NUNCHUCK/open-source-hardware "Nintendo Wiichuk") device to the board.

In this article I will look a bit deaper into the [Nintendo Wiichuk](https://www.olimex.com/Products/Modules/Sensors/MOD-WII/MOD-Wii-UEXT-NUNCHUCK/open-source-hardware "Nintendo Wiichuk") device interface and how can our driver present the device as an input device.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/07/25/input-device.html)

## Nintendo Wiichuk and I2C

I continue going through [Bootlin](https://bootlin.com/ "Bootlin") training materials on embedded systems and [Linux Kernel](https://www.kernel.org/ "Linux Kernel"). In [the previous post](https://krinkinmu.github.io/2020/07/12/linux-kernel-modules.html "the previous post") I covered the basics of cross compiling modules for the [BeagleBone Black](https://beagleboard.org/black "BeagleBone Black") or [BeagleBone Black Wireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless") as well as an brief introduction into [Device Tree](https://en.wikipedia.org/wiki/Device_tree "Device Tree").

In this article we will properly configure [I2C](https://en.wikipedia.org/wiki/I%C2%B2C "I2C") bus on the board, connect our [Nintendo Wiichuk](https://www.olimex.com/Products/Modules/Sensors/MOD-WII/MOD-Wii-UEXT-NUNCHUCK/open-source-hardware "Nintendo Wiichuk") device to the board and check that it’s recognized by the board.

[Read More](https://krinkinmu.github.io/2020/07/18/nintendo-wiichuk-i2c.html)

## Kernel modules, device drivers and Device Tree

I continue going through [Bootlin](https://bootlin.com/ "Bootlin") training materials on embedded systems and [Linux Kernel](https://www.kernel.org/ "Linux Kernel"). In [the previous post](https://krinkinmu.github.io/2020/07/05/beaglebone-software-update.html "the previous post") I covered the environment setup, so now we should be able to access the board and share files between the board and the host.

In this article I’m going to try to actually create a few simple Linux Kernel modules, build them for the [BeagleBone Black](https://beagleboard.org/black "BeagleBone Black") or [BeagleBone Black Wireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless") board and test them on the actual hardware.

All the sources used in this article are available on [GitHub.](https://github.com/krinkinmu/bootlin)

[Read More](https://krinkinmu.github.io/2020/07/12/linux-kernel-modules.html)

## Updating kernel and bootloader on BeagleBone Black Wireless

I continue going through [Bootlin](https://bootlin.com/ "Bootlin") training materials on embedded systems and [Linux Kernel](https://www.kernel.org/ "Linux Kernel"). In this article I will cover building and updating [Linux Kernel](https://www.kernel.org/ "Linux Kernel") and [U-Boot](https://github.com/u-boot/u-boot "U-Boot") on my [BeagleBone Black Wireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless"), but the same instruction should apply for [BeagleBone Black](https://beagleboard.org/black "BeagleBone Black").

[Read More](https://krinkinmu.github.io/2020/07/05/beaglebone-software-update.html)

## Eneter U-Boot console on BeagleBone Black Wireless

I’m going through [Bootlin](https://bootlin.com/ "Bootlin") training materials on embedded systems and [LinuxKernel](https://www.kernel.org/ "Linux Kernel"). In the training materials they use [BeagleBoneBlack](https://beagleboard.org/black "BeagleBone Black") or \[BeagleBonBlackWireless\] boards.

This post covers how to connect the board and drop into [U-Boot](https://github.com/u-boot/u-boot "U-Boot") console, as well as hardware required. I’m using [BeagleBoneBlackWireless](https://beagleboard.org/black-wireless "BeagleBone Black Wireless"), but the same should apply to [BeagleBoneBlack](https://beagleboard.org/black "BeagleBone Black") giving that we don’t use any wireless capabilities of the board.

[Read More](https://krinkinmu.github.io/2020/06/27/beaglebone-black-uboot-console.html)

## A few notes on Rust borrow checker

A while ago I tried to embrace [Rust](https://www.rust-lang.org/ "Rust"), but my experience was mostly negative due to various reasons. However the language and toolchain has machured since then and I’m giving it another shot.

One of the features of [Rust](https://www.rust-lang.org/ "Rust") that makes it different from the other languages is it’s borrow checker. What follows are a few notes about the Rust borrow checker.

[Read More](https://krinkinmu.github.io/2020/06/21/rust-borrow-checker.html)

## GitHub Pages and Jekyll

I’m mostly trying to stay away from any kind of front-end related engineering because I’ve never found it interesting enough to spend a reasonable amount of time to learn it.

That being said, on a subjective level I like the idea of keeping my posts in VCS close to the code, so I started looking at [GitHub Pages](https://guides.github.com/features/pages/ "Getting Started with GitHub Pages"). What follows is a very brief explanation of what I found with references to other sources.

[Read More](https://krinkinmu.github.io/2020/06/14/github-pages.html)