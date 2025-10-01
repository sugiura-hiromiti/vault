---
title: Rust Atomics and Locks by Mara Bos
source: https://marabos.nl/atomics/
author:
  - "[[Mara Bos]]"
published: 
created: 2025-05-22
description: Low-level Concurrency in Practice. This practical book helps Rust programmers of all levels gain a clear understanding of low-level concurrency. You'll learn everything about atomics and memory ordering and how they're combined with basic operating system APIs to build common primitives like mutexes and condition variables. Once you're done, you'll have a firm grasp of how Rust's memory model, the processor, and the role of the operating system all fit together.
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
## About this Book

The Rust programming language is extremely well suited for concurrency, and its ecosystem has many libraries that include lots of concurrent data structures, locks, and more. But implementing those structures correctly can be difficult. Even in the most well-used libraries, memory ordering bugs are not uncommon.

In this practical book, Mara Bos, team lead of the Rust library team, helps Rust programmers of all levels gain a clear understanding of low-level concurrency. You’ll learn everything about atomics and memory ordering and how they're combined with basic operating system APIs to build common primitives like mutexes and condition variables. Once you’re done, you’ll have a firm grasp of how Rust’s memory model, the processor, and the role of the operating system all fit together.

With this guide, you’ll learn:

- How Rust's type system works exceptionally well for programming concurrency correctly
- All about mutexes, condition variables, atomics, and memory ordering
- What happens in practice with atomic operations on Intel and ARM processors
- How locks are implemented with support from the operating system
- How to write correct code that includes concurrency, atomics, and locks
- How to build your own locking and synchronization primitives correctly

[Start reading](https://marabos.nl/atomics/foreword.html)

## Code Examples

The code examples from this book are available on GitHub: [https://  github.com/  m-ou-se/  rust-atomics-and-locks](https://github.com/m-ou-se/rust-atomics-and-locks)