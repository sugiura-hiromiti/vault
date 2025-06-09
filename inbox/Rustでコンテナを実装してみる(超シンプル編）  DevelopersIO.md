---
title: Rustでコンテナを実装してみる(超シンプル編） | DevelopersIO
source: https://dev.classmethod.jp/articles/rust-container-simple/
author:
  - "[[中村 修太]]"
published: 
created: 2025-05-22
description: 
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
## Introduction

[Docker](https://www.docker.com/) や [Finch](https://github.com/runfinch/finch) など、  
いまや当たり前となったコンテナ技術ですが、  
これは実行されるソフトウェアとそのOSの間で仮想化する、分離された実行環境です。

OS上のコンテナエンジンは個別に隔離&構成されたコンテナを作成し、  
そのコンテナ内でソフトウェアを実行します。  
もしそのコンテナがクラッシュしたりリソースを使い切ったとしても、  
システム全体とその他のコンテナで実行されているサービスには影響はありません。

本稿ではコンテナを作成するための基礎と、  
Rustで実際にコンテナを作成するためのCLIアプリを実装します。

## Environment

今回試した環境は以下のとおりです。

- MacBook Pro (13-inch, M1, 2020)
- OS: MacOS 12.4
- UTM: 4.1.5
- Rust: 1.67.0

※UTMからubuntu 23.04を起動して動作確認

## About Container

コンテナとは、サーバー内でアプリを実行して管理を効率よく行うための仮想化技術です。  
そのため、コンテナではアプリとその依存関係を1つにまとめて管理します。

コンテナはそれ以前の仮想化(VirtualBOXとかのホストOS型)と違い、  
共有のOSを使うので従来の仮想化よりもリソース使用量と  
オーバーヘッドが少なくてすみます。  
これにより、コンテナを使ったアプリ開発＆管理が一般的になりました。

## How to implement a Container?

Dockerは使用したことがあるのですが、  
「どうやって隔離された実行環境やネットワークを構築したり  
リソース制限をしているのか」  
ということはよく知りませんでした。

まずはコンテナがどういう仕組で動作しているのかを確認してみます。  
\*主にLinuxでのコンテナ型仮想化

コンテナを簡単にいうと、  
「独立した名前空間を持っている、他のプロセスと実行環境がわかれているプロセス」  
です。 コンテナは同じホストOSの中で動くプロセスとして存在します。  
ですが、通常のプロセスは各種リソース（ファイルやCPUなど）を他のプロセスと共有していて、  
互いに強く依存しています。

その状態で各プロセスを独立して動かすため、  
Linuxのnamespace機能を使います。  
この独立したプロセスがコンテナです。

![](https://devio2023-media.developers.io/wp-content/uploads/2023/06/linux-ns.png)

### namaspaceを使ってみる

Linuxのnamaspace(名前空間)は、 共有リソースを隔離して、  
個々のプロセスが独立した専用環境を持っているかのようにみせる仕組みです。

この機能を使えば、各プロセスは自分のnamespace内においてrootとして振る舞うことができ、  
そのnamespace内で独自のUserやGroupを構成することができます。

参考: [User namespaces and Linux Capabilties](https://litchipi.github.io/2022/01/06/container-in-rust-part6.html)

namespaceを作成する方法はいくつかありますが、  
ここでは [unshare(1)](https://linuxjm.osdn.jp/html/LDP_man-pages/man2/unshare.2.html) コマンドを使います。  
unshareコマンドは、プロセスの名前空間を隔離するめたのコマンドです。

試しにつかってみましょう。  
Linux(Ubuntu23)で動作確認してみます。

```
% ls -l /proc/$$/ns/pid
lrwxrwxrwx 1 myuser myuser 0 Feb 28 11:46 /proc/6208/ns/pid -> 'pid:[4026531836]'
```

新規PID　namespaceを作成して、bashを実行します。

```
% sudo unshare --fork --pid --mount-proc bash
```

forkとpidオプションを指定して、新しい名前空間でプロセスをフォークし、  
PID名前空間を作成します。  
これで新しい名前空間内のプロセスは元の名前空間とは違うPIDを持ちます。  
また、mount-procオプションを指定して  
新しい名前空間で/procをマウンするように指定しています。  
これしないとpsコマンドが動きません。

最後にbashを指定し、新しい名前空間作成後に  
新しいプロセスがフォークされて、その名前空間でbashシェルが実行されます。  
新しい名前空間内では、PIDやマウントポイントなどが  
元のシステムと隔離されています。

```
#現在のpid表示
root@mytest:/home/myuser# echo $$
1
```

作成したnamespaceではpidが1になっています。  
また、作成したnamespaceのプロセスはbashとpsだけです。

```
root@mytest:/home/myuser# ps -ax
    PID TTY      STAT   TIME COMMAND
      1 pts/0    S      0:00 bash
      9 pts/0    R+     0:00 ps -ax
```

この状態で、新しくコンソールを起動してプロセスツリーとpidをみてみます。  
ほかのプロセスと隔離されているのがわかります。

```
% pstree -p | grep unshare
           |-sshd(841)-+-sshd(1272)---sshd(1355)---bash(1356)---sudo(6111)---unshare(6112)---bash(6113)

% sudo ls -l /proc/6113/ns/pid
lrwxrwxrwx 1 root root 0 Feb 28 11:46 /proc/6113/ns/pid -> 'pid:[4026532336]'
```

こんな感じで名前空間を分離する処理をRustでやってみます。

## SetUp Rust Project

まずはCargoを使ってサンプルプログラムのセットアップをします。

```
% cargo new mini-container && cd mini-container
```

ちなみに、このままだとcargo build時に  
seccompがないとかなんとかでエラーがでるかもしれません。　  
その場合には下記コマンドでlibseccompパッケージをインストールしましょう。

```
#amazon linuxの場合
% sudo yum install libseccomp-devel

#ubuntuの場合
% sudo apt-get install -y libseccomp-dev
```

依存ライブラリに↓のものを追加します。

```
[dependencies]
nix = "0.26.1"
thiserror = "1.0.37"
log = "0.4.17"
simplelog = "0.12.0"
anyhow = "1.0.66"
libc = "0.2.139"
tokio = { version = "1.28.0", features = ["full"] }
```

ビルドしてエラーがでなければOKです。

```
% cargo build
・・・
```

## Implementing Rust Code

### nixを使って実装していく

Rustでunshareを実行するには、 [nix](https://crates.io/crates/nix) クレートを使います。  
nixはUnixでシステムプログラミングをするときによく使うcrateで、  
いろいろなシステムコールを呼び出すラッパーを提供しています。

実際の呼び出しは↓のようにします。  
簡単です。

```
use nix::sched::{unshare, CloneFlags};

・・・

unshare(CloneFlags::CLONE_NEWNS).expect("Failed to create a new namespace");
```

本稿ではunshareと [clone](https://docs.rs/nix/latest/nix/sched/fn.clone.html) を組み合わせて名前空間の分離を行い、  
コンテナ（っぽい）動作をさせてみます。

unshareとclone、どちらもnamespaceを制御するシステムコールであり、  
できることも多少かぶっているのですが、 unshareはnamespaceの制御、  
cloneはプロセス制御にそれぞれ特化しています。

また、unshareはさきほどのようにコマンドとシステムコールが  
それぞれ提供されてますが、  
cloneはシステムコールのみです。

```
% whatis unshare
unshare (1)          - run program in new namespaces
unshare (2)          - disassociate parts of the process execution context

% whatis clone
clone (2)            - create a child process
```

main.rsにコードを記述します。  
いろいろ雑だけど気にしない。  
※88行目で指定しているディレクトリは、適宜書き換えて作成しておいてください

```
use nix::mount::*;
use nix::sys::wait::waitpid;
use nix::sys::signal::{Signal, SIGCHLD};
use nix::unistd::{chroot, execvp};
use nix::sched::{clone,unshare, CloneFlags};
use std::env::{args, set_current_dir};
use std::ffi::CString;
use std::process::Command;
use anyhow::{self};
use log::{info, debug, error};
use simplelog::*;

//ログの初期化
fn init_log() {
    CombinedLogger::init(
        vec![
            TermLogger::new(LevelFilter::Debug, Config::default(), TerminalMode::Mixed, ColorChoice::Auto),
        ]
    ).unwrap();
}

//make-privateみたいなことをする
fn mount_private() -> anyhow::Result<(), nix::Error> {
    let result = mount(
        Some("none"),
        "/",
        None::<&str>,
        //MS_REC:指定したマウントポイント以下すべてにマウント操作が再帰的に適用
        //MS_PRIVATE:プライベートなマウント名前空間を作成
        MsFlags::MS_REC | MsFlags::MS_PRIVATE,
        None::<&str>,
    );
    info!("mount_private:result:{:?}",result);

    result
}

//mount --bind相当の処理
fn mount_bind(source: &str, target: &str) -> anyhow::Result<(), nix::Error> {
    let result = mount(
        Some(source),
        target,
        None::<&str>,
        //指定したファイルまたはディレクトリを別の場所にbind mount
        MsFlags::MS_BIND,
        None::<&str>,
    );

    info!("mount_bind:result:{:?}",result);

    result
}

//procをマウント
fn mount_proc(source: &str, target: &str) -> anyhow::Result<(), nix::Error> {
    let result = mount(
        Some(source),
        target,
        Some("proc"),
        MsFlags::empty(),
        None::<&str>,
    );
    info!("mount_proc:result:{:?}",result);

    result
}

//初期化処理
fn container_init(container_rootdir: &str) -> anyhow::Result<(), Box<dyn std::error::Error>> {
    mount_private()?;
    //chrootのroot filesystem作成
    mount_bind("/", container_rootdir)?;
    //指定したディレクトリを新しいrootディレクトリとして設定
    chroot(container_rootdir)?;
    //プロセスのカレントディレクトリを指定したディレクトリに変更
    set_current_dir("/")?;
　　　　　　　//procをマウント
    mount_proc("proc", "/proc")?;
    Ok(())
}

fn main() -> anyhow::Result<(), Box<dyn std::error::Error>> {

    init_log();

    debug!("mini container start.");

    let root = "/path/your/new_root_tmp_dir";

    unshare(CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWUTS).expect("Failed to create a new namespace");

    let closure = || {

        if let Err(e) = container_init(&root) {
            eprintln!("init container failed: {:?}", e);
            return 256;
        }

        let cmd = CString::new("bash").unwrap();
        let args = vec![
            CString::new("containered bash").unwrap(),
        ];
        if let Err(e) = execvp(&cmd, &args.as_ref()) {
            error!("Error -> {}", e);
            return 256;
        }
        256
    };

    let cb = Box::new(closure);
    let mut child_stack = [0u8; 8192];
    let flags = CloneFlags::CLONE_NEWIPC | CloneFlags::CLONE_NEWPID;

    let sigchld: libc::c_int = SIGCHLD as libc::c_int;
    let _pid = clone(cb, &mut child_stack, flags, Some(sigchld))?;

    info!("PID : {:?}", _pid);

    while let Ok(status) = waitpid(None, None) {
        info!("Exit Status: {:?}", status);
    }

    Ok(())
}
```

ビルドして実行すると↓のような感じでシェルが起動します。  
ここではプロセスIDが86519で起動したことがわかります。

```
% cargo build
% sudo target/debug/mini-container
08:45:58 [DEBUG] (1) mini: mini container start.
08:45:58 [INFO] PID : Pid(86519)
08:45:58 [INFO] mount_private:result:Ok(())
08:45:58 [INFO] mount_bind:result:Ok(())
08:45:58 [INFO] mount_bind:result:Ok(())
08:45:58 [INFO] mount_proc:result:Ok(())
root@myuser:/#
```

psでみると２つしかプロセスがありません。  
また、別コンソールを起動してpsでみると、86519のプロセスが見えます。

```
root@myuser:/# ps -ax
    PID TTY      STAT   TIME COMMAND
      1 ?        S      0:00 containered bash
      7 ?        R+     0:00 ps -ax
```

namespaceが分離されてるか確認します。  
unshare時にCLONE\_NEWUTSを指定したので、hostnameも分離されているはずです。  
ためしに、新しいnamespaceでhostnameを変更してみます。

```
root@myuser:/# hostname hoge
root@myuser:/# hostname
hoge
```

別コンソールでhostnameを確認しても、変わっていません。

```
$ hostname
myhost
```

さらに、mountの状態も分離されており、元システムに影響はありません。  
今回はやってませんが、ファイルシステムやネットワークも分離することができます。

## Summary

今回はnixクレートを使ってnamespaceの動作を試してみました。  
ここではシンプルに実装しましたが、  
これをベースにリソース制限や仮想ネットワーク設定も可能です。

## References

- [Writing a container in Rust](https://litchipi.github.io/series/container_in_rust)
- [Linux containers in 500 lines of code　×](https://blog.lizzie.io/linux-containers-in-500-loc.html) \* [namespaces - Linux 名前空間の概要](https://linuxjm.osdn.jp/html/LDP_man-pages/man7/namespaces.7.html)
- [user\_namespaces - Linux ユーザー名前空間の概要](https://linuxjm.osdn.jp/html/LDP_man-pages/man7/user_namespaces.7.html)
- [Rustでsocketpairを使ってIPCしようとしてみたが...](https://udzura.hatenablog.jp/entry/2021/03/25/231833)
- [unshareコマンドでLinuxのNamespaceに入門](https://ozashu.hatenablog.com/entry/2019/03/22/144143)
- [Linux user namespaces might not be secure enough? a.k.a. subverting POSIX capabilities](https://medium.com/@ewindisch/linux-user-namespaces-might-not-be-secure-enough-a-k-a-subverting-posix-capabilities-f1c4ae19cad)
- [コンテナ型仮想化技術の仕組み](https://qiita.com/Ewokkkkk/items/990cabfc696bd54a5140)
- [Linux cgroup v2で実メモリ占有量を制限する](https://qiita.com/kakinaguru_zo/items/cb18bd8f7aa92c11f6bf)
- [What is a Container?](https://ayushblog.medium.com/what-is-a-container-595d258af6ed)
- [network namespaceとは](https://zenn.dev/takai404/articles/52e75a953efe9e)
- [crate.io rtnetlink](https://crates.io/crates/rtnetlink)
- [Github rtnetlink](https://github.com/rust-netlink/rtnetlink)
- [Rustでもunshare（というか、Linux Namespaceの分離）したい！](https://udzura.hatenablog.jp/entry/2021/03/26/185057)
- [Dockerとネットワークネームスペースの関係](https://qiita.com/sugimount/items/5c92c4976f9949650403)
- [Docker の仕組み 〜 コンテナを 60 行で実装する](https://qiita.com/PND/items/d2dfb0ef0568a6e81b3e)
- [unshareコマンドでLinuxのNamespaceに入門](https://ozashu.hatenablog.com/entry/2019/03/22/144143)
- [LinuxのNetns/veth/Bridge/NATで仮想ネットワーク構築](https://blog.kamijin-fanta.info/2018/12/netns/)
- [秒速でネットワーク作成 \[veth peer\]](https://blog.serverworks.co.jp/tech/2019/08/05/post-70460/)
- [Linuxカーネルのコンテナ機能［5］ ─ネットワーク](https://gihyo.jp/admin/serial/01/linux_containers/0006)
- [コンテナ技術の基礎（1）「カーネルの分離 namespace」](https://news.mynavi.jp/techplus/article/k8ssecurity-3/4)
- [crateio:rtnetlink](https://crates.io/crates/rtnetlink)
- [Github:rtnetlink](https://github.com/rust-netlink/rtnetlink)