---
title: OS開発に必要なArmアーキテクチャとは part.1 　実行モデルと割り込み　 | ログミーBusiness
source: https://logmi.jp/main/technology/323824
author: 
published: 
created: 2025-05-22
description: 概要と自己紹介金津穂氏（以下、金津）：「AArch64とOS入門」ということで金津が発表いたします。はじめにですが、「これからArmでOSを自作したい！」という人向けのまとめ資料になります。なので、すでにArmでお仕事している人、とくに組み...
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
[ARM入門勉強会](https://logmi.jp/events/detail/2418)

OS開発に必要なARMアーキテクチャ. プロテクション、割り込み、MMU、の使い方, ARMで動くカーネルの紹介など（全2記事）

## OS開発に必要なArmアーキテクチャとは part.1 実行モデルと割り込み

リンクをコピー

記事をブックマーク

![](https://images.logmi.jp/media/article/323824/images/Gvyvu21onPGMM5Gt3bY9Wf.png?w=850)

[画像・スライド一覧](https://logmi.jp/main/technology/gallery/323824)

Arm入門勉強会とは、macOSがArmに移行したこの機にArmアーキテクチャでのプログラミングについて入門するソフトウェアエンジニアのための会です。OS開発に必要なArmの低レイヤーなプログラミングについて、金津穂氏が共有しました。前半はArmの実行モデルと割り込みについて。全2回。

## 概要と自己紹介

**金津穂氏（以下、金津）** ：「AArch64とOS入門」ということで金津が発表いたします。

はじめにですが、「これからArmでOSを自作したい！」という人向けのまとめ資料になります。なので、すでにArmでお仕事している人、とくに組み込み向けだったりとかすでにOS開発とかしている人にとってはもう既知の情報しかない。あと、リファレンスマニュアルを自分で読める人にとっては、それを読んだほうが確実な情報が手に入るんじゃないかなと思います。

Armと題してますけど、基本的にはAArch64だけにします。AArch32はちょっと面倒くさいので触りません。Cortex-MなどのMシリーズはまた別の機会ということで、今回はAシリーズ、これを発表していきます。

![](https://images.logmi.jp/media/article/323824/images/editor/17roScxW6vM9tzsSXjYu9k.png)

まず私、orumin。Twitter「kotatsu\_mi」でやっています。主にunikernelとか仮想化とかをやってて、博士学生です。

## OSに必要なプロセッサー機能

では始めていきます。まずOSに必要なプロセッサーの機能とは何でしょうか？

OSの中でも、モダンなOSに求められる必須要素というものが存在すると思います。最近は、WindowsだったりLinuxだったりMacといったモダンなデスクトップOS、あるいは組み込みでもモダンなOSが多いと思いますが、こういったものではマルチタスクやメモリ保護、そして計算資源の抽象化や多重化といったものが前提となっています。

今回は、この中でもマルチタスクやメモリ保護について主にフィーチャーしていこうかと思います。ということで、主にマルチタスクに必要な割り込みやコンテキスト退避、メモリ保護に必要なMMU、これに絞って説明をしていきたいと思います。

![](https://images.logmi.jp/media/article/323824/images/editor/MCdfKtWCycuNgJgXXrvKND.png)

## Armの名前

まず本題に入る前に……。みなさんArmの名前、いつも混乱していると思います。先ほどtnishinagaさんにもいろいろと説明してもらいましたが、一度おさらいしておくと、ArmはArm社のプロセッサーということで、もともとはイギリスのAcornという会社が作っていた、Acorn RISC Machinesという特定のAcorn社のPC向けのプロセッサーでした。

そのあとAdvanced RISC Machines、ARM Ltd.、Arm Holdings plcと主体が変遷してて、現在Arm Holdingsはソフトバンクが買収しています。もともとArmはすべて大文字「ARM」でしたが、現在、先頭のAだけ大文字の「Arm」というのが正式名称です。

また、64-bit Armのアーキテクチャ名は基本的に「AArch64」で、「Arm64」というのはGNUがreferして使っている名前です。「Intel 64」が正式名称でありながら、GNU、GCCだと「x86-64」のほうを使うのと同じような理由です。

AArch64では先ほどtnishinagaさんが説明したようにA64。AArch32ではA32とT32の命令セットが利用できます。

商標のページを見てても、記事タイトルとかですべて大文字にするような何か必要性がないかぎりは、基本的には不適切な大文字化は避けよと書かれています。

![](https://images.logmi.jp/media/article/323824/images/editor/TBztvv8SCUGChfUd1DM8Ao.png)

## Armの実行モデル

では本題です。まずArmの実行モデルについて話していこうと思います。これからは、基本的にはIntel 64のCPUプロセッサーと比較して話していきます。

まずIntel。みなさん知っているかと思いますが、Intelはリング（Ring）といったものを使って実行権限を分離しています。Ring 0・1・2・3がありまして、Ring 0が特権モード、いわゆるOSカーネルを動作させるモードで、Ring 3がみんなが使っているブラウザなどのアプリケーションです。

Ring 1・2は、本当はOSのドライバとかをよりRing 0よりも小さな権限で実行することでセキュリティを担保する、そういった理由で作られているのですが、実際のところ誰も使っていません。

というのも、基本的には特権モードが多すぎるとOSをそれに特化させて実装しなければいけないんですが、x86-64だけで動くPCなどではそれでいいんですけど、Windows NTだったりLinuxだったり複数のアーキテクチャで動く必要のあるものは、基本的には2つのモードがあったとしてもRing1・Ring2といったものは存在しないため、それらは使わないことになってしまって、実質2モードしかないことになっています。

一方、Armを見てみましょう。ArmではRingではなくて、Exception Level（例外レベル）という名前で実行モードを分けています。Intelと違って、数字の若いほうから権限が弱くなっていて、数字の大きいほうが権限が一番強くなっています。0から順番にUser、OS、Hypervisor、そしてSecure Monitorとなっていまして、Secure Monitorというのは基本的にTrustZoneなどのセキュアOSで実行するものになっています。

TrustZoneについては後ほど説明があると思うので、今回は省こうと思います。Hypervisorについても、ぬるぽへさんがあとでしゃべると思うので、今回の資料では、EL0とEL1、この2つのモードに絞って説明していこうと思います。

![](https://images.logmi.jp/media/article/323824/images/editor/5rwenbL22Bd2Jfgjtbsv8j.png)

## AArch32の実行モデル

その前に、いちど、AArch32の実行モデルを説明していこうと思います。先ほどException Levelという話をしましたが、こちらの図のException Level 1のところにService Call（svc）・Abort（abt）・IRQ（irq）・FIQ（fiq）・Undefined（und）・System（sys）、これら6つモードが書いてあります。

これはどういうことかと言いますと、もともとAArch32・ARMv7では7つCPUの動作モードがありまして、特権モードは7つのモードのうちの6つ、1つUserモードだけ非特権モードになっており、それぞれモードによって汎用レジスタがバンク切り替えすることによっていろいろなモードを切り替えて実行する、そういったことになっていました。

実はAArch64でもAArch32モードに切り替えることができるので、途中でそのモードに……6つのモードを意識した状態で実行することも可能なのですが、今回の発表ではそこはなるべく触れないようにしていきます。ですが、たまに古いOSの実装とか読むときには、これも必要となってくるので、頭の片隅に置いておくと何か役に立つかもしれません。

![](https://images.logmi.jp/media/article/323824/images/editor/4vX1MhJzh4nzatwL4hBr7D.png)

## AArch64の割り込み

AArch64の割り込みについてです。AArch64はAArch32と違って、いくつかレジスタとか増やしていて、基本的に割り込みに関係するのはここらへんのレジスタになります。

まずPSTATE。これは条件フラグとか現在の例外レベルといった状態を記憶しておきます。例外が実際に発生したときには、SPSRというレジスタにPSTATEを保存して退避して、別の例外レベルにジャンプします。SPSRは例外レベルごとに1〜3まで3つ別々に存在しているため、例えばOSの中でHypervisor Call（HVC）を発行したら、そのときのPSTATEをまたSPSR\_EL2に保存してといったかたちで、順番にジャンプすることが可能です。

そしてリンクレジスタ（LR）。これは先ほど説明がありましたね。サブルーチンからのリターンアドレスを記憶しますが、例外リンクレジスタというELRというものも存在します。これは例外からのリターンアドレスを記憶するもので、リンクレジスタと基本的に使い方は同じですが、例外のハンドリングのときに使用します。

![](https://images.logmi.jp/media/article/323824/images/editor/5AVhp48U1Kj9K2dUBfZ2hV.png)

次にベクタテーブルを見ていきます。AArch64はベクタテーブルを割り込みレベルEL1〜3それぞれ別々に持っていて、それぞれVBAR\_ELnというアドレスからのオフセットでアクセスできます。

例えばVBAR\_ELnがcurrent ELをSP0でとか書いてありますけど、これはどういうことかといいますと、例えばOS、EL1の中でもう一度OSの割り込みが発生するNested IRQが起きたときに同じ例外レベルでハンドリングすることになったら、SP0を使ってそのまままた例外に返ってくる。そのときの例外の種類によってIRQだったりFIQだったりSErrorだったりとかで、それぞれ0x080、0x100、0x180などにジャンプして、そこに登録されている例外ハンドラを実行するかたちになっています。

また、SP0だけじゃなくて、SPは例外レベルポイントごとにあったりするんですけど、SPSelというビットがあったりするので、それでSPを切り替えたりすることもできます。

より低い例外レベルに遷移したときにAArch64からAArch32に切り替えるなどもあるので、それぞれより低い例外レベルにジャンプしたときのベクタはAArch64モード版とAArch32版でそれぞれ別々に用意されていて、0x780までベクタが存在しています。

![](https://images.logmi.jp/media/article/323824/images/editor/6dkcmbAjijuCZBzyXYnuxv.png)

## 割り込みフローとコード例

このときの割り込みのフローを実際に見てきますと、EL0 User Programで、例えばSupervisor Call（SVC）、いわゆるシステムコールを発行したらIRQが起きるので、そこでProgram Counterレジスタ（PC）を、Exception level Link Register（ELR）、例外のリンクレジスタに保存。また、現在の状態はPSTATEからSPSRに退避して、実際の割り込みを実行し始める。

割り込みのハンドラの中でまたレジスタ退避だったりとか割り込みを有効化することで、さらにnestedして別のinterruption handlerが呼ばれる。そういったこともあります。

基本的にはLRとPSTATE、PCなど使っていい感じにELの変化などでレジスタに退避できるので、けっこう便利な感じになっています。直感的だと思います。これは。

![](https://images.logmi.jp/media/article/323824/images/editor/MH89KrazKLpxWSVa2ah5Mw.png)

最後に割り込みについて実際のアセンブリコードを見ていきます。これは公式のドキュメントで見てみたんですけど簡単で、いっぺん壊される可能性のあるレジスタをSPに退避して、read\_irq\_sourceとかそういった割り込み原因を読むようなコードにブランチしてから、Cで実装されたハンドラにブランチしてまた割り込みに返ってくるみたいな素朴な実装になっています。また、ERETを使うことによって、ELRに保存したリターンアドレスを使ってもとの場所に返ってきます。

この実装の場合はSPSRやELRの退避をしていないので、nestedの割り込みをハンドルすることはできません。

![](https://images.logmi.jp/media/article/323824/images/editor/9Xv2gcGrd4SuWeFQ5PCNhy.png)

（次回につづく）

続きを読むには会員登録  
（無料）が必要です。

会員登録していただくと、すべての記事が制限なく閲覧でき、  
著者フォローや記事の保存機能など、便利な機能がご利用いただけます。

[無料会員登録](https://logmi.jp/auth/register?r=https%3A%2F%2Flogmi.jp%2Fmain%2Ftechnology%2F323824)

[会員の方はこちら](https://logmi.jp/auth/login?r=https%3A%2F%2Flogmi.jp%2Fmain%2Ftechnology%2F323824)

[続きを読む](https://logmi.jp/main/technology/323824?)

## この記事のスピーカー

- [
	金津穂
	](https://logmi.jp/speakers/detail/7979)

## 同じログの記事

- [1
	OS開発に必要なArmアーキテクチャとは part.1 実行モデルと割り込み](https://logmi.jp/main/technology/323824)
- [2
	OS開発に必要なArmアーキテクチャとは part.2　MMUとデバイス取得情報、ブート方法
	](https://logmi.jp/main/technology/323864)

## コミュニティ情報

[![](https://images.logmi.jp/media/communities/1232/images/icon_image_UVdzVo25eBAm4fyFkSzd2x.png)](https://logmi.jp/communities/detail/1232)

[ARM入門勉強会](https://logmi.jp/communities/detail/1232)

[記事数: 7](https://logmi.jp/communities/detail/1232)

[

macOSはARMに移行し、TOP500トップのFugakuはARMを採用、今まさにARMアーキテクチャがアツい！しかしARM何も分からん！そこでこのビッグウェーブに乗って、ARMアーキテクチャでのプログラミングについてワイワイ入門しましょうという会。各テーマに関する入門セッションと、5つの自由トークセッションをオンライン（YouTube Live）で開催。

](https://logmi.jp/communities/detail/1232)

[![広告掲載のご案内](https://logmi.jp/asset/frontend/img/side_banner_01.png)](https://logmi.co.jp/service/biz/solution/?utm_source=logmibiz&utm_medium=referral&utm_campaign=menu_top)

[![プレミアム記事が読める](https://logmi.jp/asset/frontend/img/side_banner_02.png)](https://logmi.jp/auth/register)

## ログミーBusinessに記事掲載しませんか？

イベント・インタビュー・対談 etc.

“編集しない編集”で、  
スピーカーの「意図をそのまま」お届け！

![](https://cdn.webpush.jp/20000797/329d7a37-ba91-42a5-90a4-686b8cfa8828.png)

ログミーBusinessからの通知を許可しますか?