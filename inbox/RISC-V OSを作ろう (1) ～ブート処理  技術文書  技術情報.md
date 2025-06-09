---
title: RISC-V OSを作ろう (1) ～ブート処理 | 技術文書 | 技術情報
source: https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0001/
author:
  - "[[VA Linux Systems Japan株式会社]]"
published: 
created: 2025-05-22
description: RISC-VはMIPSアーキテクチャの流れを汲むRISC CPUです。命令セットはシンプルですが、既存のメジャーなCPUのアーキテクチャと大きな違いがあるわけではありません。 Linux上で利用できるRISC-Vツール群も揃ってきたので、それらを使ってRISC-V用の小さなOSを実装してみようと思います。
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
- オペレーティングシステム

## RISC-V OSを作ろう (1) ～ブート処理

2021/05/27

技術本部 CTO・技術本部長兼制御OS開発部長　高橋 浩和

[RISC-V ハイパーバイザーを作ろう (2) ～ 仮想CPU](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0014/)

[RISC-V ハイパーバイザーを作ろう (1) ～ 概要編](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0012/)

[RISC-V OSを作ろう (12) ～ KVM上で動かそう](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0013/)

[RISC-V OSを作ろう (11) ～ SBI対応](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0011/)

[RISC-V OSを作ろう (10) ～ マルチコア (タスクスケジューリング)](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0010/)

[RISC-V OSを作ろう (9) ～ マルチコア (OSの起動)](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0009/)

[RISC-V OSを作ろう (8) ～ 簡易メモリ保護](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0008/)

[RISC-V OSを作ろう (7) ～ マシンモードとユーザモード](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0007/)

[RISC-V OSを作ろう (6) ～ セマフォ](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0006/)

[RISC-V OSを作ろう (5) ～ 時限待ち](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0005/)

[RISC-V OSを作ろう (4) ～ タイムシェアリングスケジューリング](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0004/)

[RISC-V OSを作ろう (3) ～ 割り込み](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0003/)

[RISC-V OSを作ろう (2) ～ タスク切り替え](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0002/)

RISC-V OSを作ろう (1) ～ブート処理

![](https://www.valinux.co.jp/wp/wp-content/uploads/2021/05/eyecatch20210527-2-250x250.png)

　RISC-VはMIPSアーキテクチャの流れを汲むRISC CPUです。

　命令セットはシンプルですが、既存のメジャーなCPUのアーキテクチャ  
　と大きな違いがあるわけではありません。

　Linux上で利用できるRISC-Vツール群も揃ってきたので、それらを使って  
　RISC-V用の小さなOSを実装してみようと思います。

　「 [VA Linux エンジニアブログ](https://valinux.hatenablog.com/) 」にて公開していますのでご覧ください。  
[https://valinux.hatenablog.com/entry/20210527](https://valinux.hatenablog.com/entry/20210527)

## 関連記事

- [OS徒然草 (9)](https://www.valinux.co.jp/technologylibrary/document/linux/os0009/)
- [OS徒然草 (8)](https://www.valinux.co.jp/technologylibrary/document/linux/os0008/)
- [OS徒然草 (7)](https://www.valinux.co.jp/technologylibrary/document/linux/os0007/)
- [RISC-V ハイパーバイザーを作ろう (2) ～ 仮想CPU](https://www.valinux.co.jp/technologylibrary/document/linux/riscvos0014/)