---
title: Arm64(ARMv8) Assembly Programming (00)
source: https://www.mztn.org/dragon/arm6400idx.html
author: 
published: 
created: 2025-05-22
description: Arm64 Assembly Programming
tags:
  - clippings
  - tech/osdev
  - assembly
status: bm
updated: 2025-06-10T06:33
---
## はじめに (2015-12-11, 2020-07-04)

[2011年10月にARMの64ビットアーキテクチャが発表](https://web.archive.org/web/20190101024118/https://www.arm.com/about/newsroom/arm-discloses-technical-details-of-the-next-version-of-the-arm-architecture.php) され、最初のARM64のCPU であるApple A7が載った iPhone 5S が2013年9月に発売されてから、 7年ほど経過しました。 ARM の64ビットCPU はすでにスマートフォンの中の普通のCPUとなっています。iPhone 5s 以降、 iPhone6s ではApple A9、 iPhoneXS でが A12 が使われてます。 Androidの機種では [Qualcomm](https://www.qualcomm.com/) の [Snapdragon 410](https://www.qualcomm.com/products/snapdragon/processors/410) ぐらいから始まって、 [Snapdragon 765](https://www.qualcomm.com/products/snapdragon-765-5g-mobile-platform) 、 [Snapdragon 865](https://www.qualcomm.com/products/snapdragon-865-5g-mobile-platform) といったCPUが採用されるようです。 [シングルボードコンピュータ](https://ja.wikipedia.org/wiki/%E3%82%B7%E3%83%B3%E3%82%B0%E3%83%AB%E3%83%9C%E3%83%BC%E3%83%89%E3%82%B3%E3%83%B3%E3%83%94%E3%83%A5%E3%83%BC%E3%82%BF) としても [https://www.96boards.org](https://www.96boards.org/) で [Qualcomm の DragonBoard 410c](https://developer.qualcomm.com/hardware/dragonboard-410c) や [HiKey](https://www.96boards.org/products/ce/hikey-circuitco/) 、 [LeMaker](https://www.lemaker.org/) の [Hikey(LeMaker版)](https://www.mztn.org/dragon/hikey01.html) が 1万円程度で入手できました。

さらに [Orange Pi PC2](https://www.orangepi.org/orangepipc2/) という 4 コアの 64 ビット の ARMv8 ([Allwinner H5](https://www.allwinnertech.com/index.php?c=product&a=index&id=57)) を使ったシングルボードコンピュータが2016年末に登場し、送料込み2500円程度で入手できました([Orange Pi PC2 の性能と Ubuntu のインストール](https://www.mztn.org/dragon/opipc201.html))。

2020年6月現在では、4コアのCortex-A72(1.5GHz)が搭載された [Raspberry Pi4](https://www.raspberrypi.org/) が5000円強で購入できます。 メモリ 8GB でも8000円強です。 自宅サーバとして使用するには十分な性能です。 さらにスーパーコンピュータの分野でも、ARM64のCPUを使った [富岳](https://www.r-ccs.riken.jp/jp/fugaku/overview.html) が [TOP500](https://top500.org/lists/top500/2020/06/highs/) のランキングで1位を獲得しています。

PC の分野でも Apple が [Mac](https://www.apple.com/jp/mac/) の CPU を ARM64 に変更する予定 ([macOS Big Sur Enables Transition to Apple Silicon](https://www.apple.com/newsroom/2020/06/apple-announces-mac-transition-to-apple-silicon/)) となっています。 もう完全にメジャーな CPU アーキテクチャになりました。

個人でも簡単に入手して Arm64 のアセンブリプログラミングができるので、を始めてみます。 よく使われる命令から初めて、分りやすい解説ができたらいいなと思います。

下の表は、bash と python3.4、rvtl-arm64を逆アセンブルして得られた 676,628 命令のうち、よく使われている上位 95% の命令です。 [8000ページ以上の公式マニュアル](https://www.mztn.org/dragon/#reference) を見ると500以上の命令がありますが、 よく使われる命令はこんなものです。 この程度ならば何とかなりそうですね。

| 命令 | 頻度(%) | 機能 |
| --- | --- | --- |
| [mov](https://www.mztn.org/dragon/arm6405str.html#mov) | 16 | レジスタ間のコピー |
| [ldr](https://www.mztn.org/dragon/arm6404ldr.html#load) | 13 | メモリからレジスタに読み出し |
| [b](https://www.mztn.org/dragon/arm6408cond.html#b) | 10 | 無条件分岐 |
| [bl](https://www.mztn.org/dragon/arm6408cond.html#bl) | 9 | サブルーチン呼び出し |
| [add](https://www.mztn.org/dragon/arm6406calc.html#add) | 8 | 加算 |
| [cmp](https://www.mztn.org/dragon/arm6406calc.html#cmp) | 6 | 比較 |
| [str](https://www.mztn.org/dragon/arm6405str.html#store) | 6 | レジスタからメモリへ格納 |
| [ldp](https://www.mztn.org/dragon/arm6405str.html#ldp) | 5 | スタックから取り出し |
| [stp](https://www.mztn.org/dragon/arm6405str.html#stp) | 4 | スタックへ格納 |
| [adrp](https://www.mztn.org/dragon/arm6405str.html#adrp) | 3 | レジスタにアドレスを設定 |
| [cbz](https://www.mztn.org/dragon/arm6408cond.html#cbz) | 3 | 比較して 0 なら分岐 |
| [b.eq](https://www.mztn.org/dragon/arm6408cond.html#bcond) | 3 | 等しければ分岐 |
| [ret](https://www.mztn.org/dragon/arm6408cond.html#ret) | 3 | サブルーチンから戻る |
| [sub](https://www.mztn.org/dragon/arm6406calc.html#sub) | 2 | 減算 |
| [b.ne](https://www.mztn.org/dragon/arm6408cond.html#bcond) | 2 | 異なれば分岐 |
| [adr](https://www.mztn.org/dragon/arm6405str.html#adr) | 1 | レジスタにアドレスを設定 |
| [cbnz](https://www.mztn.org/dragon/arm6408cond.html#cbnz) | 1 | 比較して非 0 なら分岐 |
| [and](https://www.mztn.org/dragon/arm6406calc.html#and) | 1 | ビット積 |

  

## ARM64とは

ARM 系の CPU は、 [ARM Ltd.](https://www.arm.com/)が設計した CPU を複数の CPU メーカがライセンス生産しています。 アーキテクチャとコア、チップ、命令セットに別の名前が付いています。 実際の CPUチップ の型名はメーカ毎にいろいろな名前があります。それぞれの CPU は、ARM Ltd.が設計した CPU コアのアーキテクチャバージョンで大まかに区別できます。

例えば、 [Raspberry Pi1](https://www.raspberrypi.org/products/model-b-plus/) は **ARMv6** アーキテクチャで ARM1176JZF-S コア の BCM2835 チップを使っています。 [Raspberry Pi2](https://www.raspberrypi.org/products/raspberry-pi-2-model-b/) は **ARMv7** アーキテクチャで [Cortex-A7 コア](https://www.arm.com/ja/products/processors/cortex-a/cortex-a7.php) が4つ入った BCM2836 チップを使っています。ARMv6 と ARMv7 は 32ビットのアーキテクチャです。

64ビットのアーキテクチャとしては、 [Qualcomm の DragonBoard 410c](https://developer.qualcomm.com/hardware/dragonboard-410c) が **ARMv8** アーキテクチャで Cortex A53 コアのSnapdragon 410というチップを使っています。 ARMv8 アーキテクチャは32ビットの実行ステート (AArch32) も含んでいるため、32ビットと64ビットの両方が使えます。 「 **ARMv8** アーキテクチャの **AArch64** 実行状態をサポートする **A64** 命令セット」が正しい表現と思いますが、短く「 **ARM64** 」と呼ぶことにします

汎用レジスタの数が ARM32 の [16 個](https://www.mztn.org/slasm/arm02.html#reg) から ARM64 では、 30 個 (X0.. X29) に増え、汎用レジスタのサイズも64ビットに拡張されています。 命令のサイズは 32 ビット固定長のままとなっています。 命令の大きさを変えずに大きなデータを扱うため、ARM32とは命令のビットパターン(エンコード)が全く異なっています。 [AMD](https://www.amd.com/ja-jp/products/processors) が設計した [x86-64](https://www.mztn.org/lxasm64/amd00.html) のように 32 ビットの x86 との互換性を重視した複雑なエンコードではなく、ARM はシンプルでキレイなビットパターンとして 64 ビット命令を再設計することを選んだようです。 アセンブラの表記法が32ビット命令と近い書き方になっているものの、レジスタ、アドレッシングモード、命令ともに似ているようで違ったものになっています。 また、浮動小数点演算とSIMDはオプション扱いではなくなっています。常にハードウェアで浮動小数点演算を行うようになります。

演算結果で変化するフラグの条件で命令を実行したり、スキップしたりする [条件実行](https://www.mztn.org/slasm/arm02.html#sf) の機能を多くの種類の命令で持っていることが、他の CPU にはない ARM32 の特徴となっています。 ARM64では多くの命令でこの条件実行の機能はなくなり、条件付命令は分岐(b)、比較(ccmp等)、選択(csel)とわずかに残るのみになりました。 また、スタックへの複数レジスタの退避／復帰が 1 命令で行える便利な [LDM / STM 命令](https://www.mztn.org/slasm/arm05.html) もなくなり、2つのレジスタに限定された LDP / STP 命令に変わっています。

32ビットと64ビットの命令の互換性を重視しなかった理由は、64ビットの命令も 32 ビット固定長にしたところにあります。 ARM の演算命令は 32 ビットでも 64 ビットでも、1命令中にレジスタを 3 つ指定することができます。 加算命令を例にすると「A=B+C」といったように2つのレジスタの演算結果を別のレジスタに格納することができます。「A=A+B」のように基本的に 1 命令中に 2つのレジスタしか使えない x86 とは異なっています。

30 個のレジスタを指定するためには 5 ビット(0..31)が必要です。 さらに64ビットの汎用レジスタの内容を8ビット、16ビット、32ビットといった小さい単位でもデータを扱おうとすると、そこでもサイズの区別のために2ビットが必要となります。 単純に考えるとレジスタの指定だけでも3つのレジスタで 21ビット が必要となり、32ビットの固定長の命令とするためには無理があります。

インテルの32ビットCPU(x86) の64ビット版である [x86-64](https://www.mztn.org/lxasm64/amd00.html) では、1つのレジスタを 64 ビットで使う場合はRAX、32ビットではEAX, 16ビットではAX, 8ビットでは AL レジスタとして指定できますが、次の例のように 長いものでは 8 バイト以上を使う可変長の命令となっています。

```
67 89 0c 95 40 68 60 00    mov  DWORD PTR [edx * 4 + 0x606840], ecx
  03 75 28                   add    esi, DWORD PTR [rbp + 0x28]
  48 8d 7c dd 00             lea    rdi, [rbp + rbx * 8 + 0x0]
  48 8d 05 1b 03 00 00       lea    rax, [rip + 0x31b]
```

ARM64では、すべての命令を 32 ビットで表現するために色々な工夫がされていて、まず最初に ARM32 でほとんどの命令で可能であった条件実行をなくすことで 4 ビットを節約しています。さらにレジスタを 8 ビットと 16 ビットで指定することをあきらめることで 1 ビット、3 レジスタで 3 ビットの節約ができます。 指定するレジスタをビットマップで指定できる [ARM32 の LDM / STM 命令](https://www.mztn.org/slasm/arm05.html) はレジスタが倍増したため不可能になりました。

このような工夫を積み重ねることで、できるだけ ARM32 との互換性を考えながら、64ビットCPUでも苦労して命令長を 32 ビットに収める様子が想像できて楽しめます(笑)。

## 参考資料

最も詳細なドキュメントは、ARM Architecture Reference Manual で、 [https://developer.arm.com/architectures/cpu-architecture/a-profile/doc](https://developer.arm.com/architectures/cpu-architecture/a-profile/docs) から入手できます。 2020年07月現在の最新版は Armv8.6 (2020-03-31, DDI0487F\_b\_armv8\_arm.pdf, 8128page) です。 32ビット命令を含めて8000ページ以上の膨大な量のドキュメントです。 個別の命令のエンコードや疑似コードで詳細な動作が記述されています。 読みやすいものではありません。

**ARM64 アセンブリプログラミング**

  
- [0\. はじめに](https://www.mztn.org/dragon/arm6400idx.html) 【このページ】 (2020-07-04)
- [1\. メモリ、バイト、エンディアン](https://www.mztn.org/dragon/arm6401bin.html) (2015-12-11)
- [2\. アセンブラのインストール](https://www.mztn.org/dragon/arm6402as.html) (2015-12-11)
- [3\. ARM64のレジスタ](https://www.mztn.org/dragon/arm6403reg.html) (2015-12-23)
- [4\. ロード命令](https://www.mztn.org/dragon/arm6404ldr.html) (2015-12-27)
- [5\. ストア命令](https://www.mztn.org/dragon/arm6405str.html) (2016-01-12)
- [6\. 演算命令](https://www.mztn.org/dragon/arm6406calc.html) (2016-01-24)
- [7\. シフト命令](https://www.mztn.org/dragon/arm6407shift.html) (2016-01-30)
- [8\. 分岐命令など](https://www.mztn.org/dragon/arm6408cond.html) (2016-02-04)
- [9\. 浮動小数点レジスタと命令](https://www.mztn.org/dragon/arm6409float.html) (2017-01-28)
- [10\. 浮動小数点数の表示](https://www.mztn.org/dragon/arm6410print.html) (2017-01-28)
- [11\. 浮動小数点数のロード/ストア命令](https://www.mztn.org/dragon/arm6411fldr.html) (2017-02-11)
- [12\. ベクトルのロード/ストア命令](https://www.mztn.org/dragon/arm6412ldnstn.html) (2017-03-02)
- [13\. 浮動小数点数のレジスタ間移動命令](https://www.mztn.org/dragon/arm6413mov.html) (2017-04-23)
- 続く  
	  
	Stay tuned. Comming Soon.
  

### 続く...

  
  

## ARM64 アセンブリ

- [0\. はじめに](https://www.mztn.org/dragon/arm6400idx.html)
- [1\. メモリ、バイト、エンディアン](https://www.mztn.org/dragon/arm6401bin.html)
- [2\. アセンブラのインストール](https://www.mztn.org/dragon/arm6402as.html)
- [3\. ARM64 のレジスタ](https://www.mztn.org/dragon/arm6403reg.html)
- [4\. ロード命令](https://www.mztn.org/dragon/arm6404ldr.html)
- [5\. ストア命令](https://www.mztn.org/dragon/arm6405str.html)
- [6\. 演算命令](https://www.mztn.org/dragon/arm6406calc.html)
- [7\. シフト命令](https://www.mztn.org/dragon/arm6407shift.html)
- [8\. 条件分岐、システムコール](https://www.mztn.org/dragon/arm6408cond.html)
- [9\. 浮動小数点レジスタと命令](https://www.mztn.org/dragon/arm6409float.html)
- [10\. 浮動小数点数の表示](https://www.mztn.org/dragon/arm6410print.html)
- [11\. 浮動小数点数のロード/ストア命令](https://www.mztn.org/dragon/arm6411fldr.html)
- [12\. ベクトルのロード/ストア命令](https://www.mztn.org/dragon/arm6412ldnstn.html)
- [13\. 浮動小数点数のレジスタ間移動命令](https://www.mztn.org/dragon/arm6413mov.html)
- つづく...
- [インタプリタの作成](https://github.com/jun-mizutani/rvtl-arm64)
- [Dragonboard 410C のインストール](https://www.mztn.org/dragon/dbd01.html)
- [仮想 Arm64 マシンの作り方](https://www.mztn.org/dragon/arm64_01.html)
- [HiKey のインストール](https://www.mztn.org/dragon/hikey01.html)
- [Orange Pi PC2 の性能と Ubuntu のインストール](https://www.mztn.org/dragon/opipc201.html)
- [Raspberry Pi2、Orange Pi Zero/PC2 の UnixBench](https://www.mztn.org/dragon/opizero1.html)
  

## アセンブリ言語シリーズ

- [PowerPC アセンブリ](https://www.mztn.org/ppcasm/ppcasm01.html)
- [ARM アセンブリ](https://www.mztn.org/slasm/arm00.html)
- [x86 アセンブリ](https://www.mztn.org/lxasm/asm00.html)
- [x86-64 アセンブリ](https://www.mztn.org/lxasm64/amd00.html)

## ラズベリーパイ メモ

- [Raspberry Pi メモ 目次](https://www.mztn.org/rpi/rpi00.html)
- [★ 逆引き Raspberry Pi メモ ★](https://www.mztn.org/rpi/rpi00.html#reverse)
- [(1) Raspberry Pi到着](https://www.mztn.org/rpi/rpi01.html)
- [(2) ブート用SDカードの作成](https://www.mztn.org/rpi/rpi02.html)
- [(3) アセンブリで浮動小数点数表示](https://www.mztn.org/rpi/rpi03.html)
- [(4) 軽く三次元](https://www.mztn.org/rpi/rpi04.html)
- [(5) ベクトル演算の実力](https://www.mztn.org/rpi/rpi05.html)
- [(6) 転んでも泣かない!](https://www.mztn.org/rpi/rpi06.html)
- [(7) OpenGL ES2 (1) 概要](https://www.mztn.org/rpi/rpi07.html)
- [(8) OpenGL ES2 (2) 初期化](https://www.mztn.org/rpi/rpi08.html)
- [(9) 公式オーバークロック](https://www.mztn.org/rpi/rpi09.html)
- [(10) OpenGL ES2 (3) シェーダの使い方](https://www.mztn.org/rpi/rpi10.html)
- [(11) OpenGL ES2 (4) 三次元で三角形](https://www.mztn.org/rpi/rpi11.html)
- [(12) OpenGL ES2 (5) テクスチャ](https://www.mztn.org/rpi/rpi12.html)
- [(13) OpenGL ES2 (6) シェーダで照明](https://www.mztn.org/rpi/rpi13.html)
- [(14) 新wheezy-raspbian と「まとめ」](https://www.mztn.org/rpi/rpi14.html)
- [(15) Tiny BASIC と ASLR](https://www.mztn.org/rpi/rpi15.html)
- [(16) 新イメージ 2012-12-16](https://www.mztn.org/rpi/rpi16.html)
- [(17) 各種言語のベンチマーク](https://www.mztn.org/rpi/rpi17.html)
- [(18) Pi専用の Minecraft の使い方](https://www.mztn.org/rpi/rpi18.html)
- [(19) LuaJITでお手軽3D (1)](https://www.mztn.org/rpi/rpi19.html)
- [(20) LuaJITでお手軽3D (2) LjESリリース](https://www.mztn.org/rpi/rpi20.html)
- [(21) 新 raspbian と Wayland/Weston](https://www.mztn.org/rpi/rpi21.html)
- [(22) LuaJITでお手軽3D (3) NodeとShape](https://www.mztn.org/rpi/rpi22.html)
- [(23) カメラモジュールの使い方](https://www.mztn.org/rpi/rpi23.html)
- [(24) 2013-09-25-wheezy-raspbian と「まとめ」](https://www.mztn.org/rpi/rpi24.html)
- [(25) LuaJITでお手軽3D (4) テクスチャマッピング](https://www.mztn.org/rpi/rpi25.html)
- [(26) raspbian(2013-12-20)とMathematica](https://www.mztn.org/rpi/rpi26.html)
- [(27) RPI Expansion Board (X100)のレビュー](https://www.mztn.org/rpi/rpi27.html)
- [(28) 液晶ディスプレイ一体型PC](https://www.mztn.org/rpi/rpi28.html)
- [(29) LuaJITでお手軽3D (5) LjES-2 リリース](https://www.mztn.org/rpi/rpi29.html)
- [(30) GPIO とシャットダウンボタン](https://www.mztn.org/rpi/rpi30.html)
- [(31) Lua でオブジェクト指向](https://www.mztn.org/rpi/rpi31.html)
- [(32) 新Raspbianとリアルタイムクロック](https://www.mztn.org/rpi/rpi32.html)
- [(33) 2014-09-09-wheezy-raspbian のインストール](https://www.mztn.org/rpi/rpi33.html)
- [(34) デスクトップの軽量な日本語化](https://www.mztn.org/rpi/rpi34.html)
- [(35) デスクトップのカスタマイズ](https://www.mztn.org/rpi/rpi35.html)
- [(36) 2014-12-24-wheezy-raspbian の変更点](https://www.mztn.org/rpi/rpi36.html)
- [(37) Java8 プログラミング](https://www.mztn.org/rpi/rpi37.html)
- [(38) Raspberry Pi でラムダ式](https://www.mztn.org/rpi/rpi38.html)
- [(39) Raspberry Pi 2 始動](https://www.mztn.org/rpi/rpi39.html)
- [(40) Raspberry Pi2 の互換性](https://www.mztn.org/rpi/rpi40.html)
- [(41) ゲームパッドでシャットダウン](https://www.mztn.org/rpi/rpi41.html)
- [(42) Raspberry Pi2 の非互換性とGPIO](https://www.mztn.org/rpi/rpi42.html)
- [(43) Node.js で JavaScript](https://www.mztn.org/rpi/rpi43.html)
- [(44) ハードディスク起動とヘアピンNAT](https://www.mztn.org/rpi/rpi44.html)
- [(45) 2015-05-05版と新しい無線LAN設定方法](https://www.mztn.org/rpi/rpi45.html)
- [(46) Jessie がやってきた](https://www.mztn.org/rpi/rpi46.html)
- [(47) 公式7インチタッチパネルの自作ケース](https://www.mztn.org/rpi/rpi47.html)
- [(48) Raspberry Pi2 で Blender を使う](https://www.mztn.org/rpi/rpi48.html)
- [(49) 本気でタッチスクリーンを使う](https://www.mztn.org/rpi/rpi49.html)
- [(50) ゲームパッドでコマンドを実行](https://www.mztn.org/rpi/rpi50.html)
- [(51) Raspberry Pi3 と Stretch と Electron](https://www.mztn.org/rpi/rpi51.html)
- [(52) Raspberry Pi Pico](https://www.mztn.org/rpi/rpi52.html)
- [(53) Pico でCO2センサーを作成](https://www.mztn.org/rpi/rpi53.html)
- [(54) 2021-10-30-raspios-bullseye のインストール](https://www.mztn.org/rpi/rpi54.html)
- [(55) LXC でコンテナを本格的に運用する](https://www.mztn.org/rpi/rpi55.html)
  
- つづく...かも
  

## ARM アセンブリ

- [はじめに](https://www.mztn.org/slasm/arm00.html)
- [1\. アセンブラのインストールと実行](https://www.mztn.org/slasm/arm01.html)
- [2\. ARMのレジスタ](https://www.mztn.org/slasm/arm02.html)
- [3\. 演算命令と分岐命令](https://www.mztn.org/slasm/arm03.html)
- [4\. ロード／ストア命令](https://www.mztn.org/slasm/arm04.html)
- [5\. ロード／ストア命令(複数レジスタ)](https://www.mztn.org/slasm/arm05.html)
- [6\. システムコールとその他の命令](https://www.mztn.org/slasm/arm06.html)
- [7\. アセンブラGNU asの基礎知識](https://www.mztn.org/slasm/arm07.html)
- [8\. 標準入出力用のサブルーチンの作成](https://www.mztn.org/slasm/arm08.html)
- [9\. フレームバッファでグラフィックス - その１](https://www.mztn.org/slasm/arm09.html)
- [A. システムコールと引数一覧](https://www.mztn.org/slasm/arm_sys.html)
- [B. インタプリタの作成](https://www.mztn.org/rvtl/rvtl_arm.html)