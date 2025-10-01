---
title: "karpathy/LLM101n: LLM101n: Let's build a Storyteller"
source: https://github.com/karpathy/LLM101n
author:
  - "[[GitHub]]"
published: 
created: 2025-05-22
description: "LLM101n: Let's build a Storyteller. Contribute to karpathy/LLM101n development by creating an account on GitHub."
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
This repository was archived by the owner on Aug 1, 2024. It is now read-only.

**[LLM101n](https://github.com/karpathy/LLM101n)** Public archive

LLM101n: Let's build a Storyteller

[Open in github.dev](https://github.dev/) [Open in a new github.dev tab](https://github.dev/) [Open in codespace](https://github.com/codespaces/new/karpathy/LLM101n?resume=1)

<table><thead><tr><th colspan="2"><span>Name</span></th><th colspan="1"><span>Name</span></th><th><p><span>Last commit message</span></p></th><th colspan="1"><p><span>Last commit date</span></p></th></tr></thead><tbody><tr><td colspan="3"></td></tr><tr><td colspan="2"><p><a href="https://github.com/karpathy/LLM101n/blob/master/README.md">README.md</a></p></td><td colspan="1"><p><a href="https://github.com/karpathy/LLM101n/blob/master/README.md">README.md</a></p></td><td><p><a href="https://github.com/karpathy/LLM101n/commit/c6de374acd4b57b6fea3b1a1b6e945d58f19cd30">Update README.md</a></p></td><td></td></tr><tr><td colspan="2"><p><a href="https://github.com/karpathy/LLM101n/blob/master/llm101n.jpg">llm101n.jpg</a></p></td><td colspan="1"><p><a href="https://github.com/karpathy/LLM101n/blob/master/llm101n.jpg">llm101n.jpg</a></p></td><td><p><a href="https://github.com/karpathy/LLM101n/commit/21dfe611fc504104509834b32d79d4e29d95797e">initial commit</a></p></td><td></td></tr><tr><td colspan="3"></td></tr></tbody></table>

---

**!!! NOTE: this course does not yet exist. It is current being developed by [Eureka Labs](https://eurekalabs.ai/). Until it is ready I am archiving this repo!!!**

---

[![LLM101n header image](https://github.com/karpathy/LLM101n/raw/master/llm101n.jpg)](https://github.com/karpathy/LLM101n/blob/master/llm101n.jpg)

> What I cannot create, I do not understand. -Richard Feynman

In this course we will build a Storyteller AI Large Language Model (LLM). Hand in hand, you'll be able to create, refine and illustrate little [stories](https://huggingface.co/datasets/roneneldan/TinyStories) with the AI. We are going to build everything end-to-end from basics to a functioning web app similar to ChatGPT, from scratch in Python, C and CUDA, and with minimal computer science prerequisites. By the end you should have a relatively deep understanding of AI, LLMs, and deep learning more generally.

**Syllabus**

- Chapter 01 **Bigram Language Model** (language modeling)
- Chapter 02 **Micrograd** (machine learning, backpropagation)
- Chapter 03 **N-gram model** (multi-layer perceptron, matmul, gelu)
- Chapter 04 **Attention** (attention, softmax, positional encoder)
- Chapter 05 **Transformer** (transformer, residual, layernorm, GPT-2)
- Chapter 06 **Tokenization** (minBPE, byte pair encoding)
- Chapter 07 **Optimization** (initialization, optimization, AdamW)
- Chapter 08 **Need for Speed I: Device** (device, CPU, GPU,...)
- Chapter 09 **Need for Speed II: Precision** (mixed precision training, fp16, bf16, fp8,...)
- Chapter 10 **Need for Speed III: Distributed** (distributed optimization, DDP, ZeRO)
- Chapter 11 **Datasets** (datasets, data loading, synthetic data generation)
- Chapter 12 **Inference I: kv-cache** (kv-cache)
- Chapter 13 **Inference II: Quantization** (quantization)
- Chapter 14 **Finetuning I: SFT** (supervised finetuning SFT, PEFT, LoRA, chat)
- Chapter 15 **Finetuning II: RL** (reinforcement learning, RLHF, PPO, DPO)
- Chapter 16 **Deployment** (API, web app)
- Chapter 17 **Multimodal** (VQVAE, diffusion transformer)

**Appendix**

Further topics to work into the progression above:

- Programming languages: Assembly, C, Python
- Data types: Integer, Float, String (ASCII, Unicode, UTF-8)
- Tensor: shapes, views, strides, contiguous,...
- Deep Learning frameworks: PyTorch, JAX
- Neural Net Architecture: GPT (1,2,3,4), Llama (RoPE, RMSNorm, GQA), MoE,...
- Multimodal: Images, Audio, Video, VQVAE, VQGAN, diffusion