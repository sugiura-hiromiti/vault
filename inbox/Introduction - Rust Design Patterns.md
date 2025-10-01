---
title: Introduction - Rust Design Patterns
source: https://rust-unofficial.github.io/patterns/
author: 
published: 
created: 2025-05-22
description: A catalogue of Rust design patterns, anti-patterns and idioms
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
If you are interested in contributing to this book, check out the [contribution guidelines](https://github.com/rust-unofficial/patterns/blob/master/CONTRIBUTING.md).

- **2024-03-17**: You can now download the book in PDF format from [this link](https://rust-unofficial.github.io/patterns/rust-design-patterns.pdf).

In software development, we often come across problems that share similarities regardless of the environment they appear in. Although the implementation details are crucial to solve the task at hand, we may abstract from these particularities to find the common practices that are generically applicable.

Design patterns are a collection of reusable and tested solutions to recurring problems in engineering. They make our software more modular, maintainable, and extensible. Moreover, these patterns provide a common language for developers, making them an excellent tool for effective communication when problem-solving in teams.

Keep in mind: Each pattern comes with its own set of trade-offs. It’s crucial to focus on why you choose a particular pattern rather than just on how to implement it.<sup><a href="https://rust-unofficial.github.io/patterns/#1">1</a></sup>

Rust is not object-oriented, and the combination of all its characteristics, such as functional elements, a strong type system, and the borrow checker, makes it unique. Because of this, Rust design patterns vary with respect to other traditional object-oriented programming languages. That’s why we decided to write this book. We hope you enjoy reading it! The book is divided in three main chapters:

- [Idioms](https://rust-unofficial.github.io/patterns/idioms/index.html): guidelines to follow when coding. They are the social norms of the community. You should break them only if you have a good reason for it.
- [Design patterns](https://rust-unofficial.github.io/patterns/patterns/index.html): methods to solve common problems when coding.
- [Anti-patterns](https://rust-unofficial.github.io/patterns/anti_patterns/index.html): methods to solve common problems when coding. However, while design patterns give us benefits, anti-patterns create more problems.

<sup>1</sup>

https://web.archive.org/web/20240124025806/https://www.infoq.com/podcasts/software-architecture-hard-parts/