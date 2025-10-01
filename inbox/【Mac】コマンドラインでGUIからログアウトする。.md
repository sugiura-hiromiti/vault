---
title: "【Mac】コマンドラインでGUIからログアウトする。"
source: "https://qiita.com/Kit-i/items/ee32870a0b90cf196a87"
author:
  - "[[Kit-i]]"
published: 2023-07-22
created: 2025-08-01
description: "はじめに ある日Macの上部にあるメニューがクリックしても反応しない謎の事象が発生。 その他一部GUIの表示などが崩れていたものの、基本的なキーボード操作やマウス操作は効いたため、コマンド操作によりログアウトできないだろうかと考えた。 [Coomand] + [Ctr..."
tags:
  - "clippings"
status: "unread"
aliases:
---
More than 1 year has passed since last update.

## はじめに

ある日Macの上部にあるメニューがクリックしても反応しない謎の事象が発生。  
その他一部GUIの表示などが崩れていたものの、基本的なキーボード操作やマウス操作は効いたため、コマンド操作によりログアウトできないだろうかと考えた。

\[Coomand\] + \[Ctrl\] + \[Q\]によりログインウィンドウへ一度戻り再ログインするだけでは事象は解決しなかった。

## TL;DR

- Macのlogoutコマンドはexitコマンドと同じ。
- ログアウトの機能を提供する直接的なコマンドはない模様
- ログアウトはlaunchctl bootoutコマンドを利用して実現する

以下のコマンドでログアウト可能。

logout

```bash
launchctl bootout user/$(id -u)
```

## logoutコマンド

zshの場合ビルトインコマンドとして"logout"コマンドが用意されております。  
一見いかにもログアウトできそうなコマンドですが、  
このコマンドはexitコマンドと同じ動きとなり、  
アクティブシェルを閉じるだけで、GUIからログアウトを行うことはできませんでした。  
マニュアルにも"same as exit"と記載されております。

## launchctl bootout

### launchctl

launchctlはlaunchdを操作するためのコマンドラインツールです。  
launchdはMacのサービス(デーモン)を管理しているような存在で、  
誤解を恐れずに言えば、RHELでいうsystemdのようなものと捉えていただければいいと思います。

launchctlはサブコマンド形式の構文となります。  
ログアウトを行う場合、サブコマンドとして"bootout"と指定します。

書式

```bash
launchctl サブコマンド
```

### bootout

launchctlのサブコマンドの一つです。  
bootoutは特定のサービスをアンロードします。

書式

```bash
launchctl bootout domain-target [service-path service-path2 ...] | service-target
```

#### domain-target

launchdが管理するプロセスグループのようなものと認識してます。  
以下の3つが存在するようです。

- system
- user/<uid>
- gui/<uid>

つまりアンロードさせる対象がどの領域かによって指定するドメインが変わるのでしょう。  
ドメインがsystemにあたるものはプロセスの実行ユーザがrootとなっていものと考えられます。  
まさにlaunchdなんかはこのドメインに属すると推測できます。

userとguiはどちらも任意のユーザによって実行されたプロセスを対象とする際に指定しますが、  
userの場合ログインの有無は問わないのに対して、  
guiの方はGUIログインしているアクティブなユーザのみを対象とした領域となるようです。  
<参考>  
[launchctl/launchd cheat sheet](https://gist.github.com/masklinn/a532dfe55bdeab3d60ab8e46ccc38a68)

今回のケースではbootoutの引数としてはdomain-targetのみを指定します。

> If no paths or service target are specified, these commands can  
> either bootstrap or remove a domain specified as a domain  
> target. Some domains will implicitly bootstrap pre-defined paths  
> as part of their creation.
> 
> 引用：launchctlのhelpよりbootstrap|bootout箇所を抜粋

service-pathやservice-targetを指定しない場合、  
domain-targetで指定されたドメインをremoveすると記載があります。  
removeという表現が誤解を招きそうですが、  
指定したドメインのプロセスを全てkillする（終了させる)くらいに捉えていただくのがいいと思います。  
決して特定のユーザアカウント削除するような動きではありません。  
これにより、対象ユーザを親とするプロセスがkillされることで、結果としてログアウトが実現されるものと捉えます。

今回は任意のユーザーのログアウトをということで、  
ドメインは"user"とします。  
加えてどのユーザーを対象とするかUIDで指定する必要があります。

##### UIDの取得

現在ログインしているユーザのUIDは以下のコマンドで取得可能です。

UIDの取得

```bash
id -u
```

余談ではありますがMacの場合、一般的なUNIX系環境でアカウント情報が載っている"/etc/passwd"には  
MacOSのユーザーアカウントの情報が載っていないので注意してください。  
MacOSのアカウント情報は内部的にはLDAPとパスワードサーバで管理されているようで、  
Open Directoryというディレクトリサービスを通じてアクセス・管理が行われているようです。

## コマンドの実行

上述の説明を踏まえ、以下がログアウトの実行コマンドとなります。

ログアウトコマンド

```bash
launchctl bootout user/$(id -u)
```

"id -u"により自身のUIDを指定しておりますが、  
ここで他のログインユーザのUIDを指定すれば、  
ログアウトさせることもできます。

鋭い方は「gui」ドメインでも実行できるのではと勘づかれているかもしれません。  
userドメインとguiドメインの違いはGUIログインの有無によるものですので、  
GUIログインしているユーザをログアウトさせる場合問題なくログアウトできます

guiドメインバージョン

```bash
launchctl bootout gui/$(id -u)
```

ただし、CLIログインしているユーザをguiドメイン指定でログアウトさせることはできません。  
CLIログインしているユーザ上でドメインをguiに指定してbootoutさせた結果が以下です。

CLiログインでbootout

```bash
launchctl bootout gui/$(id -u)
#実行結果
Domain does not support specified action
```

## 環境

OS:macOS 13.3(Ventura)  
シェル：zsh 5.9

## 終わりに

ログアウトなんてコマンド1つ打ってOKくらいのイメージでしたが、  
思ったより奥が深いですね。  
launchctlのドメインという概念もこの件で初めて知りましたし、  
MacOSのアカウント情報はOpenDirectoryというディレクトリサービスを通じて行われているというのも初めて知りました。

## 参考

Register as a new user and use Qiita more conveniently

1. You get articles that match your needs
2. You can efficiently read back useful information
3. You can use dark theme
[What you can do with signing up](https://help.qiita.com/ja/articles/qiita-login-user)

[Sign up](https://qiita.com/signup?callback_action=login_or_signup&redirect_to=%2FKit-i%2Fitems%2Fee32870a0b90cf196a87&realm=qiita) [Login](https://qiita.com/login?callback_action=login_or_signup&redirect_to=%2FKit-i%2Fitems%2Fee32870a0b90cf196a87&realm=qiita)

[1](https://qiita.com/Kit-i/items/ee32870a0b90cf196a87/likers)

4