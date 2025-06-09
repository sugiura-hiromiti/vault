---
title: threadと一貫性とAtomic
source: https://qiita.com/takaomag/items/cbf8301709024e6073fa
author:
  - "[[Qiita]]"
published: 2022-12-24
created: 2025-05-22
description: "Retail AI X AdventCalender2022への、23日目の寄稿です。前: 22日目: @takurUNさんのAPIゲートウェイ Kongを使って開発してる話。次: 24日目: …"
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
More than 1 year has passed since last update.

[Retail AI X AdventCalender2022](https://qiita.com/advent-calendar/2022/retail-ai-x) への、23日目の寄稿です。

前: 22日目: [@takurUN](https://qiita.com/takurUN "takurUN") さんの [APIゲートウェイ Kongを使って開発してる話。](https://qiita.com/takurUN/items/aace0e60744d0ec92cf6)  
次: 24日目: [@k-yoshigai](https://qiita.com/k-yoshigai "k-yoshigai") さんの [Go の Workspace を試す](https://qiita.com/k-yoshigai/items/cb094cf5ba0a26013f56)

## なにを書くか

こういう記事は書き慣れないし、まともな事を書こうとするとそれなりに時間かかるものなので、結構迷いました。  
結局、おぼろげながら覚えていて、しかももしかしたら使う場面がくるかもしれない、Atomic変数のことを書くことにしました。rustでのthreadとmemory modelについて書いていますが、C++などシステムプログラミングに使うような言語にも通ずる（というかrustのmemory modelはC++ベース）ものがあります。

## threadで競合を起こす

まずは以下のようなプログラムを用意します。rustで書いていますが、rust知らない人でも見た感じでだいたい解ると思います。

```rust
fn main() {
    // 引数1: スレッド数
    let thread_count: u8 = std::env::args().nth(1).unwrap().parse().unwrap();

    // 引数2: それぞれのスレッドでのカウント数
    let loop_count: u64 = std::env::args().nth(2).unwrap().parse().unwrap();

    println!("thread count = {thread_count}");
    println!("loop count = {loop_count}");
    println!(
        "result = {}",
        count_up_relaxed::count_up(thread_count, loop_count)
    );
}

pub fn count_up(thread_count: u8, loop_count: u64) -> u64 {
    let mut value: u64 = 0;
    let ptr = &mut value as *mut u64 as usize;

    // 指定された数のthreadを作って、それぞれが指定された回数分1を加算する。
    (0..thread_count)
        .map(|_| {
            std::thread::spawn(move || {
                (0..loop_count).for_each(|_| unsafe {
                    let value = ptr as *mut u64;
                    if cfg!(debug_assertion) {
                        // debug buildの場合
                        *value += 1;
                    } else {
                        // release buildの場合
                        *value = std::ptr::read_volatile(ptr as *const u64) + 1;
                    }
                })
            })
        })
        .collect::<Vec<_>>()
        .into_iter()
        .map(std::thread::JoinHandle::join)
        .for_each(Result::unwrap);
    value
}
```

### やっていること

1. 数字の変数を用意し、
2. 引数で指定された数のthreadsを作り、
3. それぞれのthread内で、引数で指定された回数分incrementする。

普通のrustでは、thread間で生pointerを共有することができないので、 `unsafe` ブロックを使ってpointer外しをやっています。rustでこういう生pointerを使うのは、ライブラリーとかじゃない限り頻繁にやることではないことに注意してください。

### 結果

`thread数` × `カウント数` が期待する値になりますが、

#### 1 threadの場合

- thread数 == 1
- count数 == 1000000
- 期待する結果 = 1000000
- 実際の結果 = 1000000

#### 8 threadの場合

- thread数 == 8
- count数 == 1000000
- 期待する結果 = 8000000
- 実際の結果 = 2266221（とか。実行するたびに変わる）

プログラム見ただけで結果は想像できると思いますが、2個以上のthread数で動かした場合、期待される数字よりも少ないです。値を読んでから+1した値を書き込むまでに、他のthreadがやっちゃうという、race conditionです。

ちょっと言い訳すると、release buildのときだけ `read_volatile` を使っています。これは、単純に `u64` のpointerに書き込むだけにしてrelease buildすると、コンパイル時に最適化が効いてしまって一瞬で正しい値を返してしまうからです。アセンブラで確認しようと思っても大量にでてくるし、ちゃんと読めるわけじゃないので自信ないですが。  
debug buildの場合は最適化が効かないので、思ったとおりに変な数字が出ます。

### race condition対策（Mutex）

脇道にそれますが、一番わかりやすい対策として、誰しも真っ先にMutexを使うことを思いつきます。  
加算している部分にロックをかけるとその部分は同時に1 threadしか動かないので期待した数字を得られます。楽ですね。

```rust
pub fn count_up(thread_count: u8, loop_count: u64) -> u64 {
    use std::sync::{Arc, Mutex};

    let value: Arc<Mutex<u64>> = Arc::new(Mutex::new(0));

    // 指定された数のthreadを作って、それぞれが指定された回数分1を加算する。
    (0..thread_count)
        .map(|_| {
            std::thread::spawn({
                let value = Arc::clone(&value);
                move || {
                    (0..loop_count).for_each(|_| {
                        let mut value = value.lock().unwrap();
                        *value += 1;
                    })
                }
            })
        })
        .collect::<Vec<_>>()
        .into_iter()
        .map(std::thread::JoinHandle::join)
        .for_each(Result::unwrap);
    Arc::try_unwrap(value).unwrap().into_inner().unwrap()
}
```

### race condition対策（Atomic変数）

Mutexはロックをかけますが、Atomic変数を使えばロックじゃなくてメモリーアクセスのレベルでいい感じにしてくれます。必要に応じて多くの人がやっていることだと思います。

```rust
pub fn count_up(thread_count: u8, loop_count: u64) -> u64 {
    use std::sync::{
        atomic::{AtomicU64, Ordering},
        Arc,
    };

    let value: Arc<AtomicU64> = Arc::new(AtomicU64::new(0));

    // 指定された数のthreadを作って、それぞれが指定された回数分1を加算する。
    (0..thread_count)
        .map(|_| {
            std::thread::spawn({
                let value = Arc::clone(&value);
                move || {
                    (0..loop_count).for_each(|_| {
                        value.fetch_add(1, Ordering::Relaxed);
                    })
                }
            })
        })
        .collect::<Vec<_>>()
        .into_iter()
        .map(std::thread::JoinHandle::join)
        .for_each(Result::unwrap);
    value.load(Ordering::Relaxed)
}
```

それぞれ速度を軽くrelase buildでbenchmarkすると以下のようになりました。

- 8 thread/1\_000\_000カウントしたときの結果（ [criterion](https://crates.io/crates/criterion) で計測）

| pointerに直接加算 | Mutex | Atomic変数 |
| --- | --- | --- |
| 6.0298 ms | 552.02 ms | 105.90 ms |

今回はthread内の処理がほぼそのままcritical sectionになるので、thead化している意味が全くなく、thread無しでやったほうが何桁も速いです（ベンチマークはやっていませんが）。  
まあ通常threadを利用する場合、thread内でいろいろ並列処理を行いつつ、その中でcritical sectionがあったりするので、今回はcritical sectionだけの極端な例です。

ここから得られる考察はたぶん、

- pointerに直接加算する方法  
	正確な数字が必要な場合は使えない。存在の確認などを高速に行うだけなら十分使えるような気もします。
- Mutexを使う方法  
	正確だけど遅い。
- Atomic変数を使う方法  
	正確だし速い。Atomic変数を使えるならば使ったほうがいい。

で、前ふりが長かったですが、ここからです。

## 複数threadでのメモリの値の見え方

こんな感じのプログラムを実行します。

```rust
fn main() {
    loop {
        let mut x = 0;
        let mut y = 0;
        let ptr_x = &mut x as *mut i32 as usize;
        let ptr_y = &mut y as *mut i32 as usize;

        let thread_0 = std::thread::spawn(move || unsafe {
            // ここでなにかの処理

            // store x
            *(ptr_x as *mut i32) = 1;
            // store y
            *(ptr_y as *mut i32) = 1;
        });

        let thread_1 = std::thread::spawn(move || unsafe {
            // ここでなにかの処理

            // load y
            let y = *(ptr_y as *const i32);
            // load x
            let x = *(ptr_x as *const i32);
            (x, y)
        });

        thread_0.join().unwrap();
        let (x, y) = thread_1.join().unwrap();

        if x == 0 && y == 1 {
            panic!("一貫性が無い");
        }
    }
}
```

### やっていること

1. `x`, `y` の2つの変数を用意する。
2. thread\_0が `x`,`y` の順で `1` をstoreする。
3. ほぼ同時に起動するthread\_1が `y`,`x` の順でloadする。

### 期待する結果

長い間interpreterな言語をやっていると、つい逐次実行される感覚が身についてしまって、以下のような結果を期待してしまいます。

| x | y | 想像される処理順 |
| --- | --- | --- |
| 0 | 0 | thread\_1: `y` をload（y == 0）   thread\_1: `x` をload（x == 0）   thread\_0: `x` にstore   thread\_0: `y` にstore |
| 1 | 1 | thread\_0: `x` にstore   thread\_0: `y` にstore   thread\_1: `y` をload（y == 1）   thread\_1: `x` をload（x == 1） |
| 1 | 0 | thread\_0: `x` にstore   thread\_1: `y` をload（y == 0）   thread\_0: `y` にstore   thread\_1: `x` をload（x == 1） |

### 実際に起こるもうひとつの結果

上記3つは当然発生しますが、それ以外にも `x == 0`, `y == 1` という結果が発生することがあります。上記のプログラムで `panic!`しているところです。  
（上記のままではまず発生しませんが、それぞれのthreadに他のコードとか入れるとたまに発生します）

thread\_1で `y` が `1` に見えているということは、thread\_0では既に `x` に `1` がstoreされているはずなのに `0` になります。変ですね。この際起こっていることは、以下のどちらかです。

- thread\_1から観て、thread\_0が、プログラマーが書いた順とは逆に、store y, store xの順で実行された（ように見えるように動いた）
- thread\_0から観て、thread\_1が、プログラマーが書いた順とは逆に、load x, load yの順で実行された（ように見えるように動いた）

これは、プログラムはプログラマーが書いた順に逐次実行されるとは限らず、実行時に順番が最適化されるために起こります。順番を何かしら制約する命令ではない場合、結果に影響のない範囲でCPUやコンパイラーは自由に命令を並べ替えることができるからです。

例えば、次の命令で使う値がCPUキャッシュに載っておらず、次の次の命令で使う値が既にCPUキャッシュに載っていたりすると、次の命令で使う値をloadしている間に、次の次の命令を先に実行したりするそうです。

普通のプログラムではうまくやってくるし、特にシングルスレッドではまったく気にする必要がないどころか高速化するのでありがたい機能ですが、マルチスレッドで危ないことをすると問題になるアレです。

上の例では2 threadでやっていますが、もう一つのthreadを用意したときに、thread\_1で観察された順番とは逆、つまりみんなそれぞれ見え方が異なる、ということも起こりえます。まったく一貫性がない状態です。

## 一貫性の種類

一貫性の話にこぎつけてタイトルの中の２番めの用語を回収します。  
Eventual Consistencyという言葉を聞いたことがあると思います。そのうち値が見えるようになるよという、速いらしいけど使うときにかなり頭を使わせるアレです。

昔、Cassandraがまだ出たての頃、値をGETしたら（Read Repairも効いておらず）何世代も前の値が返ってきたりして途方に暮れた経験がありますが（だいぶ前からそんな動きはしないようになった）、そういう動作でも準拠していると言えるところがEventual ConsistencyのEventual Consistencyたる所以です。厳密には殆どなにも保証も無いのと一緒です。

さて世の中にはEventual Consistency以外にも、一貫性の保証レベルはたくさんあるそうです。メジャーらしいやつをthreadとメモリの観点からいくつか挙げます。

### 1\. PRAM Consistency（FIFO Consistency）

- あるthreadがある場所にstore操作した結果は、他のthreadからも同じ順序で（一貫して）観測できる。
- 別のthreadから同じ場所に書き込まれた値は、他のthreadから異なる順序で観測されてもよい。

### 2\. Causal Consistency

- PRAM Consistencyのレベルと、
- 複数thread間での因果関係があるstoreの順序は、他のthreadからも同じ順で（一貫して）観測される。
- 複数thread間での因果関係が無いstoreの順序は、他のthreadから異なる順序で観測されてもよい。

因果関係というのは例えば、

- thread\_1が、変数aをstore
- thread\_2が、変数aをloadした結果から計算して変数bにstoreした

とき、変数aへのstoreと変数bへのstoreに因果関係がある、といいます。

### 3\. Sequential Consistency

- Causal Consistencyのレベルと、
- メモリ操作の順序は、どのthreadからも同じ順序で（一貫して）観測される。
- storeした値がloadで観測できるようになる時間は、thread間で異なってよい。
- 観測される値の変化の順序は、実時間におけるstoreの順序と一致しなくてもよい。

ちょっとわかりにくいですが、ここでいう順序はstore命令の順序ではなく、実際に書き込まれて読み取れるようになった順序で、どのthreadでも同じ順序という意味っぽいです。  
どんな書き込みも全てのスレッドで同じ順序で見えることが保証されるので、thread違いで矛盾が起こらないことがポイントです。

### 4\. linearization

- Sequential Consistencyのレベルと、
- 各read/writeがグローバル時刻で順序つけられている。

### 5\. Strict Consistency

- linearizationのレベルと、
- あるメモリ場所への任意のloadは、そこへの最も新しいstore結果になる。

これら以外にも、なんかたくさんの一貫性レベルがあるそうです。結構頭が混乱するし、そういう仕事していないとすぐ忘れるし、具体例書くのも時間かかるのでここでは省略します。検索してみてください。

## Atomic型

タイトルの中の用語の3番めの回収です。そろそろ終わりです。  
一貫性を頭に入れた上で、上の対策でも使ったAtomic型を整理します。Atomic型（変数）とは、

- 最新のstoreは、他のスレッドからそのうちloadできる。（可視性）
- 変数のstore中に、他のスレッドから中途半端な値がloadされることはない。（原子性）
- memory orderingにより一貫性が変わる。これは対象のAtomic変数だけでなく、その変数が関係する他の変数の可視性やAtomic性にも関わる。

rustでは、 `std::sync::atomic` に以下のようなAtomic型が用意されています。それぞれメモリ上ではAtomicではない素の型と同じバイナリ表現です。

- `AtomicBool` == `bool`
- `AtomicI8` == `i8`
- `AtomicI16` == `i16`
- `AtomicI32` == `i32`
- `AtomicI64` == `i64`
- `AtomicIsize` == `isize`
- `AtomicPtr` == `*mut T`
- `AtomicU8` == `u8`
- `AtomicU16` == `u16`
- `AtomicU32` == `u32`
- `AtomicU64` == `u64`
- `AtomicUsize` == `usize`

## Memory ordering（barrier）

Atomic型にはメソッドがいろいろあって、それぞれのメソッドは以下のような `Ordering` enumを引数にとり、そのOrdering次第で前後のメモリの読み書きの一貫性（順序）に影響を与えます。  
Memory orderingは、あくまで順序に関する保証であり、単純なcritical sectionを保証してくれるわけではないことに注意してください。

```rust#[derive(copy, clone, debug, eq, partialeq, hash)]
#[non_exhaustive]
pub enum Ordering {
    Relaxed,
    Release,
    Acquire,
    AcqRel,
    SeqCst,
}
```

Orderingの種類をそれぞれみていきます。

### Relaxed

- そのAtomic変数自体の原子性と可視性のみ保証。
- その他のメモリアクセスの順序に関しては何も保証しない。

Relaxedだけで済む場面も多いですが、注意すべきことはそのAtomic変数だけがAtomicであることだけしか保証されない点です。ロジック面で他の変数と絡めて使ってしまうと予想外の結果になります。ただし、順番が多少前後しても問題ない場合は、敢えて使ってもいいと思います。

### Release / Acquire

ReleaseとAcquireはセットで。store時にRelease、load時にAcquireを使います。  
loadでReleaseを使ったり、storeでAcquireを使うとpanicします。

効果としては、

- thread Aが、あるAtomic変数に対して値 `a` をRelease-storeし、
- thread Bが、同じAtomic変数に対してAcquire-loadして値 `a` を観察できた場合
- thread Bは、Acquire-load後、thread Aにおける（少なくとも）Release-store以前のwriteを観察できる。Release-store以降のwriteも観察されるかもしれない。
- thread Aは、Release-store前、thread Bにおける（少なくとも）Acquire-load以降のwriteを観察できない。Acquire-load以前のwriteは観察されるかもしれない。

感覚的に言うと、Atomic変数はキュー、その値は前後関係をはっきりさせてくれる手紙のようなものです。

1. thread Aでキュー（Atomic変数）に手紙（値）を流して（Release）、
2. 他のthreadがキュー（Atomic変数）からその手紙（値）を拾ったら（Acquire）、
3. 手紙をreleaseする前と、Acquireした後の前後関係が保証される。

例を書くとこんな感じです。

```rust
use std::sync::{
    atomic::{AtomicI32, Ordering},
    Arc,
};

fn main() {
    let ptr_x = &mut 0 as *mut i32 as usize;
    let atomic_val = Arc::new(AtomicI32::new(0));

    let thread_0 = std::thread::spawn({
        let atomic_x = Arc::clone(&atomic_val);
        move || {
            unsafe {
                // data = 1
                *(ptr_x as *mut i32) = 1;
            }
            // Release-store
            atomic_x.store(1, Ordering::Release);
        }
    });

    let thread_1 = std::thread::spawn({
        let atomic_x = Arc::clone(&atomic_val);
        move || loop {
            // busy loop開始
            if atomic_x.load(Ordering::Acquire) == 1 {
                // load-Acquire
                if unsafe { *(ptr_x as *const i32) != 1 } {
                    unreachable!("ここには到達しない。");
                };
                break;
            }
        }
    });

    thread_0.join().unwrap();
    thread_1.join().unwrap();
}
```

- thread\_0でRelease-storeしたAtomic変数値を、thread\_1が読み取れたということは、
- thread\_0でのRelease-store以前の書き込みが全て読み取れることが保証される。
- つまりthread\_1はptr\_xへの書き込みを読めることが保証されるので、ptr\_xは必ず `1` 。

### Consume

pointer計算した場合だけAcquireの動きをします。Acquireより高速らしくC++にはありますがrustのstdにはありませんし、rustで生pointerを使いすぎるとこれ大丈夫なのとか言われるし、ライブラリーとか使って実現するとしてもうっかり使い方間違えそうで怖いです。省略します。

### AcqRel

AcquireとRelease両方の性質を持ちます。loadの際にはAcquire、storeの際にはReleaseの効果が得られます。load/store両方を行うread-modify-write操作（compare\_and\_exchangeやfetch\_add）の際に使うものです。

compare\_and\_exchangeなど、失敗（writeする場合の条件に合致するか）する可能性があるread-modify-write操作には、success時のOrdering, 失敗したときのOrderingの引数がありますが、これはそれぞれ現在の値との比較が成功した場合のOrdering、失敗した場合のOrderingになります。

例を書くとこんな感じです。

```rust
use std::sync::atomic::{AtomicU8, Ordering};

fn main() {
    static COUNT: AtomicU8 = AtomicU8::new(0);
    let ptr_0 = &mut 0 as *mut i32 as usize;
    let ptr_1 = &mut 0 as *mut i32 as usize;

    let thread_0 = std::thread::spawn(move || {
        unsafe { *(ptr_0 as *mut i32) = 1 };
        if COUNT.fetch_add(1, Ordering::AcqRel) == 1 {
            println!("thread_0 wins.");
            assert_eq!(unsafe { *(ptr_1 as *const i32) }, 1);
        }
    });

    let thread_1 = std::thread::spawn(move || {
        unsafe { *(ptr_1 as *mut i32) = 1 };
        if COUNT.fetch_add(1, Ordering::AcqRel) == 1 {
            println!("thread_1 wins.");
            assert_eq!(unsafe { *(ptr_0 as *const i32) }, 1);
        }
    });

    thread_0.join().unwrap();
    thread_1.join().unwrap();
}
```

AcqRelによって、片方のthreadがAtomic変数に加えた変更を、もう片方のthreadが読み取れたときに、その変更を行ったthreadのそれより前の書き込みが全て読み取れます。  
つまり、どちらのthreadが後でも、相手がAtomic変数の変更前の値を読めることが保証されます。  
さらに、必ずどちらか一方だけが、 `if` 文の中の処理を行います。どっちも処理しないとか、どっちも処理するということは起こりません。

### SeqCst

AcqRelに加えて、複数のthreadsによる複数のAtomic変数の書き換えが、一貫した順序で観察されることを保証します。  
言い換えると、Release/Acquire（AcqRel）では、複数のthreadsが複数のAtomic変数を書き換える際に、thread間で異なった順序に見える可能性があります。つまり、Atomic変数1個しか使わない場合や、複数のAtomic変数を使用したとしてもお互いに関連が無い限り不要です。

迷ったらSeqCstを使え、とか書いてあったりしますが、これが必要ということは理解が難しい、かなり複雑なことをやっていることになります。気をつけましょう。

## fence

Atomic変数との組み合わせで使うfenceというものがあります。

Atomic変数でRelease,Acquire,AcqRel,SeqCstを指定した命令は、  
Atomi変数のrelaxedを指定した命令と、Release,Acquire,AcqRel,SeqCst fenceで置換できます。  
Atomic変数だけで実現できるのに、Atomic変数も必要なfenceの存在意義あるのかなぁ、と思っていましたが、今回改めて [コード例](https://doc.rust-lang.org/std/sync/atomic/fn.fence.html) を観てみると、relaxedのloopの後にfenceを置いていたりして、ちょっとだけ意味がわかりました。  
どうやら、前後の全てのアトミック操作の順序が保証されるみたいです。

## おまけ: threadのjoin()

rustのthreadの [join](https://doc.rust-lang.org/std/thread/struct.JoinHandle.html#method.join) メソッドの説明を見るわかりますが、以下のように書いてあるので、threadのjoin()前後の順序は保証されています。

> In terms of atomic memory orderings, the completion of the associated thread synchronizes with this function returning. In other words, all operations performed by that thread happen before all operations that happen after join returns.

## 最後に

Atomicを単純にAtomicとして使うことは頻繁にありますが、例えば普通のwebエンジニャーがOrderingやfenceを無理して使うことないと思うし、そもそも同じ事はMutexで実現できるし、一つの処理をMutex使ったコードより数ミリ秒単位で速くしたって、ユーザーどころか同じ会社の人でも気づきません。

さらに、書いた人がメンテナンスする分には問題無いですが、特にSeqCstのレベルが必要なコードを他の人がメンテナンスする場合、逆にバクを仕込んでしまったりもします。高速化が重要なライブラリーのgit観ていると、Orderingでよく議論になっていたりします。

使う人が使う理由は、上のカウンターの例と同じく単純に速いからです。ちょっと古いですが、 [ここのグラフの速度](http://ithare.com/infographics-operation-costs-in-cpu-clock-cycles/) でいうAtomic/CASのところの速度であり、Mutexやmessage queue/passingは [100倍レベルで遅くて](https://www.slideshare.net/mitsunorikomatsu/performance-comparison-of-mutex-rwlock-and-atomic-types-in-rust) このグラフには載っていません。

ライブラリーやゲームやデータ処理など、マイクロ秒やナノ秒の世界で生きている人たちは普通に使います。速さを競うライブラリーを普通のMutexで書いていると、他の人からAtomic/fenceに置き換えたpull requestが来たりもします。

goはよく知りませんが、ちょっと検索した限り

> Don't communicate by sharing memory, share memory by communicating.

という、昔からよく聞くOpinionatedな方針なので、ダイレクトな操作はしないっぽいです。すいません。

ということであまり使わないことを説明しましたが、人生意外と長いです。普通のwebエンジニャーでも、そのうち膨大な量の処理を金かけずに高速にしなければ、会社が潰れちゃうとか緩慢な死を迎える、という岐路に立つことがあります。

そういう困難な状況に直面した時でも、深呼吸した後、自信がないならMutexやReaderWriterLockで長ーいロックをかけて安全なコードを書いてください。たまに変に動くバグよりもましです。

Register as a new user and use Qiita more conveniently

1. You get articles that match your needs
2. You can efficiently read back useful information
3. You can use dark theme
[What you can do with signing up](https://help.qiita.com/ja/articles/qiita-login-user)

[Sign up](https://qiita.com/signup?callback_action=login_or_signup&redirect_to=%2Ftakaomag%2Fitems%2Fcbf8301709024e6073fa&realm=qiita) [Login](https://qiita.com/login?callback_action=login_or_signup&redirect_to=%2Ftakaomag%2Fitems%2Fcbf8301709024e6073fa&realm=qiita)

[17](https://qiita.com/takaomag/items/cbf8301709024e6073fa/likers)

0