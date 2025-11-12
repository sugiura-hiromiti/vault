---
title: "RustのPinチョットワカル"
source: "https://tech-blog.optim.co.jp/entry/2020/03/05/160000"
author:
  - "[[optim-hiro-saito]]"
published: 2020-03-05
created: 2025-11-12
description: "Rustの分かりにくくて奥の深いPinについて解説します。"
tags:
  - "clippings"
status: "unread"
aliases:
---
こんにちは。 先日、しばらく不動の一位を守ってきた [RustをVSCodeで使う記事](https://tech-blog.optim.co.jp/entry/2019/07/18/173000) を抜き、 私の書いた [非同期プログラミングの記事](https://tech-blog.optim.co.jp/entry/2019/11/08/163000) の記事が一番人気になったと思いきや数日でまた抜き返されて傷心中の、 R&Dチームの齋藤（ [@aznhe21](https://twitter.com/aznhe21) ）です。

さて、Rustの非同期プログラミングで時々 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を使ったり、コンパイラに [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) が不足していると怒られたりしませんか？ そんな時によく分からずuseしたり別の手段を取ったりしていませんか？ 今回、このままではマズいと思って [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を勉強して完全に理解しましたので、その成果を皆さんと共有したいと思います。

## 更新履歴

- 03/10
	- [指摘](https://twitter.com/__pandaman64__/status/1235477608856342528) を受け下記2点を修正しました
		- [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない型もムーブ出来ることへの言及
		- [pin-projectクレート](https://github.com/taiki-e/pin-project) が安全であることによる書き換え

## 対象読者

この記事は下記全てに当てはまる人を想定して執筆しています。

- Rustのトレイトを使える
- [`std::pin::Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を詳しく知りたい
- 変数がムーブしたとき、その変数のアドレスが変わることを理解している
- スタックやヒープが何であるかを知っている

## つまり・・・どういうことだってばよ（TL;DR）

- [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) 型の変数は、それ自体をムーブしても内部に保持するポインタのアドレス\\は変わらない
- この性質を利用すれば自己参照構造体を安全に取り扱うことが出来る
- 値の変更は内部フィールドのアドレスが変わる可能性があるため、 [`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) から可変参照を得るためには `P` が、 「変更しても安全」であることを示す [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトを満たす必要がある

[![スPinスPinスPin](https://cdn-ak.f.st-hatena.com/images/fotolife/o/optim-tech/20200302/20200302143858.png "スPinスPinスPin")](https://www.google.com/search?q=%E5%9C%B0%E7%90%83%E5%84%80+%E3%82%B9pin)

## Pinを使うその前に

まずはよく一緒に使われる非同期プログラミングとは切り離し、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) と [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) がどういった部分で必要になるかを説明しましょう。

### なぜPinが必要になるのか

まず、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の仕組みは値をムーブ **させたくない** ときに必要になるものです 「値をムーブさせたくないとき」というのは、主に自己参照構造体を使うときのことを言います。

```rust
struct SelfRef {
    x: u32,
    // ptrは常にxを指していて欲しいが、SelfRefがムーブした瞬間に別のアドレスを指すようになる
    ptr: *const u32,
}

impl SelfRef {
    pub fn new(x: u32) -> SelfRef {
        let mut this = SelfRef {
            x,
            ptr: std::ptr::null(),
        };
        this.ptr = &this.x;

        // まだアドレスは変わらないのでテストは成功する
        assert_eq!(&this.x as *const _, this.ptr);

        // ここで値を返した瞬間にxのアドレスが変わり、ptrの値が不正となる
        this
    }
}

fn main() {
    let v = SelfRef::new(0);

    // v.xとv.ptrの値が異なるためテスト失敗
    assert_eq!(&v.x as *const _, v.ptr);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=struct%20SelfRef%20%7B%0A%20%20%20%20x%3A%20u32%2C%0A%20%20%20%20%2F%2F%20ptr%E3%81%AF%E5%B8%B8%E3%81%ABx%E3%82%92%E6%8C%87%E3%81%97%E3%81%A6%E3%81%84%E3%81%A6%E6%AC%B2%E3%81%97%E3%81%84%E3%81%8C%E3%80%81SelfRef%E3%81%8C%E3%83%A0%E3%83%BC%E3%83%96%E3%81%97%E3%81%9F%E7%9E%AC%E9%96%93%E3%81%AB%E5%88%A5%E3%81%AE%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%82%92%E6%8C%87%E3%81%99%E3%82%88%E3%81%86%E3%81%AB%E3%81%AA%E3%82%8B%0A%20%20%20%20ptr%3A%20*const%20u32%2C%0A%7D%0A%0Aimpl%20SelfRef%20%7B%0A%20%20%20%20pub%20fn%20new\(x%3A%20u32\)%20-%3E%20SelfRef%20%7B%0A%20%20%20%20%20%20%20%20let%20mut%20this%20%3D%20SelfRef%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20x%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20ptr%3A%20std%3A%3Aptr%3A%3Anull\(\)%2C%0A%20%20%20%20%20%20%20%20%7D%3B%0A%20%20%20%20%20%20%20%20this.ptr%20%3D%20%26this.x%3B%0A%0A%20%20%20%20%20%20%20%20%2F%2F%20%E3%81%BE%E3%81%A0%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%81%AF%E5%A4%89%E3%82%8F%E3%82%89%E3%81%AA%E3%81%84%E3%81%AE%E3%81%A7%E3%83%86%E3%82%B9%E3%83%88%E3%81%AF%E6%88%90%E5%8A%9F%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20assert_eq!\(%26this.x%20as%20*const%20_%2C%20this.ptr\)%3B%0A%0A%20%20%20%20%20%20%20%20%2F%2F%20%E3%81%93%E3%81%93%E3%81%A7%E5%80%A4%E3%82%92%E8%BF%94%E3%81%97%E3%81%9F%E7%9E%AC%E9%96%93%E3%81%ABx%E3%81%AE%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%81%8C%E5%A4%89%E3%82%8F%E3%82%8A%E3%80%81ptr%E3%81%AE%E5%80%A4%E3%81%8C%E4%B8%8D%E6%AD%A3%E3%81%A8%E3%81%AA%E3%82%8B%0A%20%20%20%20%20%20%20%20this%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20v%20%3D%20SelfRef%3A%3Anew\(0\)%3B%0A%0A%20%20%20%20%2F%2F%20v.x%E3%81%A8v.ptr%E3%81%AE%E5%80%A4%E3%81%8C%E7%95%B0%E3%81%AA%E3%82%8B%E3%81%9F%E3%82%81%E3%83%86%E3%82%B9%E3%83%88%E5%A4%B1%E6%95%97%0A%20%20%20%20assert_eq!\(%26v.x%20as%20*const%20_%2C%20v.ptr\)%3B%0A%7D%0A)

このとき、 `SelfRef` の `ptr` は常に `x` へのアドレスを保持していて欲しいわけですが、 コンストラクタから値を返した時点で変数のアドレスが変わってしまうためこのコードはうまく動きません。

このような「 **ムーブしたら絶対アカン😡** 型」をうまく使うために、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) と [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) という仕組みが用意されています。

### ムーブしてもおけまる🙆な型のためのUnpinトレイト

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) について説明する前に、まず理解しなければならないのが [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトです。 この [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトは「ムーブしてもおけまる🙆な型」に実装されます。

```rust
// Unpinの定義はこれっぽっち
pub auto trait Unpin {}
```

この [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトは自動トレイト [\*1](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-12cef594 "現在はNightly限定の機能です") として宣言されており、基本的には **あらゆる型に実装されます** 。 それもそのはず、普通にコードを書いていて「ムーブしたら絶対アカン😡型」なんてものは出てこないからです。

そのため、先述した `SelfRef` といった稀有な「ムーブしたら絶対アカン😡型」には自分で「ムーブしたら絶対アカン😡型マーク」を付ける必要があります。 これには [`std::marker::PhantomPinned`](https://doc.rust-lang.org/std/marker/struct.PhantomPinned.html) を使います。

```rust
use std::marker::PhantomPinned;

struct SelfRef {
    x: u32,
    ptr: *const u32,
    _pinned: PhantomPinned,
}
```

[`PhantomPinned`](https://doc.rust-lang.org/std/marker/struct.PhantomPinned.html) は [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を **実装しない** 型です。 そして、自動トレイトの機能によって「 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない型を含む型」もまた「 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない型」となります。 これによって `SelfRef` は「ムーブしてもおけまる🙆な型」 **ではなく** 「ムーブしたら絶対アカン😡型」を **自称** することが出来るようになりました。

ここで「自称」と書いたのには意味があります。 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトを付けないようにしたとしても、コンパイラが特別扱いしてくれるわけではないのです。 つまり、 `SelfRef` を「ムーブしたら絶対アカン😡型」といくら「自称」したところで、いくらでもムーブが出来てしまうのです。

```rust
use std::marker::PhantomPinned;

struct Obj {
    _pinned: PhantomPinned,
}

fn move_obj(_obj: Obj) {
    println!("objがムーブされた");
}

fn main() {
    let obj = Obj { _pinned: PhantomPinned };
    move_obj(obj);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0A%0Astruct%20Obj%20%7B%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Afn%20move_obj\(_obj%3A%20Obj\)%20%7B%0A%20%20%20%20println!\(%22obj%E3%81%8C%E3%83%A0%E3%83%BC%E3%83%96%E3%81%95%E3%82%8C%E3%81%9F%22\)%3B%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20obj%20%3D%20Obj%20%7B%20_pinned%3A%20PhantomPinned%20%7D%3B%0A%20%20%20%20move_obj\(obj\)%3B%0A%7D%0A)

では「ムーブしたら絶対アカン😡型」をムーブさせないようにするためにはどうしたら良いのでしょう。

### オブジェクトがムーブしないのはどういうときか

そもそも「オブジェクトがムーブしない」というのは一体どんなときでしょうか？

答えは2つあります。 1つは「スタックから移動しない変数」で、もう1つは「ヒープに確保された変数」です。

#### スタックから移動しない変数

いつものように変数を定義するとスタックにその領域が確保されるわけですが、 スタックに確保された変数が別の場所に移動することは `SelfRef` の例で述べた通りです。

しかし、スタックに確保された変数を移動できないようにする方法があります。 コードを見てみましょう。

```rust
// (1) 変数xを定義
let mut x = Object::new();
// (2) xへの参照をxとして定義
let mut x = &mut x;
```

(1)で `x` を普通の変数として定義しています。これは何の変哲もない定義です。 ここのミソは(2)にあり、(1)で定義した名前と同じ `x` という名前で、(1)の `x` への参照を定義しています。 これにより、(1)で定義した `x` にアクセスは出来なくなり、「別の場所に移動しない変数」となったわけです。 すなわち、もはや(1)の `x` のアドレスは変わることがないのです。

このようにして `Object` インスタンスへのアドレスが変わらないように、つまり「オブジェクトがムーブしない」ようになるのです。

#### ヒープに確保された変数

スタックではなくヒープに確保された変数もまた、ムーブしない変数です。

```rust
// 変数をヒープに確保
let x = Box::new(Object::new());
```

このようにして `Object` インスタンスをヒープに確保すれば `Object` インスタンそのアドレスが変わらないように、 つまり「オブジェクトがムーブしない」ようになります。

#### と思うじゃん？

ここまで述べてきてちゃぶ台をひっくり返す(ノ｀Д´)ノ彡┻━┻ようですが、実はムーブしないオブジェクトをムーブさせる抜け道があります。 その抜け道とは [`std::mem::replace`](https://doc.rust-lang.org/std/mem/fn.replace.html) や [`std::mem::swap`](https://doc.rust-lang.org/std/mem/fn.swap.html) などの `&mut T` を受け取り、内部を丸ごと書き換える関数です。

これらの関数を使うと変数の中身をそのまま取り出すことが出来ます。 つまりインスタンスをそのままに「オブジェクトが **ムーブする** 」ことになってしまうのです。

そのコードを実際に見てみましょう。

```rust
// xの中身はもちろんx
let mut x = Object::new();
// 変数xを隠蔽することによってムーブを防ぐ
let mut x = &mut x;
// 隠蔽したxの「中身」を取り出す
let y = std::mem::replace(x, Object::new());
// xの中身がyにムーブしてしまった
```
```rust
// Objectをヒープに確保することによってムーブを防ぐ
let mut x = Box::new(Object::new());
// ヒープにあるObjectをスタックに引っ張り出す
let y = std::mem::replace(&mut *x, Object::new());
// xの中身がyにムーブしてしまった
```

このコードにより、一度は隠蔽した `x` の中身やヒープに確保した `x` が `y` にムーブされてしまいます。 これは由々しき事態です。

### Pinがムーブを阻止する

可変参照を使いつつも値のムーブを防ぐための仕組みが [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) です。 では、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) はどのようにしてムーブさせない仕組みを提供しているのでしょうか。

まずは [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の定義を見てみます。関数定義を除けばこのようになっています。

```rust
pub struct Pin<P> { /* fields omitted */ }

impl<P: Deref> Pin<P> where P::Target: Unpin {
    // ...
}

impl<P: Deref> Pin<P> {
    // ...
}

impl<P: DerefMut> Pin<P> {
    // ...
}

impl<'a, T: ?Sized> Pin<&'a T> {
    // ...
}

impl<'a, T: ?Sized> Pin<&'a mut T> {
    // ...
}
```

型 `P` はポインタ（Pointer）のPを表しており、実質的に **`P` には [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を実装したポインタ型のみが入る** 制限があります。 より詳しく言うと、実装から型 `P` には [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) か [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) 、あるいは `&T` 、 `&mut T` が来ることが分かります。 [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) は [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を要求し、また `&T` や `&mut T` はそれぞれ [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) と [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) を満たすため、 実質的に **[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を要求している** のです

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を要求するということは、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は逆参照の出来る型、つまり `&T` や `Box<T>` などを要求します。 そして、これらの型を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) で包むと、 **[`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない「ムーブしたら絶対アカン😡型」での [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) の使用を制限** します。 [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) が使えないということは [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を通して変数を可変参照として扱えないということです。 変数を可変参照で扱えると、 [以前の章](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E3%81%A8%E6%80%9D%E3%81%86%E3%81%98%E3%82%83%E3%82%93) で説明した通り [`std::mem::replace`](https://doc.rust-lang.org/std/mem/fn.replace.html) などによって変数の中身を取り出すことが出来ます。 逆に言えば **可変参照として扱えないのなら変数のムーブを防ぐことが出来る** のです。 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) の使用を制限しますから、翻って **[`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) の使えない [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は変数のムーブを防ぐことが出来る** というわけです。

ここで [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) と [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) の実装を見てみましょう [\*2](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-e8111409 "Nightly限定の機能を避けるために少し修正しています") 。 これを見ると [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) は「ムーブしてもおけまる🙆な型」（ [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装した型）でのみ提供され、 「ムーブしたら絶対アカン😡型」には提供されないことが分かります。

```rust
// Derefはどんな型にも提供する
impl<P: Deref> Deref for Pin<P> {
    type Target = P::Target;
    fn deref(&self) -> &P::Target { /* implementation omitted */ }
}

// 「ムーブしてもおけまる🙆な型」にのみDerefMutを提供する
impl<P: DerefMut> DerefMut for Pin<P> where P::Target: Unpin {
    fn deref_mut(&mut self) -> &mut P::Target { /* implementation omitted */ }
}
```

ただし [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) が提供されないということはその中身を変更することが出来ないということでもあります。 もちろんその手段は用意されていますので [後程](https://tech-blog.optim.co.jp/entry/2020/03/05/#Pin%E3%81%AE%E4%B8%AD%E8%BA%AB%E3%82%92%E5%A4%89%E6%9B%B4%E3%81%99%E3%82%8B) ご紹介します。

## Pinの使い方

ここまでで [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の必要性が分かりました。それでは [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を実際に使っていきましょう。

### Pinの作り方

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) にはコンストラクタが2つあります。しかし、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の生成には **どちらも使いません** 。 その理由を説明するために、まずはその2つのコンストラクタを紹介しましょう [\*3](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-a48157ea "Nightly限定の機能を避けるために少し修正しています") 。

```rust
impl<P: Deref> Pin<P> where P::Target: Unpin {
    pub fn new(pointer: P) -> Pin<P> { /* implementation omitted */ }
}

impl<P: Deref> Pin<P> {
    pub unsafe fn new_unchecked(pointer: P) -> Pin<P> { /* implementation omitted */ }
}
```

[`Pin::<P>::new`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.new) は `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) であり、かつ [`Deref::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装する場合のみ使うことができるもので、 逆に [`Pin::<P>::new_unchecked`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.new_unchecked) は不安全ですが使用に制限がないものです。

つまり、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は「ムーブしたら絶対アカン😡型」をムーブさせないためのものなのに、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を作るためには「ムーブしてもおけまる🙆な型」であることが要求されるのです。 となると、「ムーブしたら絶対アカン😡型」を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) で扱うためには **不安全な方のコンストラクタを使うことになる** わけです。

では [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を作るには不安全なコードを書かなければならないのでしょうか？ いいえ、安心してください。不安全なコンストラクタは不安全なコードのためのものであり、 安全なコードを書く上では別の機能が用意されています。つまり、 **[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の2つのコンストラクタはどちらも使わない** のです。

### 安全Pin

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を安全なコードから生成するための仕組みはいくつか用意されています。

これらの仕組みは全てスタックかヒープに変数を固定し、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に **ピン留め** する機能を持っています。 ここでは変数をメモリに固定した上で [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包むことを「スタックでピン留め」あるいは「ヒープでピン留め」と呼んでいます。

#### pin\_utils::pin\_mut!マクロ

[pin-utilsクレート](https://github.com/rust-lang-nursery/pin-utils) の [`pin_mut!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.pin_mut.html)マクロは [「スタックから移動しない変数」](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%8B%E3%82%89%E7%A7%BB%E5%8B%95%E3%81%97%E3%81%AA%E3%81%84%E5%A4%89%E6%95%B0) で紹介したコードに相当する内容を安全に実現します。

このマクロは以下のように使います。

```rust
use std::marker::PhantomPinned;
use std::pin::Pin;
use pin_utils::pin_mut;

// Unpinを実装しない型
struct NotUnpin {
    _pinned: PhantomPinned,
}

impl NotUnpin {
    // NotUnpinのインスタンスを生成する
    pub fn new() -> NotUnpin {
        NotUnpin {
            _pinned: PhantomPinned,
        }
    }

    // Pin<&mut Self>をselfとして受け取る
    pub fn method(self: Pin<&mut Self>) {
        println!("やあやあ我こそはPinなり！");
    }
}

// 値がPinで包まれているかをコンパイル時に確認するためのダミー関数
fn assert_pin<T>(_: &Pin<&mut T>) {}

fn main() {
    let obj = NotUnpin::new();

    // objはUnpinを実装していないためPin::newを使えない
    // let obj = Pin::new(obj);

    // pin_mutによってスタックでピン留めする
    pin_mut!(obj);

    // objはPin<&mut NotUnpin>である
    assert_pin::<NotUnpin>(&obj);

    // Pinになったのでメソッドを呼び出せる
    // obj.method()でも呼び出せるがobjを消費してしまって2度目以降の呼び出しが出来なくなるためas_mut()を通して呼び出す
    obj.as_mut().method();
    obj.as_mut().method();
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0Ause%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_utils%3A%3Apin_mut%3B%0A%0A%2F%2F%20Unpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%AA%E3%81%84%E5%9E%8B%0Astruct%20NotUnpin%20%7B%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Aimpl%20NotUnpin%20%7B%0A%20%20%20%20%2F%2F%20NotUnpin%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E7%94%9F%E6%88%90%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20new\(\)%20-%3E%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20Pin%3C%26mut%20Self%3E%E3%82%92self%E3%81%A8%E3%81%97%E3%81%A6%E5%8F%97%E3%81%91%E5%8F%96%E3%82%8B%0A%20%20%20%20pub%20fn%20method\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%82%84%E3%81%82%E3%82%84%E3%81%82%E6%88%91%E3%81%93%E3%81%9D%E3%81%AFPin%E3%81%AA%E3%82%8A%EF%BC%81%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20%E5%80%A4%E3%81%8CPin%E3%81%A7%E5%8C%85%E3%81%BE%E3%82%8C%E3%81%A6%E3%81%84%E3%82%8B%E3%81%8B%E3%82%92%E3%82%B3%E3%83%B3%E3%83%91%E3%82%A4%E3%83%AB%E6%99%82%E3%81%AB%E7%A2%BA%E8%AA%8D%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AE%E3%83%80%E3%83%9F%E3%83%BC%E9%96%A2%E6%95%B0%0Afn%20assert_pin%3CT%3E\(_%3A%20%26Pin%3C%26mut%20T%3E\)%20%7B%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%0A%20%20%20%20%2F%2F%20obj%E3%81%AFUnpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%A6%E3%81%84%E3%81%AA%E3%81%84%E3%81%9F%E3%82%81Pin%3A%3Anew%E3%82%92%E4%BD%BF%E3%81%88%E3%81%AA%E3%81%84%0A%20%20%20%20%2F%2F%20let%20obj%20%3D%20Pin%3A%3Anew\(obj\)%3B%0A%0A%20%20%20%20%2F%2F%20pin_mut%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%A7%E3%83%94%E3%83%B3%E7%95%99%E3%82%81%E3%81%99%E3%82%8B%0A%20%20%20%20pin_mut!\(obj\)%3B%0A%0A%20%20%20%20%2F%2F%20obj%E3%81%AFPin%3C%26mut%20NotUnpin%3E%E3%81%A7%E3%81%82%E3%82%8B%0A%20%20%20%20assert_pin%3A%3A%3CNotUnpin%3E\(%26obj\)%3B%0A%0A%20%20%20%20%2F%2F%20Pin%E3%81%AB%E3%81%AA%E3%81%A3%E3%81%9F%E3%81%AE%E3%81%A7%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%82%92%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%9B%E3%82%8B%0A%20%20%20%20%2F%2F%20obj.method\(\)%E3%81%A7%E3%82%82%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%9B%E3%82%8B%E3%81%8Cobj%E3%82%92%E6%B6%88%E8%B2%BB%E3%81%97%E3%81%A6%E3%81%97%E3%81%BE%E3%81%A3%E3%81%A62%E5%BA%A6%E7%9B%AE%E4%BB%A5%E9%99%8D%E3%81%AE%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97%E3%81%8C%E5%87%BA%E6%9D%A5%E3%81%AA%E3%81%8F%E3%81%AA%E3%82%8B%E3%81%9F%E3%82%81as_mut\(\)%E3%82%92%E9%80%9A%E3%81%97%E3%81%A6%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%99%0A%20%20%20%20obj.as_mut\(\).method\(\)%3B%0A%20%20%20%20obj.as_mut\(\).method\(\)%3B%0A%7D%0A)

このマクロによって安全に、変数 `obj` をスタックに固定しつつ `Pin` に包み、ピン留めすることが出来ます。

#### tokio::pin!マクロ

[pin\_utils::pin\_mut!マクロ](https://tech-blog.optim.co.jp/entry/2020/03/05/#pin_utilspin_mut%E3%83%9E%E3%82%AF%E3%83%AD) と同様の機能が [tokioクレート](https://github.com/tokio-rs/tokio) にも用意されています。 このマクロは [`pin_mut!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.pin_mut.html)のような定義済みの変数を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包む機能に加え、 変数をその場で [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んで定義する機能もあります [\*4](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-c76cc5c7 "tokio v0.2.13からの機能です") 。 ただし、このためだけのtokioを使うのは流石にクレートとしての規模が大きすぎるので、 tokioを使っているならpin-utilsの代わりに使う、程度の感覚で良いでしょう。

```rust
use std::marker::PhantomPinned;
use std::pin::Pin;
use tokio::pin;

// Unpinを実装しない型
struct NotUnpin {
    _pinned: PhantomPinned,
}

impl NotUnpin {
    // NotUnpinのインスタンスを生成する
    pub fn new() -> NotUnpin {
        NotUnpin {
            _pinned: PhantomPinned,
        }
    }

    // Pin<&mut Self>をselfとして受け取る
    pub fn method(self: Pin<&mut Self>) {
        println!("やあやあ我こそはPinなり！");
    }
}

fn main() {
    // pin_utils::pin_mutと同じ使い方
    {
        let obj = NotUnpin::new();
        pin!(obj);
        obj.as_mut().method();
    }

    // その場で変数の宣言も出来る
    {
        pin! {
            let obj = NotUnpin::new();
        }
        obj.as_mut().method();
    }
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0Ause%20std%3A%3Apin%3A%3APin%3B%0Ause%20tokio%3A%3Apin%3B%0A%0A%2F%2F%20Unpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%AA%E3%81%84%E5%9E%8B%0Astruct%20NotUnpin%20%7B%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Aimpl%20NotUnpin%20%7B%0A%20%20%20%20%2F%2F%20NotUnpin%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E7%94%9F%E6%88%90%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20new\(\)%20-%3E%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20Pin%3C%26mut%20Self%3E%E3%82%92self%E3%81%A8%E3%81%97%E3%81%A6%E5%8F%97%E3%81%91%E5%8F%96%E3%82%8B%0A%20%20%20%20pub%20fn%20method\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%82%84%E3%81%82%E3%82%84%E3%81%82%E6%88%91%E3%81%93%E3%81%9D%E3%81%AFPin%E3%81%AA%E3%82%8A%EF%BC%81%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20%2F%2F%20pin_utils%3A%3Apin_mut%E3%81%A8%E5%90%8C%E3%81%98%E4%BD%BF%E3%81%84%E6%96%B9%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%20%20%20%20%20%20%20%20pin!\(obj\)%3B%0A%20%20%20%20%20%20%20%20obj.as_mut\(\).method\(\)%3B%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E3%81%9D%E3%81%AE%E5%A0%B4%E3%81%A7%E5%A4%89%E6%95%B0%E3%81%AE%E5%AE%A3%E8%A8%80%E3%82%82%E5%87%BA%E6%9D%A5%E3%82%8B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%20%20pin!%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20obj.as_mut\(\).method\(\)%3B%0A%20%20%20%20%7D%0A%7D%0A)

##### てんかいごのすがた

では、このマクロはどのように展開されるのでしょうか？ 結論から言えば [「スタックから移動しない変数」](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%8B%E3%82%89%E7%A7%BB%E5%8B%95%E3%81%97%E3%81%AA%E3%81%84%E5%A4%89%E6%95%B0) で書いたコードと同じようなコードに展開されます。

具体的には下記で示すようなコードに展開されます。

```rust
use std::marker::PhantomPinned;
use pin_utils::pin_mut;

// Unpinを実装しない型
struct NotUnpin {
    _pinned: PhantomPinned,
}

impl NotUnpin {
    // NotUnpinのインスタンスを生成する
    pub fn new() -> NotUnpin {
        NotUnpin {
            _pinned: PhantomPinned,
        }
    }
}

// マクロを使ったコード
fn use_macro() {
    // 0. objを宣言
    let obj = NotUnpin::new();
    // 1〜3. objをPin化
    pin_mut!(obj);
}

// マクロが展開されるとこのようになる。マクロであるため少し複雑なコードとなる
fn expanded() {
    // 0. objを宣言
    let obj = NotUnpin::new();
    // 3. 元の変数と同じ名前で、Pin化した変数を宣言
    let mut obj = {
        // 1. objを可変にするためにmutな変数に代入
        let mut obj = obj;
        // 2. 可変参照を取ってスタックに固定し、スタックから移動しないようにする
        //    このコードは安全であるため、unsafeブロックで囲んでも問題ない
        unsafe { Pin::new_unchecked(&mut obj) }
    };
}

// マクロで展開されたコードから無駄な部分を省くと以下のコードとなる
fn simplified() {
    // 0〜1. objをmutで宣言
    let mut obj = NotUnpin::new();
    // 2〜3. 可変参照を取ってスタックに固定し、元の変数と同じ名前でPin化した変数を宣言
    //       このコードは安全であるため、unsafeブロックで囲んでも問題ない
    let mut obj = unsafe { Pin::new_unchecked(&mut obj) };
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0Ause%20pin_utils%3A%3Apin_mut%3B%0A%0A%2F%2F%20Unpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%AA%E3%81%84%E5%9E%8B%0Astruct%20NotUnpin%20%7B%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Aimpl%20NotUnpin%20%7B%0A%20%20%20%20%2F%2F%20NotUnpin%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E7%94%9F%E6%88%90%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20new\(\)%20-%3E%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20%E3%83%9E%E3%82%AF%E3%83%AD%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%9F%E3%82%B3%E3%83%BC%E3%83%89%0Afn%20use_macro\(\)%20%7B%0A%20%20%20%20%2F%2F%200.%20obj%E3%82%92%E5%AE%A3%E8%A8%80%0A%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%20%20%20%20%2F%2F%201%E3%80%9C3.%20obj%E3%82%92Pin%E5%8C%96%0A%20%20%20%20pin_mut!\(obj\)%3B%0A%7D%0A%0A%2F%2F%20%E3%83%9E%E3%82%AF%E3%83%AD%E3%81%8C%E5%B1%95%E9%96%8B%E3%81%95%E3%82%8C%E3%82%8B%E3%81%A8%E3%81%93%E3%81%AE%E3%82%88%E3%81%86%E3%81%AB%E3%81%AA%E3%82%8B%E3%80%82%E3%83%9E%E3%82%AF%E3%83%AD%E3%81%A7%E3%81%82%E3%82%8B%E3%81%9F%E3%82%81%E5%B0%91%E3%81%97%E8%A4%87%E9%9B%91%E3%81%AA%E3%82%B3%E3%83%BC%E3%83%89%E3%81%A8%E3%81%AA%E3%82%8B%0Afn%20expanded\(\)%20%7B%0A%20%20%20%20%2F%2F%200.%20obj%E3%82%92%E5%AE%A3%E8%A8%80%0A%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%20%20%20%20%2F%2F%203.%20%E5%85%83%E3%81%AE%E5%A4%89%E6%95%B0%E3%81%A8%E5%90%8C%E3%81%98%E5%90%8D%E5%89%8D%E3%81%A7%E3%80%81Pin%E5%8C%96%E3%81%97%E3%81%9F%E5%A4%89%E6%95%B0%E3%82%92%E5%AE%A3%E8%A8%80%0A%20%20%20%20let%20mut%20obj%20%3D%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%201.%20obj%E3%82%92%E5%8F%AF%E5%A4%89%E3%81%AB%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%ABmut%E3%81%AA%E5%A4%89%E6%95%B0%E3%81%AB%E4%BB%A3%E5%85%A5%0A%20%20%20%20%20%20%20%20let%20mut%20obj%20%3D%20obj%3B%0A%20%20%20%20%20%20%20%20%2F%2F%202.%20%E5%8F%AF%E5%A4%89%E5%8F%82%E7%85%A7%E3%82%92%E5%8F%96%E3%81%A3%E3%81%A6%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%AB%E5%9B%BA%E5%AE%9A%E3%81%97%E3%80%81%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%8B%E3%82%89%E7%A7%BB%E5%8B%95%E3%81%97%E3%81%AA%E3%81%84%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%2F%2F%20%20%20%20%E3%81%93%E3%81%AE%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AF%E5%AE%89%E5%85%A8%E3%81%A7%E3%81%82%E3%82%8B%E3%81%9F%E3%82%81%E3%80%81unsafe%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF%E3%81%A7%E5%9B%B2%E3%82%93%E3%81%A7%E3%82%82%E5%95%8F%E9%A1%8C%E3%81%AA%E3%81%84%0A%20%20%20%20%20%20%20%20unsafe%20%7B%20Pin%3A%3Anew_unchecked\(%26mut%20obj\)%20%7D%0A%20%20%20%20%7D%3B%0A%7D%0A%0A%2F%2F%20%E3%83%9E%E3%82%AF%E3%83%AD%E3%81%A7%E5%B1%95%E9%96%8B%E3%81%95%E3%82%8C%E3%81%9F%E3%82%B3%E3%83%BC%E3%83%89%E3%81%8B%E3%82%89%E7%84%A1%E9%A7%84%E3%81%AA%E9%83%A8%E5%88%86%E3%82%92%E7%9C%81%E3%81%8F%E3%81%A8%E4%BB%A5%E4%B8%8B%E3%81%AE%E3%82%B3%E3%83%BC%E3%83%89%E3%81%A8%E3%81%AA%E3%82%8B%0Afn%20simplified\(\)%20%7B%0A%20%20%20%20%2F%2F%200%E3%80%9C1.%20obj%E3%82%92mut%E3%81%A7%E5%AE%A3%E8%A8%80%0A%20%20%20%20let%20mut%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%20%20%20%20%2F%2F%202%E3%80%9C3.%20%E5%8F%AF%E5%A4%89%E5%8F%82%E7%85%A7%E3%82%92%E5%8F%96%E3%81%A3%E3%81%A6%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%AB%E5%9B%BA%E5%AE%9A%E3%81%97%E3%80%81%E5%85%83%E3%81%AE%E5%A4%89%E6%95%B0%E3%81%A8%E5%90%8C%E3%81%98%E5%90%8D%E5%89%8D%E3%81%A7Pin%E5%8C%96%E3%81%97%E3%81%9F%E5%A4%89%E6%95%B0%E3%82%92%E5%AE%A3%E8%A8%80%0A%20%20%20%20%2F%2F%20%20%20%20%20%20%20%E3%81%93%E3%81%AE%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AF%E5%AE%89%E5%85%A8%E3%81%A7%E3%81%82%E3%82%8B%E3%81%9F%E3%82%81%E3%80%81unsafe%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF%E3%81%A7%E5%9B%B2%E3%82%93%E3%81%A7%E3%82%82%E5%95%8F%E9%A1%8C%E3%81%AA%E3%81%84%0A%20%20%20%20let%20mut%20obj%20%3D%20unsafe%20%7B%20Pin%3A%3Anew_unchecked\(%26mut%20obj\)%20%7D%3B%0A%7D%0A)

#### Box::pin

[`Box::pin`](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.pin) は変数をヒープに確保・固定すると同時に [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んでくれます。 つまり [「ヒープに確保された変数」](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E3%83%92%E3%83%BC%E3%83%97%E3%81%AB%E7%A2%BA%E4%BF%9D%E3%81%95%E3%82%8C%E3%81%9F%E5%A4%89%E6%95%B0) となるわけであり、すなわち「ヒープでピン留めする」のです。

```rust
use std::marker::PhantomPinned;
use std::pin::Pin;

// Unpinを実装しない型
struct NotUnpin {
    _pinned: PhantomPinned,
}

impl NotUnpin {
    // NotUnpinのインスタンスを生成する
    pub fn new() -> NotUnpin {
        NotUnpin {
            _pinned: PhantomPinned,
        }
    }

    // Pin<&mut Self>をselfとして受け取る
    pub fn method(self: Pin<&mut Self>) {
        println!("やあやあ我こそはPinなり！");
    }
}

fn main() {
    let obj = NotUnpin::new();

    // objはUnpinを実装していないためPin::newを使えない
    // let obj = Pin::new(obj);

    // Box::pinによってヒープでピン留めする
    let mut obj: Pin<Box<NotUnpin>> = Box::pin(obj);

    // Pinになったのでメソッドを呼び出せる
    // selfの型をPin<Box<Self>>ではなくPin<&mut Self>にしているため、obj.method()として呼び出せない
    // 代わりにPin::as_mutを使いPin<Box<T>>からPin<&mut T>に変換して呼び出す
    obj.as_mut().method();
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0Ause%20std%3A%3Apin%3A%3APin%3B%0A%0A%2F%2F%20Unpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%AA%E3%81%84%E5%9E%8B%0Astruct%20NotUnpin%20%7B%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Aimpl%20NotUnpin%20%7B%0A%20%20%20%20%2F%2F%20NotUnpin%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E7%94%9F%E6%88%90%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20new\(\)%20-%3E%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20NotUnpin%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20Pin%3C%26mut%20Self%3E%E3%82%92self%E3%81%A8%E3%81%97%E3%81%A6%E5%8F%97%E3%81%91%E5%8F%96%E3%82%8B%0A%20%20%20%20pub%20fn%20method\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%82%84%E3%81%82%E3%82%84%E3%81%82%E6%88%91%E3%81%93%E3%81%9D%E3%81%AFPin%E3%81%AA%E3%82%8A%EF%BC%81%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20obj%20%3D%20NotUnpin%3A%3Anew\(\)%3B%0A%0A%20%20%20%20%2F%2F%20obj%E3%81%AFUnpin%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%97%E3%81%A6%E3%81%84%E3%81%AA%E3%81%84%E3%81%9F%E3%82%81Pin%3A%3Anew%E3%82%92%E4%BD%BF%E3%81%88%E3%81%AA%E3%81%84%0A%20%20%20%20%2F%2F%20let%20obj%20%3D%20Pin%3A%3Anew\(obj\)%3B%0A%0A%20%20%20%20%2F%2F%20Box%3A%3Apin%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E3%83%92%E3%83%BC%E3%83%97%E3%81%A7%E3%83%94%E3%83%B3%E7%95%99%E3%82%81%E3%81%99%E3%82%8B%0A%20%20%20%20let%20mut%20obj%3A%20Pin%3CBox%3CNotUnpin%3E%3E%20%3D%20Box%3A%3Apin\(obj\)%3B%0A%0A%20%20%20%20%2F%2F%20Pin%E3%81%AB%E3%81%AA%E3%81%A3%E3%81%9F%E3%81%AE%E3%81%A7%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%82%92%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%9B%E3%82%8B%0A%20%20%20%20%2F%2F%20self%E3%81%AE%E5%9E%8B%E3%82%92Pin%3CBox%3CSelf%3E%3E%E3%81%A7%E3%81%AF%E3%81%AA%E3%81%8FPin%3C%26mut%20Self%3E%E3%81%AB%E3%81%97%E3%81%A6%E3%81%84%E3%82%8B%E3%81%9F%E3%82%81%E3%80%81obj.method\(\)%E3%81%A8%E3%81%97%E3%81%A6%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%9B%E3%81%AA%E3%81%84%0A%20%20%20%20%2F%2F%20%E4%BB%A3%E3%82%8F%E3%82%8A%E3%81%ABPin%3A%3Aas_mut%E3%82%92%E4%BD%BF%E3%81%84Pin%3CBox%3CT%3E%3E%E3%81%8B%E3%82%89Pin%3C%26mut%20T%3E%E3%81%AB%E5%A4%89%E6%8F%9B%E3%81%97%E3%81%A6%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%99%0A%20%20%20%20obj.as_mut\(\).method\(\)%3B%0A%7D%0A)

#### Rc::pin / Arc::pin

[`Rc::pin`](https://doc.rust-lang.org/std/rc/struct.Rc.html#method.pin) 及び [`Arc::pin`](https://doc.rust-lang.org/std/sync/struct.Arc.html#method.pin) は、 [`Box::pin`](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.pin) と同じく変数をヒープに固定して [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) でピン留めします。 参照カウントが必要な場面で使うことになるでしょう。

使い方は [`Box::pin`](https://tech-blog.optim.co.jp/entry/2020/03/05/#Boxpin) と同じです。

### ムーブしたら絶対アカン😡型も最初だけはムーブして良い

ここでよく考えてみると、上記のいずれの場合でもコンストラクタの戻り値がムーブしていることに気付きます。

```rust
// NotUnpin::newからobjにムーブしている
let mut obj = NotUnpin::new();
let mut obj = unsafe { Pin::new_unchecked(&mut obj) };

// NotUnpin::newからBox::newにムーブしている
let obj = Box::new(NotUnpin::new());
```

と言う事は、「ムーブしたら絶対アカン😡型」をムーブしていることになります。

実のところ、「ムーブしたら絶対アカン😡型」は「『 **ピン留めされたあとに** 』ムーブしたら絶対アカン😡型」なのです。 逆に言えば「『 **ピン留めされるまでは** 』ムーブしてもおけまる🙆な型」でもあります。

そもそも、 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) トレイトは名前からすれば「 **ピン留めを外せることを示す** 」トレイトだと言えます。 つまりピン留めを前提にしているのです。 なので、 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装する型は「ピン留めを外しても良い」、 つまり「『ピン留めされたあとであっても』ムーブしてもおけまる🙆な型」を示すトレイトなわけであり、 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない型は「ピン留めを外してはいけない」、 つまり「『ピン留めされたあとに』ムーブしたら絶対アカン😡型」型なのです。

そのため、「ムーブしたら絶対アカン😡型」は最初はムーブされても問題ない様に作る必要があります。 例えば自身のフィールドへのポインタを保持する構造体では、最初はnullポインタを入れておき、 そのフィールドについてはいつでもnullを処理できるようにしておきます [\*5](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-ed229289 "Option&lt;NonNull&lt;T>>を使うと良いでしょう") 。

なお、この記事では説明を簡単にするため、オブジェクトの生成部分を無視し、 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない型を「ムーブしたら絶対アカン😡型」としています。

### Pinをselfとして受け取る

[安全Pin](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E5%AE%89%E5%85%A8Pin) の章でしれっと `fn method(self: Pin<&mut Self>)` という構文が出て違和感を覚えた人もいるかと思います。 良く使う構文は `fn method(&self)` のような形ですよね。 実は良く使う構文も `fn method(self: &Self)` への糖衣構文なのです。この構文と見比べれば違和感は薄れると思います。

`self` を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) として受け取った場合、それはピン留めされた参照であるため、 その中身は構造体の外ではムーブされないことになります。 `Pin<&mut Self>` は自身を変更できるピン留めされた参照ですし、 他にも `Pin<&Self>` という構文をピン留めされた不変参照として使うことも出来ます。 なお、不変参照であれば `Deref` を通して `&self` を受け取るメソッドをそのまま呼び出すことも出来ますが、 こちらはどこかでムーブされるかもしれないメソッドであるため、 `&self` と `Pin<&Self>` は慎重に使い分けましょう。

ところで、全ての型が `self` の型として扱えるわけではありません。 Rust 1.41現在では `self` の型として扱えるのは下記に限られています。

- `Self`
- `&mut Self`
- `&Self`
- `Box<Self>`
- `Rc<Self>`
- `Arc<Self>`
- `Pin<T>`

因みに `Pin<T>` の `T` は上記における `Self` 以外の「 `self` の型として扱えるもの」が要求されるため、無駄にネストすることもできます。 <sub><sup>もちろん用途はありません。</sup></sub>

```rust
use std::pin::Pin;

struct Hoge;
impl Hoge {
    // 全部OK
    fn method1(self: Pin<&mut Self>) {}
    fn method2(self: Pin<&Self>) {}
    fn method3(self: Pin<Box<Self>>) {}
    fn method4(self: Pin<Pin<Pin<Pin<&mut Self>>>>) {}
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0A%0Astruct%20Hoge%3B%0Aimpl%20Hoge%20%7B%0A%20%20%20%20%2F%2F%20%E5%85%A8%E9%83%A8OK%0A%20%20%20%20fn%20method1\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%7D%0A%20%20%20%20fn%20method2\(self%3A%20Pin%3C%26Self%3E\)%20%7B%7D%0A%20%20%20%20fn%20method3\(self%3A%20Pin%3CBox%3CSelf%3E%3E\)%20%7B%7D%0A%20%20%20%20fn%20method4\(self%3A%20Pin%3CPin%3CPin%3CPin%3C%26mut%20Self%3E%3E%3E%3E\)%20%7B%7D%0A%7D%0A)

なお、将来的には様々な型を `self` として受け取れるようになる可能性があります。

### Pinの中身を変更する

さて、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を作ったり受け取ったりは出来るようになりましたが、今のところ受け取ったとしても中身を変更することができません。 これでは不変参照を使うのと変わらないどころかタイプ数が無駄に増えているだけです。

でも大丈夫。中身を変更するAPIもしっかり用意されています。

変数の中身を書き換えるには **不安全** な [`Pin::get_unchecked_mut`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.get_unchecked_mut) を使うこととなります。 これは「ムーブしたら絶対アカン😡型」を書き換えた場合にオブジェクトの内部状態がどのようになるかはコンパイラは分からないためであり、 内部状態の整合性が保たれることに実装者が責任を持つ必要があります。

```rust
use std::pin::Pin;

struct Hoge {
    field: u32,
}

impl Hoge {
    fn get(self: Pin<&mut Self>) -> u32 {
        // 中身を変更しない場合、Derefによって透過的にフィールドにアクセスできる
        self.field
    }

    fn inc(self: Pin<&mut Self>) {
        unsafe {
            // Pin::get_unchecked_mutから&mut Hogeが返る
            let this: &mut Hoge = self.get_unchecked_mut();
            this.field += 1;
        }
    }
}

fn main() {
    let mut hoge = Box::pin(Hoge { field: 0 });
    hoge.as_mut().inc();
    assert_eq!(hoge.as_mut().get(), 1);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0A%0Astruct%20Hoge%20%7B%0A%20%20%20%20field%3A%20u32%2C%0A%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20fn%20get\(self%3A%20Pin%3C%26mut%20Self%3E\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20%E4%B8%AD%E8%BA%AB%E3%82%92%E5%A4%89%E6%9B%B4%E3%81%97%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%80%81Deref%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E9%80%8F%E9%81%8E%E7%9A%84%E3%81%AB%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%81%A7%E3%81%8D%E3%82%8B%0A%20%20%20%20%20%20%20%20self.field%0A%20%20%20%20%7D%0A%0A%20%20%20%20fn%20inc\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20Pin%3A%3Aget_unchecked_mut%E3%81%8B%E3%82%89%26mut%20Hoge%E3%81%8C%E8%BF%94%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%3A%20%26mut%20Hoge%20%3D%20self.get_unchecked_mut\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20this.field%20%2B%3D%201%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20hoge%20%3D%20Box%3A%3Apin\(Hoge%20%7B%20field%3A%200%20%7D\)%3B%0A%20%20%20%20hoge.as_mut\(\).inc\(\)%3B%0A%20%20%20%20assert_eq!\(hoge.as_mut\(\).get\(\)%2C%201\)%3B%0A%7D%0A)

#### 安全にPinの中身を変更する

**更新（03/09）： [指摘](https://twitter.com/__pandaman64__/status/1235477608856342528) を受け、# [pin\_project](https://docs.rs/pin-project/0.4/pin_project/attr.pin_project.html) 属性マクロを使う前提に書き換えました**

不安全なコードで [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の中身を変更できるようにはなりましたが、使う場面でいちいちunsafeブロックが必要になり、 しかも本当にそのコードが安全なのか不安になります。

でも安心してください。この操作を安全に実現するクレートがあります。

##### pin\_project::pin\_project属性マクロ

[pin-projectクレート](https://github.com/taiki-e/pin-project) が提供する [#\[pin\_project\]](https://docs.rs/pin-project/0.4/pin_project/attr.pin_project.html) 属性マクロを使うと、 安全に `Pin<&mut Self>` からフィールドを `&mut T` として取り出すことが出来るため、安全に [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の中身を変更することが出来ます。

```rust
use std::pin::Pin;
use pin_project::pin_project;

// 構造体定義に#[pin_project]属性マクロを付ける
#[pin_project]
struct Hoge {
    field: u32,
}

impl Hoge {
    fn get(self: Pin<&mut Self>) -> u32 {
        // 中身を変更しない場合、Derefによって透過的にフィールドにアクセスできる
        self.field
    }

    fn inc(self: Pin<&mut Self>) {
        // projectメソッドはHogeのfieldフィールドが&mut u32になった構造体を返す
        let this = self.project();
        *this.field += 1;
    }
}

fn main() {
    let mut hoge = Box::pin(Hoge { field: 0 });
    hoge.as_mut().inc();
    assert_eq!(hoge.as_mut().get(), 1);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_project%3A%3Apin_project%3B%0A%0A%2F%2F%20%E6%A7%8B%E9%80%A0%E4%BD%93%E5%AE%9A%E7%BE%A9%E3%81%AB%23%5Bpin_project%5D%E5%B1%9E%E6%80%A7%E3%83%9E%E3%82%AF%E3%83%AD%E3%82%92%E4%BB%98%E3%81%91%E3%82%8B%0A%23%5Bpin_project%5D%0Astruct%20Hoge%20%7B%0A%20%20%20%20field%3A%20u32%2C%0A%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20fn%20get\(self%3A%20Pin%3C%26mut%20Self%3E\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20%E4%B8%AD%E8%BA%AB%E3%82%92%E5%A4%89%E6%9B%B4%E3%81%97%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%80%81Deref%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E9%80%8F%E9%81%8E%E7%9A%84%E3%81%AB%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%81%A7%E3%81%8D%E3%82%8B%0A%20%20%20%20%20%20%20%20self.field%0A%20%20%20%20%7D%0A%0A%20%20%20%20fn%20inc\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20project%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%AFHoge%E3%81%AEfield%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%8C%26mut%20u32%E3%81%AB%E3%81%AA%E3%81%A3%E3%81%9F%E6%A7%8B%E9%80%A0%E4%BD%93%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20%20%20%20%20let%20this%20%3D%20self.project\(\)%3B%0A%20%20%20%20%20%20%20%20*this.field%20%2B%3D%201%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20hoge%20%3D%20Box%3A%3Apin\(Hoge%20%7B%20field%3A%200%20%7D\)%3B%0A%20%20%20%20hoge.as_mut\(\).inc\(\)%3B%0A%20%20%20%20assert_eq!\(hoge.as_mut\(\).get\(\)%2C%201\)%3B%0A%7D%0A)

##### ちょっと危険なpin\_utils::unsafe\_unpinned!マクロ

[pin-utilsクレート](https://github.com/rust-lang-nursery/pin-utils) が提供する [`unsafe_unpinned!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.unsafe_unpinned.html)マクロは、 `Pin<&mut Self>` からフィールドを `&mut T` で取り出すメソッドを定義します。 ただし名前にunsafeと入っていることから分かる通りこのマクロは安全ではなく、 [`Pin::get_unchecked_mut`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.get_unchecked_mut) を使うときと同様、 内部状態の整合性が保たれることに実装者が責任を持つ必要があります。

```rust
use std::pin::Pin;
use pin_utils::unsafe_unpinned;

struct Hoge {
    field: u32,
}

impl Hoge {
    unsafe_unpinned!(field: u32);

    fn get(self: Pin<&mut Self>) -> u32 {
        // 中身を変更しない場合、Derefによって透過的にフィールドにアクセスできる
        self.field
    }

    fn inc(self: Pin<&mut Self>) {
        // self.field()は&mut u32を返す
        let field: &mut u32 = self.field();
        *field += 1;
    }
}

fn main() {
    let mut hoge = Box::pin(Hoge { field: 0 });
    hoge.as_mut().inc();
    assert_eq!(hoge.as_mut().get(), 1);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_utils%3A%3Aunsafe_unpinned%3B%0A%0Astruct%20Hoge%20%7B%0A%20%20%20%20field%3A%20u32%2C%0A%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20unsafe_unpinned!\(field%3A%20u32\)%3B%0A%0A%20%20%20%20fn%20get\(self%3A%20Pin%3C%26mut%20Self%3E\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20%E4%B8%AD%E8%BA%AB%E3%82%92%E5%A4%89%E6%9B%B4%E3%81%97%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%80%81Deref%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E9%80%8F%E9%81%8E%E7%9A%84%E3%81%AB%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%81%A7%E3%81%8D%E3%82%8B%0A%20%20%20%20%20%20%20%20self.field%0A%20%20%20%20%7D%0A%0A%20%20%20%20fn%20inc\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20self.field\(\)%E3%81%AF%26mut%20u32%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20%20%20%20%20let%20field%3A%20%26mut%20u32%20%3D%20self.field\(\)%3B%0A%20%20%20%20%20%20%20%20*field%20%2B%3D%201%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20hoge%20%3D%20Box%3A%3Apin\(Hoge%20%7B%20field%3A%200%20%7D\)%3B%0A%20%20%20%20hoge.as_mut\(\).inc\(\)%3B%0A%20%20%20%20assert_eq!\(hoge.as_mut\(\).get\(\)%2C%201\)%3B%0A%7D%0A)

### PinのフィールドからPinを生成する

前の章では [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) で受け取った自身のフィールドを書き換える方法をご紹介しました。 では、自身のフィールドに [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を要求するオブジェクトがあった場合にはどうなるでしょうか。 以下の場合を考えてみます。

```rust
use std::pin::Pin;

struct Hoge {}

impl Hoge {
    pub fn hoge(self: Pin<&mut Self>) {}
}

struct Fuga {
    hoge: Hoge,
}

impl Fuga {
    pub fn fuga(self: Pin<&mut Self>) {
        unsafe {
            let this = self.get_unchecked_mut();

            // Hoge::hogeを呼び出したいが、this.hogeはHoge型なのでPin<&mut Hoge>として受け取れない
            this.hoge.hoge();
        }
    }
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0A%0Astruct%20Hoge%20%7B%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20pub%20fn%20hoge\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%7D%0A%7D%0A%0Astruct%20Fuga%20%7B%0A%20%20%20%20hoge%3A%20Hoge%2C%0A%7D%0A%0Aimpl%20Fuga%20%7B%0A%20%20%20%20pub%20fn%20fuga\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%20%3D%20self.get_unchecked_mut\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20Hoge%3A%3Ahoge%E3%82%92%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97%E3%81%9F%E3%81%84%E3%81%8C%E3%80%81this.hoge%E3%81%AFHoge%E5%9E%8B%E3%81%AA%E3%81%AE%E3%81%A7Pin%3C%26mut%20Hoge%3E%E3%81%A8%E3%81%97%E3%81%A6%E5%8F%97%E3%81%91%E5%8F%96%E3%82%8C%E3%81%AA%E3%81%84%0A%20%20%20%20%20%20%20%20%20%20%20%20this.hoge.hoge\(\)%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A)

このようなパターンは現実には [`Future`](https://doc.rust-lang.org/std/future/trait.Future.html) を使うときに良く出てきます。 これは標準ライブラリにおいては [`Pin::map_unchecked_mut`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.map_unchecked_mut) を使うことで実現できます。 このメソッドは [`Pin::get_unchecked_mut`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.get_unchecked_mut) と同じく不安全なメソッドであり、 例によって内部状態の整合性が保たれることに実装者が責任を持つ必要があります。

```rust
use std::pin::Pin;

struct Hoge {}

impl Hoge {
    pub fn hoge(self: Pin<&mut Self>) {
        println!("ほげ");
    }
}

struct Fuga {
    hoge: Hoge,
}

impl Fuga {
    pub fn fuga(self: Pin<&mut Self>) {
        unsafe {
            // map_unchecked_mutによりhogeをPin<&mut Hoge>として取り出すことが出来る
            let mut hoge: Pin<&mut Hoge> = self.map_unchecked_mut(|this| &mut this.hoge);
            hoge.as_mut().hoge();
        }
    }
}

fn main() {
    let mut fuga = Box::pin(Fuga { hoge: Hoge {} });
    fuga.as_mut().fuga();
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0A%0Astruct%20Hoge%20%7B%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20pub%20fn%20hoge\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%81%BB%E3%81%92%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Astruct%20Fuga%20%7B%0A%20%20%20%20hoge%3A%20Hoge%2C%0A%7D%0A%0Aimpl%20Fuga%20%7B%0A%20%20%20%20pub%20fn%20fuga\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20map_unchecked_mut%E3%81%AB%E3%82%88%E3%82%8Ahoge%E3%82%92Pin%3C%26mut%20Hoge%3E%E3%81%A8%E3%81%97%E3%81%A6%E5%8F%96%E3%82%8A%E5%87%BA%E3%81%99%E3%81%93%E3%81%A8%E3%81%8C%E5%87%BA%E6%9D%A5%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20mut%20hoge%3A%20Pin%3C%26mut%20Hoge%3E%20%3D%20self.map_unchecked_mut\(%7Cthis%7C%20%26mut%20this.hoge\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20hoge.as_mut\(\).hoge\(\)%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20fuga%20%3D%20Box%3A%3Apin\(Fuga%20%7B%20hoge%3A%20Hoge%20%7B%7D%20%7D\)%3B%0A%20%20%20%20fuga.as_mut\(\).fuga\(\)%3B%0A%7D%0A)

#### 安全にPinのフィールドからPinを生成する

**更新（03/09）： [指摘](https://twitter.com/__pandaman64__/status/1235477608856342528) を受け、# [pin\_project](https://docs.rs/pin-project/0.4/pin_project/attr.pin_project.html) 属性マクロを使う前提に書き換えました**

[前章](https://tech-blog.optim.co.jp/entry/2020/03/05/#%E5%AE%89%E5%85%A8%E3%81%ABPin%E3%81%AE%E4%B8%AD%E8%BA%AB%E3%82%92%E5%A4%89%E6%9B%B4%E3%81%99%E3%82%8B) と同じく、外部クレートを使うことで安全にこの操作を実現できます。

##### pin\_project::pin\_project属性マクロ

[pin-projectクレート](https://github.com/taiki-e/pin-project) が提供する\[#\[pin\_project\]\]属性マクロと `#[pin]` ヘルパー属性を使うと、 安全に `Pin<&mut Self>` からフィールドを `Pin<&mut U>` として取り出すことができ、安全に `Pin<&mut Self>` から [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) を生成することが出来ます。

```rust
use std::pin::Pin;
use pin_project::pin_project;

struct Hoge {}

impl Hoge {
    fn hoge(self: Pin<&mut Self>) {
        println!("ほげ");
    }
}

// 構造体定義に#[pin_project]属性マクロを付ける
#[pin_project]
struct Fuga {
    // Pin化したいフィールドに#[pin]ヘルパー属性を付ける
    #[pin]
    hoge: Hoge,
}

impl Fuga {
    fn fuga(self: Pin<&mut Self>) {
        // projectメソッドはFugaのhogeフィールドがPin<&mut Hoge>になった構造体を返す
        let this = self.project();
        this.hoge.hoge();
    }
}

fn main() {
    let mut fuga = Box::pin(Fuga { hoge: Hoge {} });
    fuga.as_mut().fuga();
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_project%3A%3Apin_project%3B%0A%0Astruct%20Hoge%20%7B%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20fn%20hoge\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%81%BB%E3%81%92%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20%E6%A7%8B%E9%80%A0%E4%BD%93%E5%AE%9A%E7%BE%A9%E3%81%AB%23%5Bpin_project%5D%E5%B1%9E%E6%80%A7%E3%83%9E%E3%82%AF%E3%83%AD%E3%82%92%E4%BB%98%E3%81%91%E3%82%8B%0A%23%5Bpin_project%5D%0Astruct%20Fuga%20%7B%0A%20%20%20%20%2F%2F%20Pin%E5%8C%96%E3%81%97%E3%81%9F%E3%81%84%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%AB%23%5Bpin%5D%E3%83%98%E3%83%AB%E3%83%91%E3%83%BC%E5%B1%9E%E6%80%A7%E3%82%92%E4%BB%98%E3%81%91%E3%82%8B%0A%20%20%20%20%23%5Bpin%5D%0A%20%20%20%20hoge%3A%20Hoge%2C%0A%7D%0A%0Aimpl%20Fuga%20%7B%0A%20%20%20%20fn%20fuga\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20project%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%AFFuga%E3%81%AEhoge%E3%83%95%E3%82%A3%E3%83%BC%E3%83%AB%E3%83%89%E3%81%8CPin%3C%26mut%20Hoge%3E%E3%81%AB%E3%81%AA%E3%81%A3%E3%81%9F%E6%A7%8B%E9%80%A0%E4%BD%93%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20%20%20%20%20let%20this%20%3D%20self.project\(\)%3B%0A%20%20%20%20%20%20%20%20this.hoge.hoge\(\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20fuga%20%3D%20Box%3A%3Apin\(Fuga%20%7B%20hoge%3A%20Hoge%20%7B%7D%20%7D\)%3B%0A%20%20%20%20fuga.as_mut\(\).fuga\(\)%3B%0A%7D%0A)

##### ちょっと危険なpin\_utils::unsafe\_pinned!マクロ

[pin-utilsクレート](https://github.com/rust-lang-nursery/pin-utils) が提供する [`unsafe_pinned!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.unsafe_pinned.html)マクロは、 `Pin<&mut Self>` からフィールドを `Pin<&mut T>` で取り出すメソッドを定義します。 ただし名前にunsafeと入っていることから分かる通りこのマクロは安全ではなく、 [`Pin::map_unchecked_mut`](https://doc.rust-lang.org/std/pin/struct.Pin.html#method.map_unchecked_mut) を使うときと同様、 内部状態の整合性が保たれることに実装者が責任を持つ必要があります。

```rust
use std::pin::Pin;
use pin_utils::unsafe_pinned;

struct Hoge {}

impl Hoge {
    fn hoge(self: Pin<&mut Self>) {
        println!("ほげ");
    }
}

struct Fuga {
    hoge: Hoge,
}

impl Fuga {
    unsafe_pinned!(hoge: Hoge);

    fn fuga(self: Pin<&mut Self>) {
        // self.hoge()はPin<&mut Hoge>を返す
        self.hoge().hoge();
    }
}

fn main() {
    let mut fuga = Box::pin(Fuga { hoge: Hoge {} });
    fuga.as_mut().fuga();
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_utils%3A%3Aunsafe_pinned%3B%0A%0Astruct%20Hoge%20%7B%7D%0A%0Aimpl%20Hoge%20%7B%0A%20%20%20%20fn%20hoge\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20println!\(%22%E3%81%BB%E3%81%92%22\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Astruct%20Fuga%20%7B%0A%20%20%20%20hoge%3A%20Hoge%2C%0A%7D%0A%0Aimpl%20Fuga%20%7B%0A%20%20%20%20unsafe_pinned!\(hoge%3A%20Hoge\)%3B%0A%0A%20%20%20%20fn%20fuga\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20self.hoge\(\)%E3%81%AFPin%3C%26mut%20Hoge%3E%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20%20%20%20%20self.hoge\(\).hoge\(\)%3B%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20let%20mut%20fuga%20%3D%20Box%3A%3Apin\(Fuga%20%7B%20hoge%3A%20Hoge%20%7B%7D%20%7D\)%3B%0A%20%20%20%20fuga.as_mut\(\).fuga\(\)%3B%0A%7D%0A)

### サンプル：サイズが静的な、自己参照する配列型

これは [`Vec`](https://doc.rust-lang.org/std/vec/struct.Vec.html) と違ってヒープを使わず、メモリ領域が静的に決定される配列型です。 ここではサンプルのため無理矢理 `tail` として自己参照していますが、実際には `usize` で配列の長さを保持するだけで実現できます。 なお、このコードはヒープを利用しておらず、また標準ライブラリのみで動きます。

```rust
use std::marker::PhantomPinned;
use std::mem::{self, MaybeUninit};
use std::pin::Pin;
use std::ptr::NonNull;

// メモリ領域が静的なサイズの配列型。
struct Array<T> {
    // 配列の実データ
    array: [MaybeUninit<T>; 1024],
    // arrayの末尾要素を指す。長さを保持する代わりに自身への参照を保持する
    // 初期状態ではNoneを保持する
    tail: Option<NonNull<T>>,
    _pinned: PhantomPinned,
}

impl<T> Array<T> {
    // Arrayを新しく生成する
    pub fn new() -> Array<T> {
        unsafe {
            Array {
                // [MaybeUninit::uninit(); 1024]は出来ないのでこうする
                array: MaybeUninit::uninit().assume_init(),
                // 最初はムーブしても良いようにNoneとする
                tail: None,
                _pinned: PhantomPinned,
            }
        }
    }

    // 配列の長さを返す
    // このメソッドはselfにムーブされ得ないことを要求する
    pub fn len(self: Pin<&Self>) -> usize {
        match &self.tail {
            Some(tail) => tail.as_ptr() as usize + 1 - self.array.as_ptr() as usize,
            None => 0,
        }
    }

    // 配列のindex番目から読み込む
    pub fn read(self: Pin<&Self>, index: usize) -> Option<&T> {
        if index < self.len() {
            unsafe {
                Some(&*self.array[index].as_ptr())
            }
        } else {
            None
        }
    }

    // 配列にデータを追加する。データを追加できなかった場合はfalseを返す
    pub fn push(self: Pin<&mut Self>, x: T) -> bool {
        let len = self.as_ref().len();
        if len >= 1024 {
            return false;
        }

        // pushは内部状態を変化させるため不安全なのは当然
        unsafe {
            let this = self.get_unchecked_mut();

            // 末尾要素へのポインタを取得
            let tail = this.array[len].as_mut_ptr();
            // 未初期化の値をdropしないようにしつつ追加要素を書き込む
            tail.write(x);

            // tailを更新し、tailが常にarrayの末尾要素を指すようにする
            this.tail = Some(NonNull::new_unchecked(tail));

            true
        }
    }

    // 配列のindex番目に書き込む
    pub fn write(self: Pin<&mut Self>, index: usize, x: T) {
        assert!(index < self.as_ref().len());

        // writeは内部状態を変化させないにも関わらずget_unchecked_mutによる不安全なコードになってしまう
        unsafe {
            let this = self.get_unchecked_mut();

            let ptr = this.array[index].as_mut_ptr();
            // 以前書き込まれた値をdropし、新しい値を書き込む
            *ptr = x;
        }
    }

    // 末尾要素を取り出す
    pub fn pop(self: Pin<&mut Self>) -> Option<T> {
        unsafe {
            let this = self.get_unchecked_mut();

            if let Some(tail) = this.tail {
                let tail = tail.as_ptr();

                // 末尾要素を読み出して戻り値とする
                let v = tail.read();
                // 末尾要素を1つ戻す
                let tail = tail.sub(1);
                // tailが先頭より前に行かないようにする
                this.tail = if tail >= this.array[0].as_mut_ptr() {
                    Some(NonNull::new_unchecked(tail))
                } else {
                    None
                };

                Some(v)
            } else {
                None
            }
        }
    }

    // PinとしてDropする
    fn drop_pinned(self: Pin<&mut Self>) {
        unsafe {
            let len = self.as_ref().len();
            let this = self.get_unchecked_mut();

            if mem::needs_drop::<T>() {
                // 各要素はMaybeUninitのためdropされないので自分でdropを実行する
                for i in 0..len {
                    this.array[i].as_mut_ptr().drop_in_place();
                }
            }
            this.tail = None;
        }
    }
}

impl<T> Drop for Array<T> {
    fn drop(&mut self) {
        unsafe {
            // DropするときはPinとしてDropする
            Pin::new_unchecked(self).drop_pinned();
        }
    }
}

fn main() {
    // Arrayを生成し、スタックに固定、ピン留めする
    let mut array = Array::new();
    // pin_utils::pin_mut!(obj);でも可
    let mut array = unsafe { Pin::new_unchecked(&mut array) };

    // 値をpushしてみる
    array.as_mut().push(0u32);
    assert_eq!(array.as_ref().len(), 1);
    assert_eq!(array.as_ref().read(0), Some(&0u32));

    // 値を書き換えてみる
    array.as_mut().write(0, 1u32);
    assert_eq!(array.as_ref().read(0), Some(&1u32));
    assert_eq!(array.as_mut().pop(), Some(1u32));

    // 値をpopしたので要素は空
    assert_eq!(array.as_ref().len(), 0);
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Amarker%3A%3APhantomPinned%3B%0Ause%20std%3A%3Amem%3A%3A%7Bself%2C%20MaybeUninit%7D%3B%0Ause%20std%3A%3Apin%3A%3APin%3B%0Ause%20std%3A%3Aptr%3A%3ANonNull%3B%0A%0A%2F%2F%20%E3%83%A1%E3%83%A2%E3%83%AA%E9%A0%98%E5%9F%9F%E3%81%8C%E9%9D%99%E7%9A%84%E3%81%AA%E3%82%B5%E3%82%A4%E3%82%BA%E3%81%AE%E9%85%8D%E5%88%97%E5%9E%8B%E3%80%82%0Astruct%20Array%3CT%3E%20%7B%0A%20%20%20%20%2F%2F%20%E9%85%8D%E5%88%97%E3%81%AE%E5%AE%9F%E3%83%87%E3%83%BC%E3%82%BF%0A%20%20%20%20array%3A%20%5BMaybeUninit%3CT%3E%3B%201024%5D%2C%0A%20%20%20%20%2F%2F%20array%E3%81%AE%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%82%92%E6%8C%87%E3%81%99%E3%80%82%E9%95%B7%E3%81%95%E3%82%92%E4%BF%9D%E6%8C%81%E3%81%99%E3%82%8B%E4%BB%A3%E3%82%8F%E3%82%8A%E3%81%AB%E8%87%AA%E8%BA%AB%E3%81%B8%E3%81%AE%E5%8F%82%E7%85%A7%E3%82%92%E4%BF%9D%E6%8C%81%E3%81%99%E3%82%8B%0A%20%20%20%20%2F%2F%20%E5%88%9D%E6%9C%9F%E7%8A%B6%E6%85%8B%E3%81%A7%E3%81%AFNone%E3%82%92%E4%BF%9D%E6%8C%81%E3%81%99%E3%82%8B%0A%20%20%20%20tail%3A%20Option%3CNonNull%3CT%3E%3E%2C%0A%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%7D%0A%0Aimpl%3CT%3E%20Array%3CT%3E%20%7B%0A%20%20%20%20%2F%2F%20Array%E3%82%92%E6%96%B0%E3%81%97%E3%81%8F%E7%94%9F%E6%88%90%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20new\(\)%20-%3E%20Array%3CT%3E%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20Array%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%5BMaybeUninit%3A%3Auninit\(\)%3B%201024%5D%E3%81%AF%E5%87%BA%E6%9D%A5%E3%81%AA%E3%81%84%E3%81%AE%E3%81%A7%E3%81%93%E3%81%86%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20array%3A%20MaybeUninit%3A%3Auninit\(\).assume_init\(\)%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E6%9C%80%E5%88%9D%E3%81%AF%E3%83%A0%E3%83%BC%E3%83%96%E3%81%97%E3%81%A6%E3%82%82%E8%89%AF%E3%81%84%E3%82%88%E3%81%86%E3%81%ABNone%E3%81%A8%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20tail%3A%20None%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20_pinned%3A%20PhantomPinned%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E9%85%8D%E5%88%97%E3%81%AE%E9%95%B7%E3%81%95%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20%2F%2F%20%E3%81%93%E3%81%AE%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%AFself%E3%81%AB%E3%83%A0%E3%83%BC%E3%83%96%E3%81%95%E3%82%8C%E5%BE%97%E3%81%AA%E3%81%84%E3%81%93%E3%81%A8%E3%82%92%E8%A6%81%E6%B1%82%E3%81%99%E3%82%8B%0A%20%20%20%20pub%20fn%20len\(self%3A%20Pin%3C%26Self%3E\)%20-%3E%20usize%20%7B%0A%20%20%20%20%20%20%20%20match%20%26self.tail%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20Some\(tail\)%20%3D%3E%20tail.as_ptr\(\)%20as%20usize%20%2B%201%20-%20self.array.as_ptr\(\)%20as%20usize%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20None%20%3D%3E%200%2C%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E9%85%8D%E5%88%97%E3%81%AEindex%E7%95%AA%E7%9B%AE%E3%81%8B%E3%82%89%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%82%80%0A%20%20%20%20pub%20fn%20read\(self%3A%20Pin%3C%26Self%3E%2C%20index%3A%20usize\)%20-%3E%20Option%3C%26T%3E%20%7B%0A%20%20%20%20%20%20%20%20if%20index%20%3C%20self.len\(\)%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20Some\(%26*self.array%5Bindex%5D.as_ptr\(\)\)%0A%20%20%20%20%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20%7D%20else%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20None%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E9%85%8D%E5%88%97%E3%81%AB%E3%83%87%E3%83%BC%E3%82%BF%E3%82%92%E8%BF%BD%E5%8A%A0%E3%81%99%E3%82%8B%E3%80%82%E3%83%87%E3%83%BC%E3%82%BF%E3%82%92%E8%BF%BD%E5%8A%A0%E3%81%A7%E3%81%8D%E3%81%AA%E3%81%8B%E3%81%A3%E3%81%9F%E5%A0%B4%E5%90%88%E3%81%AFfalse%E3%82%92%E8%BF%94%E3%81%99%0A%20%20%20%20pub%20fn%20push\(self%3A%20Pin%3C%26mut%20Self%3E%2C%20x%3A%20T\)%20-%3E%20bool%20%7B%0A%20%20%20%20%20%20%20%20let%20len%20%3D%20self.as_ref\(\).len\(\)%3B%0A%20%20%20%20%20%20%20%20if%20len%20%3E%3D%201024%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20return%20false%3B%0A%20%20%20%20%20%20%20%20%7D%0A%0A%20%20%20%20%20%20%20%20%2F%2F%20push%E3%81%AF%E5%86%85%E9%83%A8%E7%8A%B6%E6%85%8B%E3%82%92%E5%A4%89%E5%8C%96%E3%81%95%E3%81%9B%E3%82%8B%E3%81%9F%E3%82%81%E4%B8%8D%E5%AE%89%E5%85%A8%E3%81%AA%E3%81%AE%E3%81%AF%E5%BD%93%E7%84%B6%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%20%3D%20self.get_unchecked_mut\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%81%B8%E3%81%AE%E3%83%9D%E3%82%A4%E3%83%B3%E3%82%BF%E3%82%92%E5%8F%96%E5%BE%97%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20tail%20%3D%20this.array%5Blen%5D.as_mut_ptr\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E6%9C%AA%E5%88%9D%E6%9C%9F%E5%8C%96%E3%81%AE%E5%80%A4%E3%82%92drop%E3%81%97%E3%81%AA%E3%81%84%E3%82%88%E3%81%86%E3%81%AB%E3%81%97%E3%81%A4%E3%81%A4%E8%BF%BD%E5%8A%A0%E8%A6%81%E7%B4%A0%E3%82%92%E6%9B%B8%E3%81%8D%E8%BE%BC%E3%82%80%0A%20%20%20%20%20%20%20%20%20%20%20%20tail.write\(x\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20tail%E3%82%92%E6%9B%B4%E6%96%B0%E3%81%97%E3%80%81tail%E3%81%8C%E5%B8%B8%E3%81%ABarray%E3%81%AE%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%82%92%E6%8C%87%E3%81%99%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20this.tail%20%3D%20Some\(NonNull%3A%3Anew_unchecked\(tail\)\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20true%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E9%85%8D%E5%88%97%E3%81%AEindex%E7%95%AA%E7%9B%AE%E3%81%AB%E6%9B%B8%E3%81%8D%E8%BE%BC%E3%82%80%0A%20%20%20%20pub%20fn%20write\(self%3A%20Pin%3C%26mut%20Self%3E%2C%20index%3A%20usize%2C%20x%3A%20T\)%20%7B%0A%20%20%20%20%20%20%20%20assert!\(index%20%3C%20self.as_ref\(\).len\(\)\)%3B%0A%0A%20%20%20%20%20%20%20%20%2F%2F%20write%E3%81%AF%E5%86%85%E9%83%A8%E7%8A%B6%E6%85%8B%E3%82%92%E5%A4%89%E5%8C%96%E3%81%95%E3%81%9B%E3%81%AA%E3%81%84%E3%81%AB%E3%82%82%E9%96%A2%E3%82%8F%E3%82%89%E3%81%9Aget_unchecked_mut%E3%81%AB%E3%82%88%E3%82%8B%E4%B8%8D%E5%AE%89%E5%85%A8%E3%81%AA%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AB%E3%81%AA%E3%81%A3%E3%81%A6%E3%81%97%E3%81%BE%E3%81%86%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%20%3D%20self.get_unchecked_mut\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20ptr%20%3D%20this.array%5Bindex%5D.as_mut_ptr\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E4%BB%A5%E5%89%8D%E6%9B%B8%E3%81%8D%E8%BE%BC%E3%81%BE%E3%82%8C%E3%81%9F%E5%80%A4%E3%82%92drop%E3%81%97%E3%80%81%E6%96%B0%E3%81%97%E3%81%84%E5%80%A4%E3%82%92%E6%9B%B8%E3%81%8D%E8%BE%BC%E3%82%80%0A%20%20%20%20%20%20%20%20%20%20%20%20*ptr%20%3D%20x%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%82%92%E5%8F%96%E3%82%8A%E5%87%BA%E3%81%99%0A%20%20%20%20pub%20fn%20pop\(self%3A%20Pin%3C%26mut%20Self%3E\)%20-%3E%20Option%3CT%3E%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%20%3D%20self.get_unchecked_mut\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20if%20let%20Some\(tail\)%20%3D%20this.tail%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20let%20tail%20%3D%20tail.as_ptr\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%82%92%E8%AA%AD%E3%81%BF%E5%87%BA%E3%81%97%E3%81%A6%E6%88%BB%E3%82%8A%E5%80%A4%E3%81%A8%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20let%20v%20%3D%20tail.read\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E6%9C%AB%E5%B0%BE%E8%A6%81%E7%B4%A0%E3%82%921%E3%81%A4%E6%88%BB%E3%81%99%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20let%20tail%20%3D%20tail.sub\(1\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20tail%E3%81%8C%E5%85%88%E9%A0%AD%E3%82%88%E3%82%8A%E5%89%8D%E3%81%AB%E8%A1%8C%E3%81%8B%E3%81%AA%E3%81%84%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20this.tail%20%3D%20if%20tail%20%3E%3D%20this.array%5B0%5D.as_mut_ptr\(\)%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20Some\(NonNull%3A%3Anew_unchecked\(tail\)\)%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%7D%20else%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20None%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%7D%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20Some\(v\)%0A%20%20%20%20%20%20%20%20%20%20%20%20%7D%20else%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20None%0A%20%20%20%20%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%0A%20%20%20%20%2F%2F%20Pin%E3%81%A8%E3%81%97%E3%81%A6Drop%E3%81%99%E3%82%8B%0A%20%20%20%20fn%20drop_pinned\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20len%20%3D%20self.as_ref\(\).len\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20let%20this%20%3D%20self.get_unchecked_mut\(\)%3B%0A%0A%20%20%20%20%20%20%20%20%20%20%20%20if%20mem%3A%3Aneeds_drop%3A%3A%3CT%3E\(\)%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20%E5%90%84%E8%A6%81%E7%B4%A0%E3%81%AFMaybeUninit%E3%81%AE%E3%81%9F%E3%82%81drop%E3%81%95%E3%82%8C%E3%81%AA%E3%81%84%E3%81%AE%E3%81%A7%E8%87%AA%E5%88%86%E3%81%A7drop%E3%82%92%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20for%20i%20in%200..len%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20this.array%5Bi%5D.as_mut_ptr\(\).drop_in_place\(\)%3B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20%20%20%20%20this.tail%20%3D%20None%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A%0Aimpl%3CT%3E%20Drop%20for%20Array%3CT%3E%20%7B%0A%20%20%20%20fn%20drop\(%26mut%20self\)%20%7B%0A%20%20%20%20%20%20%20%20unsafe%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%2F%2F%20Drop%E3%81%99%E3%82%8B%E3%81%A8%E3%81%8D%E3%81%AFPin%E3%81%A8%E3%81%97%E3%81%A6Drop%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20%20%20%20%20Pin%3A%3Anew_unchecked\(self\).drop_pinned\(\)%3B%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%7D%0A%0Afn%20main\(\)%20%7B%0A%20%20%20%20%2F%2F%20Array%E3%82%92%E7%94%9F%E6%88%90%E3%81%97%E3%80%81%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%AB%E5%9B%BA%E5%AE%9A%E3%80%81%E3%83%94%E3%83%B3%E7%95%99%E3%82%81%E3%81%99%E3%82%8B%0A%20%20%20%20let%20mut%20array%20%3D%20Array%3A%3Anew\(\)%3B%0A%20%20%20%20%2F%2F%20pin_utils%3A%3Apin_mut!\(obj\)%3B%E3%81%A7%E3%82%82%E5%8F%AF%0A%20%20%20%20let%20mut%20array%20%3D%20unsafe%20%7B%20Pin%3A%3Anew_unchecked\(%26mut%20array\)%20%7D%3B%0A%0A%20%20%20%20%2F%2F%20%E5%80%A4%E3%82%92push%E3%81%97%E3%81%A6%E3%81%BF%E3%82%8B%0A%20%20%20%20array.as_mut\(\).push\(0u32\)%3B%0A%20%20%20%20assert_eq!\(array.as_ref\(\).len\(\)%2C%201\)%3B%0A%20%20%20%20assert_eq!\(array.as_ref\(\).read\(0\)%2C%20Some\(%260u32\)\)%3B%0A%0A%20%20%20%20%2F%2F%20%E5%80%A4%E3%82%92%E6%9B%B8%E3%81%8D%E6%8F%9B%E3%81%88%E3%81%A6%E3%81%BF%E3%82%8B%0A%20%20%20%20array.as_mut\(\).write\(0%2C%201u32\)%3B%0A%20%20%20%20assert_eq!\(array.as_ref\(\).read\(0\)%2C%20Some\(%261u32\)\)%3B%0A%20%20%20%20assert_eq!\(array.as_mut\(\).pop\(\)%2C%20Some\(1u32\)\)%3B%0A%0A%20%20%20%20%2F%2F%20%E5%80%A4%E3%82%92pop%E3%81%97%E3%81%9F%E3%81%AE%E3%81%A7%E8%A6%81%E7%B4%A0%E3%81%AF%E7%A9%BA%0A%20%20%20%20assert_eq!\(array.as_ref\(\).len\(\)%2C%200\)%3B%0A%7D%0A)

### Pinのメソッド一覧

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の使い方が分かったところで、Rust 1.41時点の [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) のメソッド全てを紹介しましょう。

#### Pin::new

```rust
impl<P: Deref> Pin<P> where P::Target: Unpin {
    pub fn new(pointer: P) -> Pin<P>;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20Deref%3E%20Pin%3CP%3E%20where%20P%3A%3ATarget%3A%20Unpin%20%7B%0A%20%20%20%20pub%20fn%20new\(pointer%3A%20P\)%20-%3E%20Pin%3CP%3E%3B%0A%7D%0A)

型 `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を、 [`P::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装している場合にのみ使えるメソッドです。

新しく [`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) のインスタンスを生成します。

[`P::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装していない型（ムーブしたら絶対アカン😡型）の場合、 変数のムーブが発生し得るためこのメソッドは利用できません。

#### Pin::into\_inner

```rust
impl<P: Deref> Pin<P> where P::Target: Unpin {
    pub fn into_inner(pin: Pin<P>) -> P;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20Deref%3E%20Pin%3CP%3E%20where%20P%3A%3ATarget%3A%20Unpin%20%7B%0A%20%20%20%20pub%20fn%20into_inner\(pin%3A%20Pin%3CP%3E\)%20-%3E%20P%3B%0A%7D%0A)

型 `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を、 [`P::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装している場合にのみ使えるメソッドです。

[`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に内包している値を取り出し、ピン留めを外します。

[`P::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装していない型（ムーブしたら絶対アカン😡型）の場合、 変数のムーブが発生し得るためこのメソッドは利用できません。

#### Pin::new\_unchecked

```rust
impl<P: Deref> Pin<P> {
    pub unsafe fn new_unchecked(pointer: P) -> Pin<P>;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20Deref%3E%20Pin%3CP%3E%20%7B%0A%20%20%20%20pub%20unsafe%20fn%20new_unchecked\(pointer%3A%20P\)%20-%3E%20Pin%3CP%3E%3B%0A%7D%0A)

型 `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を実装している場合にのみ使える **不安全** メソッドです。

新しく [`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) のインスタンスを生成します。

変数がムーブしても問題ないことに実装者が責任を持つ必要があります。

#### Pin::as\_ref

```rust
impl<P: Deref> Pin<P> {
    pub fn as_ref(&self) -> Pin<&P::Target>;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20Deref%3E%20Pin%3CP%3E%20%7B%0A%20%20%20%20pub%20fn%20as_ref\(%26self\)%20-%3E%20Pin%3C%26P%3A%3ATarget%3E%3B%0A%7D%0A)

型 `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を実装している場合にのみ使えるメソッドです。

[`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に内包しているポインタ型の参照先を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んで返します。 例えば `Pin<Box<u32>>` は `Pin<&u32>` に、 `Pin<&u32>` は `Pin<&u32>` となります。 後者は `Pin<&T>` を受け取るメソッドを呼び出したいが [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の所有権を渡したくないときに使います。

このメソッドは内包する変数をムーブしないため、常に安全です。

#### Pin::into\_inner\_unchecked

```rust
impl<P: Deref> Pin<P> {
    pub unsafe fn into_inner_unchecked(pin: Pin<P>) -> P;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20Deref%3E%20Pin%3CP%3E%20%7B%0A%20%20%20%20pub%20unsafe%20fn%20into_inner_unchecked\(pin%3A%20Pin%3CP%3E\)%20-%3E%20P%3B%0A%7D%0A)

型 `P` が [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を実装している場合にのみ使える **不安全** メソッドです。

[`Pin<P>`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に内包している値を取り出し、ピン留めを外します。

変数がムーブしても問題が無いことに実装者が責任を持つ必要があります。

#### Pin::as\_mut

```rust
impl<P: DerefMut> Pin<P> {
    pub fn as_mut(&mut self) -> Pin<&mut P::Target>;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20DerefMut%3E%20Pin%3CP%3E%20%7B%0A%20%20%20%20pub%20fn%20as_mut\(%26mut%20self\)%20-%3E%20Pin%3C%26mut%20P%3A%3ATarget%3E%3B%0A%7D%0A)

型 `P` が [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) を実装している場合にのみ使えるメソッドです。

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に内包している値を可変逆参照し、再度 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んで返すメソッドです。 例えば `Pin<Box<u32>>` は `Pin<&mut u32>` となり、 `Pin<&mut u32>` は `Pin<&mut u32>` となります。 後者は `Pin<&mut T>` を受け取るメソッドを呼び出したいが [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) の所有権を渡したくないときに使います。

このメソッドは内包する変数をムーブしないため、常に安全です。

#### Pin::set

```rust
impl<P: DerefMut> Pin<P> {
    pub fn set(&mut self, value: P::Target)
    where
        P::Target: Sized;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3CP%3A%20DerefMut%3E%20Pin%3CP%3E%20%7B%0A%20%20%20%20pub%20fn%20set\(%26mut%20self%2C%20value%3A%20P%3A%3ATarget\)%0A%20%20%20%20where%0A%20%20%20%20%20%20%20%20P%3A%3ATarget%3A%20Sized%3B%0A%7D%0A)

型 `P` が [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) を実装しており、かつ [`P::Target`](https://doc.rust-lang.org/std/ops/trait.Deref.html#associatedtype.Target) のサイズが定まっている場合にのみ使えるメソッドです。

ポインタ型の中身（例えば `Box<T>` では `T` ）を `value` で置き換えます。

以前の値はその場で破棄されるため安全です。

#### Pin::map\_unchecked

```rust
impl<'a, T: ?Sized> Pin<&'a T> {
    pub unsafe fn map_unchecked<U, F>(self, func: F) -> Pin<&'a U>
    where
        F: FnOnce(&T) -> &U;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20T%3E%20%7B%0A%20%20%20%20pub%20unsafe%20fn%20map_unchecked%3CU%2C%20F%3E\(self%2C%20func%3A%20F\)%20-%3E%20Pin%3C%26%27a%20U%3E%0A%20%20%20%20where%0A%20%20%20%20%20%20%20%20F%3A%20FnOnce\(%26T\)%20-%3E%20%26U%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が参照型を保持している場合にのみ使える **不安全** メソッドです。

内部の参照型に関数を適用し、その結果を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んで返します。 主に型 `T` の保持する値（構造体のフィールドなど）を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包む際に利用します。

ただし、関数の返す参照の用法が正しく、かつムーブしないことに実装者が責任を持つ必要があります。

#### Pin::get\_ref

```rust
impl<'a, T: ?Sized> Pin<&'a T> {
    pub fn get_ref(self) -> &'a T;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20T%3E%20%7B%0A%20%20%20%20pub%20fn%20get_ref\(self\)%20-%3E%20%26%27a%20T%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が参照型を保持している場合にのみ使えるメソッドです。

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が内包する参照型を返します。 多くの場合 [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) を通して透過的に内部の値にアクセスできるため、このメソッドを使う機会はあまりないでしょう。

このメソッドは内包する変数をムーブしないため、常に安全です。

#### Pin::into\_ref

```rust
impl<'a, T: ?Sized> Pin<&'a mut T> {
    pub fn into_ref(self) -> Pin<&'a T>;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20mut%20T%3E%20%7B%0A%20%20%20%20pub%20fn%20into_ref\(self\)%20-%3E%20Pin%3C%26%27a%20T%3E%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が可変参照型を保持している場合にのみ使えるメソッドです。

所有権を奪いつつ [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) 内部の可変参照を参照にして返します。 例えば `Pin<&mut u32>` は `Pin<&u32>` となります。 代わりに [`Pin::as_ref`](https://tech-blog.optim.co.jp/entry/2020/03/05/#Pinas_ref) を使うことも検討してみてください。

このメソッドは内包する変数をムーブしないため、常に安全です。

#### Pin::get\_mut

```rust
impl<'a, T: ?Sized> Pin<&'a mut T> {
    pub fn get_mut(self) -> &'a mut T
    where
        T: Unpin;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20mut%20T%3E%20%7B%0A%20%20%20%20pub%20fn%20get_mut\(self\)%20-%3E%20%26%27a%20mut%20T%0A%20%20%20%20where%0A%20%20%20%20%20%20%20%20T%3A%20Unpin%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が可変参照型を保持しており、かつ型 `T` が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装している場合にのみ使えるメソッドです。

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が内包する可変参照型を返します。 多くの場合 [`DerefMut`](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) を通して透過的に内部の値にアクセスできるため、このメソッドを使う機会はあまりないでしょう。

ただし、型 `T` が [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装していない型（ムーブしたら絶対アカン😡型）の場合、 可変参照の使い方によっては変数のムーブが発生し得るためこのメソッドは利用できません。

#### Pin::get\_unchecked\_mut

```rust
impl<'a, T: ?Sized> Pin<&'a mut T> {
    pub unsafe fn get_unchecked_mut(self) -> &'a mut T;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20mut%20T%3E%20%7B%0A%20%20%20%20pub%20unsafe%20fn%20get_unchecked_mut\(self\)%20-%3E%20%26%27a%20mut%20T%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が可変参照を保持している場合にのみ使える **不安全** メソッドです。

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が内包する可変参照を返します。

このメソッドから返される可変参照から変数がムーブしないことに実装者が責任を持つ必要があります。

#### Pin::map\_unchecked\_mut

```rust
impl<'a, T: ?Sized> Pin<&'a mut T> {
    pub unsafe fn map_unchecked_mut<U, F>(self, func: F) -> Pin<&'a mut U>
    where
        F: FnOnce(&mut T) -> &mut U;
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=impl%3C%27a%2C%20T%3A%20%3FSized%3E%20Pin%3C%26%27a%20mut%20T%3E%20%7B%0A%20%20%20%20pub%20unsafe%20fn%20map_unchecked_mut%3CU%2C%20F%3E\(self%2C%20func%3A%20F\)%20-%3E%20Pin%3C%26%27a%20mut%20U%3E%0A%20%20%20%20where%0A%20%20%20%20%20%20%20%20F%3A%20FnOnce\(%26mut%20T\)%20-%3E%20%26mut%20U%3B%0A%7D%0A)

[`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が可変参照を保持している場合にのみ使える **不安全** メソッドです。

内部の可変参照に関数を適用し、その結果を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包んで返します。 主に型 `T` の保持する値（構造体のフィールドなど）を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包む際に利用します。

ただし、関数の返す可変参照の用法が正しく、かつムーブしないことに実装者が責任を持つ必要があります。

## Pinをうまく使うためのクレート

### pin-utils

変数をスタックでピン留めするための [`pin_mut!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.pin_mut.html)マクロ、 `self: Pin<&mut Self>` からフィールドを書き換えるための [`unsafe_unpinned!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.unsafe_unpinned.html)マクロ、 `self: Pin<&mut Self>` からフィールドを [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包むための [`unsafe_pinned!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.unsafe_pinned.html)マクロを提供します。

記事公開時点で、アルファ版である0.1.0-alpha.4がリリースされた2019/7/14以降の音沙汰がありません。 [rust-lang-nurseryグループ](https://github.com/rust-lang-nursery) にいますし、せめて正式版をリリースして欲しいのですが・・・。

### pin-project

`Pin` を安全に写像するための属性マクロなどを提供するクレート。

```rust
use std::pin::Pin;
use pin_project::{pin_project, pinned_drop, project, project_ref};

#[pin_project(PinnedDrop)]
#[derive(Debug)]
struct Foo {
    // Fooを写像した際にxをPinに包む
    #[pin]
    x: u32,
    y: u32,
}

impl Foo {
    pub fn x(self: Pin<&mut Self>) -> u32 {
        // Pin<&mut Self>で受け取ったときはprojectを使って写像する
        self.project().x()
    }

    pub fn y(self: Pin<&Self>) -> u32 {
        // Pin<&Self>で受け取ったときはproject_refを使って写像する
        self.project_ref().y()
    }
}

// project()で返るオブジェクトにimplする
#[project]
impl Foo {
    pub fn x(self) -> u32 {
        let x: Pin<&mut u32> = self.x;
        *x
    }
}

// project_ref()で返るオブジェクトにimplする
#[project_ref]
impl Foo {
    pub fn y(self) -> u32 {
        let y: &u32 = self.y;
        *self.y
    }
}

// Pin<&mut Self>を受け取るDropを実装する
#[pinned_drop]
impl PinnedDrop for Foo {
    fn drop(self: Pin<&mut Self>) {
        let this = self.project();
        println!("Foo {{ x: {}, y: {} }}", this.x, this.y);
    }
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=use%20std%3A%3Apin%3A%3APin%3B%0Ause%20pin_project%3A%3A%7Bpin_project%2C%20pinned_drop%2C%20project%2C%20project_ref%7D%3B%0A%0A%23%5Bpin_project\(PinnedDrop\)%5D%0A%23%5Bderive\(Debug\)%5D%0Astruct%20Foo%20%7B%0A%20%20%20%20%2F%2F%20Foo%E3%82%92%E5%86%99%E5%83%8F%E3%81%97%E3%81%9F%E9%9A%9B%E3%81%ABx%E3%82%92Pin%E3%81%AB%E5%8C%85%E3%82%80%0A%20%20%20%20%23%5Bpin%5D%0A%20%20%20%20x%3A%20u32%2C%0A%20%20%20%20y%3A%20u32%2C%0A%7D%0A%0Aimpl%20Foo%20%7B%0A%20%20%20%20pub%20fn%20x\(self%3A%20Pin%3C%26mut%20Self%3E\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20Pin%3C%26mut%20Self%3E%E3%81%A7%E5%8F%97%E3%81%91%E5%8F%96%E3%81%A3%E3%81%9F%E3%81%A8%E3%81%8D%E3%81%AFproject%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%A6%E5%86%99%E5%83%8F%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20self.project\(\).x\(\)%0A%20%20%20%20%7D%0A%0A%20%20%20%20pub%20fn%20y\(self%3A%20Pin%3C%26Self%3E\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20%2F%2F%20Pin%3C%26Self%3E%E3%81%A7%E5%8F%97%E3%81%91%E5%8F%96%E3%81%A3%E3%81%9F%E3%81%A8%E3%81%8D%E3%81%AFproject_ref%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%A6%E5%86%99%E5%83%8F%E3%81%99%E3%82%8B%0A%20%20%20%20%20%20%20%20self.project_ref\(\).y\(\)%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20project\(\)%E3%81%A7%E8%BF%94%E3%82%8B%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%81%ABimpl%E3%81%99%E3%82%8B%0A%23%5Bproject%5D%0Aimpl%20Foo%20%7B%0A%20%20%20%20pub%20fn%20x\(self\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20let%20x%3A%20Pin%3C%26mut%20u32%3E%20%3D%20self.x%3B%0A%20%20%20%20%20%20%20%20*x%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20project_ref\(\)%E3%81%A7%E8%BF%94%E3%82%8B%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%81%ABimpl%E3%81%99%E3%82%8B%0A%23%5Bproject_ref%5D%0Aimpl%20Foo%20%7B%0A%20%20%20%20pub%20fn%20y\(self\)%20-%3E%20u32%20%7B%0A%20%20%20%20%20%20%20%20let%20y%3A%20%26u32%20%3D%20self.y%3B%0A%20%20%20%20%20%20%20%20*self.y%0A%20%20%20%20%7D%0A%7D%0A%0A%2F%2F%20Pin%3C%26mut%20Self%3E%E3%82%92%E5%8F%97%E3%81%91%E5%8F%96%E3%82%8BDrop%E3%82%92%E5%AE%9F%E8%A3%85%E3%81%99%E3%82%8B%0A%23%5Bpinned_drop%5D%0Aimpl%20PinnedDrop%20for%20Foo%20%7B%0A%20%20%20%20fn%20drop\(self%3A%20Pin%3C%26mut%20Self%3E\)%20%7B%0A%20%20%20%20%20%20%20%20let%20this%20%3D%20self.project\(\)%3B%0A%20%20%20%20%20%20%20%20println!\(%22Foo%20%7B%7B%20x%3A%20%7B%7D%2C%20y%3A%20%7B%7D%20%7D%7D%22%2C%20this.x%2C%20this.y\)%3B%0A%20%20%20%20%7D%0A%7D%0A)

### pin-project-lite

pin-projectから基本機能のみを抜き出したもので、手続きマクロ周りのクレートに依存しないためビルドが早くなる **可能性があります** 。 大抵のプロジェクトでは手続きマクロを使ったクレートに依存しているためその恩恵は無いでしょう。

基本的にはpin-projectを使うと良いと思います。

### futures

変数をスタックでピン留めする為のマクロ [`futures::pin_mut!`](https://docs.rs/futures/0.3/futures/macro.pin_mut.html)を提供します。 このマクロは [`pin_utils::pin_mut!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.pin_mut.html)マクロを指しており、両者に機能に違いはありません。

### tokio

変数をスタックでピン留めする為のマクロ [`tokio::pin!`](https://docs.rs/tokio/0.2/tokio/macro.pin.html)を提供します。 [`pin_utils::pin_mut!`](https://docs.rs/pin-utils/0.1.0-alpha.4/pin_utils/macro.pin_mut.html)マクロとほとんど同じですが、変数を宣言する形で、そのまま変数を [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) に包むことが出来る点が異なります。

tokioを既に使っているなら、pin-utilsを使う代わりにこのマクロを使うと良いでしょう。

```rust
fn main() {
    // pin_utilsもtokioも、宣言済みの変数をスタックでピン留めする機能は同じ
    let x = 0u32;
    pin_utils::pin_mut!(x);
    // xはPin<&mut u32>

    let y = 0u32;
    tokio::pin!(y);
    // yはPin<&mut u32>

    // 加えて、tokioには変数を宣言する形でそのままPinに包む機能がある
    tokio::pin! {
        let z = 0u32;
    }
    // zはPin<&mut u32>
}
```
[Rust Playgroundで実行する](https://play.rust-lang.org/?edition=2018&code=fn%20main\(\)%20%7B%0A%20%20%20%20%2F%2F%20pin_utils%E3%82%82tokio%E3%82%82%E3%80%81%E5%AE%A3%E8%A8%80%E6%B8%88%E3%81%BF%E3%81%AE%E5%A4%89%E6%95%B0%E3%82%92%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%81%A7%E3%83%94%E3%83%B3%E7%95%99%E3%82%81%E3%81%99%E3%82%8B%E6%A9%9F%E8%83%BD%E3%81%AF%E5%90%8C%E3%81%98%0A%20%20%20%20let%20x%20%3D%200u32%3B%0A%20%20%20%20pin_utils%3A%3Apin_mut!\(x\)%3B%0A%20%20%20%20%2F%2F%20x%E3%81%AFPin%3C%26mut%20u32%3E%0A%0A%20%20%20%20let%20y%20%3D%200u32%3B%0A%20%20%20%20tokio%3A%3Apin!\(y\)%3B%0A%20%20%20%20%2F%2F%20y%E3%81%AFPin%3C%26mut%20u32%3E%0A%0A%20%20%20%20%2F%2F%20%E5%8A%A0%E3%81%88%E3%81%A6%E3%80%81tokio%E3%81%AB%E3%81%AF%E5%A4%89%E6%95%B0%E3%82%92%E5%AE%A3%E8%A8%80%E3%81%99%E3%82%8B%E5%BD%A2%E3%81%A7%E3%81%9D%E3%81%AE%E3%81%BE%E3%81%BEPin%E3%81%AB%E5%8C%85%E3%82%80%E6%A9%9F%E8%83%BD%E3%81%8C%E3%81%82%E3%82%8B%0A%20%20%20%20tokio%3A%3Apin!%20%7B%0A%20%20%20%20%20%20%20%20let%20z%20%3D%200u32%3B%0A%20%20%20%20%7D%0A%20%20%20%20%2F%2F%20z%E3%81%AFPin%3C%26mut%20u32%3E%0A%7D%0A)

## Pinは非同期プログラミングより

そもそも、 [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) は非同期プログラミングを実現するために導入されたものです。 Rust標準では、 [`Unpin`](https://doc.rust-lang.org/std/marker/trait.Unpin.html) を実装しない、つまり「ムーブしたら絶対アカン😡」オブジェクトは非同期関数の戻り値と非同期ブロックのみです。

```rust
async fn func() {}

// fもbもUnpinを実装しないオブジェクト
let f = func();
let b = async {};
```

非同期関数などの「途中で中断し、再開できる関数」はCPUでは表現できないため、 内部ではコルーチンとして表現され、その後コンパイラによってステートマシンに変換されます [\*6](https://tech-blog.optim.co.jp/entry/2020/03/05/#f-cc18f284 "現在のRustにはコルーチンはありませんが、NightlyではGeneratorトレイトと共に実装されています") 。 このステートマシンが自己参照構造体になるのです。

非同期関数をステートマシンとして表現するならばこの様なコードになるでしょう。 ただし、コンパイラによって変換される表現とは大きく異なりますし、動作するコードでもありません。

```rust
// 関数としてこう書くと・・・
async fn func() {
    // State0
    let x: u32 = 0;
    // yはxへの参照
    let y: &u32 = &x;

    // another_funcを呼び出し、待機するためのオブジェクトを得る
    let future = another_func();

    // State1
    // another_func()の実際の処理を待機する
    future.await;

    // State2
    // yは中断前の状態を引き継ぐ
    println!("{}", y);
}

// 最終的にはこのようなステートマシンになる
enum Func {
    // 関数実行前の状態
    State0,

    // another_funcを待機している状態
    State1 {
        x: u32,
        // yはxへの参照。このような構文はない
        y: &'self u32,
        // another_funcの戻り値としてのFuture
        future: AnotherFunc,
    },

    // another_funcを待機したあとの状態
    State2 {
        x: u32,
        // yはxへの参照。このような構文はない
        y: &'self u32,
    }
}

impl Future for Func {
    pub fn poll(self: Pin<&mut Self>, cx: &mut Context) -> Poll<()> {
        unsafe {
            match self.get_unchecked_mut() {
                Func::State0 => {
                    // 関数の実行を開始する
                    let x: u32 = 0;
                    let y: &u32 = &x;
                    let future = another_func();

                    // another_func()の処理を待機するために次のステップに移行する
                    *self = Func::State1 { x, y, future };
                    Poll::Pending
                }

                Func::State1 { ref mut future, .. } => {
                    // another_func()を待機する
                    match Pin::new_unchecked(future).poll(cx) {
                        Poll::Ready(()) => {
                            // another_func()の処理が終われば次のステップに移行する
                            *self = Func::State2 { x, y };
                            Poll::Pending
                        }
                        Poll::Pending => {
                            // another_func()の処理が終わってなければ次のステップに移行する
                            *self = Func::State1 { x, y, future };
                            Poll::Pending
                        }
                    }
                }

                Func::State2 { x, y } => {
                    println!("{}", y);
                    Poll::Ready(())
                }
            }
        }
    }
}
```

非同期関数を実現するためには自己参照構造体が必要であり、そのために [`Pin`](https://doc.rust-lang.org/std/pin/struct.Pin.html) が用意された、ということが分かるでしょう。

## さいごに

たかが1つの機能のためにこんなに長い記事を書くことになるとは思いもしませんでした。 Rustはなんて奥が深い言語なんだ・・・。

オプティムでは自己参照しないエンジニアを募集しています。

## 謝辞

この記事を執筆するにあたり、下記の記事を大変参考にさせていただきました。ありがとうございます。

[https://qiita.com/ubnt\_intrepid/items/df70da960b21b222d0ad](https://qiita.com/ubnt_intrepid/items/df70da960b21b222d0ad)

- 冒頭の画像中にはRust公式サイトで [配布されているロゴ](https://www.rust-lang.org/policies/media-guide) を使用しており、 このロゴはMozillaによって [CC-BY](https://creativecommons.org/licenses/by/4.0/) の下で配布されています
- 冒頭の画像は [いらすとや](https://www.irasutoya.com/) さんの画像を使っています。いつもありがとうございます