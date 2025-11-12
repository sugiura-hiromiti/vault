---
title: "RustのPinを完全に理解()するための31個のクイズ"
source: "https://hikalium.hatenablog.jp/entry/2025/01/11/021212"
author:
  - "[[hikalium]]"
published: 2025-01-11
created: 2025-11-12
description: "RustのPinって難しいですよね。 ということで、Pinのお気持ちをどれだけ理解できているか測るためのクイズを用意しました。 簡単なやつからいきますので、安心してくださいね！ いきますよ〜！ Q0 これをコンパイル・実行するとどうなる？ fn main() { let a = 3; let b = 5; println!(\"(a, b) = ({a:?}, {b:?})\"); println!(\"(a, b) = ({a:?}, {b:?})\"); } こたえ $ cargo --quiet run --example q0 (a, b) = (3, 5) (a, b) = (3, 5) 解…"
tags:
  - "clippings"
status: "unread"
aliases:
---
RustのPinって難しいですよね。

ということで、Pinのお気持ちをどれだけ理解できているか測るためのクイズを用意しました。

簡単なやつからいきますので、安心してくださいね！

いきますよ〜！

## Q0

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let a = 3;
    let b = 5;
    println!("(a, b) = ({a:?}, {b:?})");
    println!("(a, b) = ({a:?}, {b:?})");
}
```

### こたえ

```
$ cargo --quiet run --example q0
(a, b) = (3, 5)
(a, b) = (3, 5)
```

### 解説

`println!()` の動作確認です。念の為2回実行しておきました（伏線）。

## Q1

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let a = 3;
    let b = 5;
    println!("(a, b) = ({a:?}, {b:?})");
    core::mem::swap(&mut a, &mut b);
    println!("(a, b) = ({a:?}, {b:?})");
}
```

### こたえ

```
$ cargo --quiet run --example q1
error[E0596]: cannot borrow \`a\` as mutable, as it is not declared as mutable
 --> examples/q1.rs:5:21
  |
5 |     core::mem::swap(&mut a, &mut b);
  |                     ^^^^^^ cannot borrow as mutable
  |
help: consider changing this to be mutable
  |
2 |     let mut a = 3;
  |         +++

error[E0596]: cannot borrow \`b\` as mutable, as it is not declared as mutable
 --> examples/q1.rs:5:29
  |
5 |     core::mem::swap(&mut a, &mut b);
  |                             ^^^^^^ cannot borrow as mutable
  |
help: consider changing this to be mutable
  |
3 |     let mut b = 5;
  |         +++

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q1") due to 2 previous errors
```

### 解説

`core::mem::swap()` は、引数で与えられた2つの `&mut T` 型の参照がそれぞれ指している `T` 型の値を、それらを [Drop](https://d.hatena.ne.jp/keyword/Drop) することなく（つまりその値の生存期間を途切れさせることなく）メモリ上の位置を互いに交換する関数です。

あ、もちろん、 `&mut` をとるためには変数が `mut` で宣言されている必要がありますから、 [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) エラーになっているんですね。凡ミスです……。

## Q2

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let mut a = 3;
    let mut b = 5;
    println!("(a, b) = ({a:?}, {b:?})");
    core::mem::swap(&mut a, &mut b);
    println!("(a, b) = ({a:?}, {b:?})");
}
```

### こたえ

```
$ cargo --quiet run --example q2
(a, b) = (3, 5)
(a, b) = (5, 3)
```

### 解説

ということで `mut` をaとbの宣言時につけてあげたらいい感じに通りました。値もちゃんと入れ替わっていますね。想定通りです！

## Q3

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let mut a = 3;
    let mut b = 5;
    println!("(a, b) @ ({0:p}, {1:p}) = ({0:?}, {1:?})", &mut a, &mut b);
    core::mem::swap(&mut a, &mut b);
    println!("(a, b) @ ({0:p}, {1:p}) = ({0:?}, {1:?})", &mut a, &mut b);
}
```

### こたえ

```
$ cargo --quiet run --example q3
(a, b) @ (0x7ffc101d53d0, 0x7ffc101d53d4) = (3, 5)
(a, b) @ (0x7ffc101d53d0, 0x7ffc101d53d4) = (5, 3)
```

### 解説

値が入れ替わっても、それぞれの変数が占めるメモリ上の位置は変わりません。あくまでも、それぞれの値が入れ替わっただけです。

それを確かめるべく、各変数のアドレスを取得して表示しています。たしかにswapの前後でaとbのアドレスは変化していませんね。しかし、値だけが入れ替わっています。 つまり、aとbのメモリ上の位置は同一だけれども、その値だけが入れ替わったというわけです。

## Q4

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let mut a = 3;
    let mut b = 5;
    let a = &mut a;
    let b = &mut b;
    println!("(a, b) @ ({0:p}, {1:p}) = ({0:?}, {1:?})", a, b);
    core::mem::swap(a, b);
    println!("(a, b) @ ({0:p}, {1:p}) = ({0:?}, {1:?})", a, b);
}
```

### こたえ

```
$ cargo --quiet run --example q4
(a, b) @ (0x7ffee3f429c0, 0x7ffee3f429c4) = (3, 5)
(a, b) @ (0x7ffee3f429c0, 0x7ffee3f429c4) = (5, 3)
```

### 解説

なんか `&mut` っていっぱいあってだるかったので、変数に代入しておきました。これで何回も `&mut` `&mut` しなくて済みます。

ちなみに、Rustでは同じ名前の変数を同一スコープ内で再定義(let)でき、古いものは隠蔽(shadowing)されます。

c.f. [https://doc.rust-lang.org/rust-by-example/variable\_bindings/scope.html](https://doc.rust-lang.org/rust-by-example/variable_bindings/scope.html)

私はこの仕様、好きです。行がチェーンで長くなりすぎたときに、letをいっぱい縦に並べることがあります。 あと、temporally [value](https://d.hatena.ne.jp/keyword/value) dropped 的なエラーが出るときは、 [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さんがそうすることをおすすめしてくれたりします。

まあ、これを許さない言語もいるので、初見だとびっくりするかもですが、慣れましょう！

## Q5

### これをコンパイル・実行するとどうなる？

```
fn main() {
    let mut a = 3;
    let mut b = 5;
    let a = &mut a;
    let b = &mut b;
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a, b);
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
}
```

### こたえ

```
$ cargo --quiet run --example q5
(a, b) @ (0x7ffc887a82b0, 0x7ffc887a82b4) = (3, 5)
(a, b) @ (0x7ffc887a82b0, 0x7ffc887a82b4) = (5, 3)
```

### 解説

そういえば `println!()` の変数指定はそのスコープから見える変数名でも書けるので、書き換えときました。特に動作上は変化なしです。

## Q6

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a, b);
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
}
```

### こたえ

```
$ cargo --quiet run --example q6
a: u8
b: u8
(a, b) @ (0x7ffe385b3086, 0x7ffe385b3087) = (3, 5)
(a, b) @ (0x7ffe385b3086, 0x7ffe385b3087) = (5, 3)
```

### 解説

type\_name\_of\_val()を使うと、その参照が指し示す値の型を [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) 時文字列にできます。 [デバッグ](https://d.hatena.ne.jp/keyword/%A5%C7%A5%D0%A5%C3%A5%B0) に便利です。 あと、aとbに代入する値をu8型である、と明確にsuffixで示しました。この結果、aとbのアドレスの差が、さきほどは4バイトだったのが1バイトになっていますね。 まあ、今のところはただの構文紹介です。

## Q7

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a, b);
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q7
a: u8
b: u8
a: &mut u8
b: &mut u8
(a, b) @ (0x7fff4d30afa6, 0x7fff4d30afa7) = (3, 5)
(a, b) @ (0x7fff4d30afa6, 0x7fff4d30afa7) = (5, 3)
a: &mut u8
b: &mut u8
```

### 解説

一応参照をとった後とか、プログラムの最後のときの型も表示しておきました。ちゃんと参照になってますね。わかりやすい。

## Q8

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::pin::Pin;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = Pin::new(a);
    let b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a, b);
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q8
error[E0308]: arguments to this function are incorrect
  --> examples/q8.rs:18:5
   |
18 |     core::mem::swap(a, b);
   |     ^^^^^^^^^^^^^^^
   |
note: expected \`&mut _\`, found \`Pin<&mut u8>\`
  --> examples/q8.rs:18:21
   |
18 |     core::mem::swap(a, b);
   |                     ^
   = note: expected mutable reference \`&mut _\`
                         found struct \`Pin<&mut u8>\`
note: expected \`&mut _\`, found \`Pin<&mut u8>\`
  --> examples/q8.rs:18:24
   |
18 |     core::mem::swap(a, b);
   |                        ^
   = note: expected mutable reference \`&mut _\`
                         found struct \`Pin<&mut u8>\`
note: function defined here
  --> /rustc/9fc6b43126469e3858e2fe86cafb4f0fd5068869/library/core/src/mem/mod.rs:732:14
help: consider mutably borrowing here
   |
18 |     core::mem::swap(&mut a, b);
   |                     ++++
help: consider mutably borrowing here
   |
18 |     core::mem::swap(a, &mut b);
   |                        ++++

For more information about this error, try \`rustc --explain E0308\`.
error: could not compile \`pinquiz\` (example "q8") due to 1 previous error
```

### 解説

さて本題のPinです。PinにはPin::newメソッドがあり、さらにPinはポインタに相当する型を内包するので、 `&mut u8` にかぶせてみたらどうなるのかな？と雑に試した結果、 [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さんにだめって言われちゃいました。 えーっとね…あー、Pinでくるんだ `Pin<&mut u8>` は `&mut なんとか` の形の型ではないので、swapには使えないですよ〜って言われてますね。

でも、安心してください。Pinはポインタと同等の振る舞いをする [インターフェイス](https://d.hatena.ne.jp/keyword/%A5%A4%A5%F3%A5%BF%A1%BC%A5%D5%A5%A7%A5%A4%A5%B9) がついているので、適当にそれを呼んであげればよさそうです。

こういうときは、borrow\_mut()してあげれば、&mutな何かがもらえるはずです。やってみましょう。

## Q9

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = Pin::new(a);
    let b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q9
error[E0596]: cannot borrow \`a\` as mutable, as it is not declared as mutable
  --> examples/q9.rs:19:21
   |
19 |     core::mem::swap(a.borrow_mut(), b.borrow_mut());
   |                     ^ cannot borrow as mutable
   |
help: consider changing this to be mutable
   |
14 |     let mut a = Pin::new(a);
   |         +++

error[E0596]: cannot borrow \`b\` as mutable, as it is not declared as mutable
  --> examples/q9.rs:19:37
   |
19 |     core::mem::swap(a.borrow_mut(), b.borrow_mut());
   |                                     ^ cannot borrow as mutable
   |
help: consider changing this to be mutable
   |
15 |     let mut b = Pin::new(b);
   |         +++

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q9") due to 2 previous errors
```

### 解説

あー、おしい。borrow\_mut()を呼ぶためには、Pin<&mut u8>を保持している変数がmutじゃないといけないんですね。つけてあげましょう！

## Q10

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q10
a: u8
b: u8
a: &mut u8
b: &mut u8
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
(a, b) @ (0x7ffeae1e3df6, 0x7ffeae1e3df7) = (3, 5)
(a, b) @ (0x7ffeae1e3df7, 0x7ffeae1e3df6) = (5, 3)
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
```

### 解説

おー、無事に通りました！これでめでたく、Pin<&mut u8>の中身が…え、入れ替わってるぅ…？というか、中身だけじゃなくて、変数自体も入れ替わってるよ…なんでぇ…？

…おちついてください、これはなにかの間違いです。どうして入れ替わっちゃったのか、明日までに考えてきてください。いいね？

## Q11

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<u8>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q11
a: u8
b: u8
a: &mut u8
b: &mut u8
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
(a, b) @ (0x7ffef9e58106, 0x7ffef9e58107) = (3, 5)
(a, b) @ (0x7ffef9e58106, 0x7ffef9e58107) = (5, 3)
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
```

### 解説

あー、なるほどね、swapの操作をu8に関して行うようにしたら、変数のアドレスは入れ変わらなくなりました。要するに、さきほどはPin<&mut u8>に関するswapをしていたので、ポインタ自体丸ごと入れ替わっちゃったんですね…borrow\_mut()はどこの型についてmutableなborrowをするのか任意性があるので、こういうことが起きちゃうわけです。気をつけましょう。

…でも、やっぱり値は入れ替わっちゃいますね。Pinしてたら入れ替わらないんじゃなかったっけ…？

## Q12

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = 3u8;
    let mut b = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<Pin<&mut u8>>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q12
a: u8
b: u8
a: &mut u8
b: &mut u8
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
(a, b) @ (0x7fffcf215c96, 0x7fffcf215c97) = (3, 5)
(a, b) @ (0x7fffcf215c97, 0x7fffcf215c96) = (5, 3)
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
```

### 解説

これは先程の仮説の検証で、今度はu8ではなくPin<&mut \>に関するswapをがんばってもらった図です。確かにswap時の型を指定しなかった場合と同様、アドレスレベルで入れ替わってますよね。

## Q13

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = (3u8, ());
    let mut b = (5u8, ());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<(u8, ())>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q13
a: (u8, ())
b: (u8, ())
a: &mut (u8, ())
b: &mut (u8, ())
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
(a, b) @ (0x7ffd2079bf96, 0x7ffd2079bf97) = ((3, ()), (5, ()))
(a, b) @ (0x7ffd2079bf96, 0x7ffd2079bf97) = ((5, ()), (3, ()))
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
```

### 解説

さて、話を少し戻して、今度はPinの指す先をswapするように戻したうえで、u8型の代わりに `(u8, ())` 型、つまりu8とunit typeのタプルを入れ替える操作をやってみました。

やっぱり通っちゃいますね…Pin…どうして…

## Q14

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    let mut a = (3u8, Default::default());
    let mut b = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<(u8, ())>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q14
a: (u8, ())
b: (u8, ())
a: &mut (u8, ())
b: &mut (u8, ())
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
(a, b) @ (0x7ffc42f7d676, 0x7ffc42f7d677) = ((3, ()), (5, ()))
(a, b) @ (0x7ffc42f7d676, 0x7ffc42f7d677) = ((5, ()), (3, ()))
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
```

### 解説

ここは小休止、Default::default()っていう便利なやつの紹介です。これは、Defaultトレイトのdefaultメソッドを呼び出すという意味になるので、書いた場所の型がDefaultを実装していたら、めでたくデフォルトの値を入れてくれるという便利な子です。 [ジェネリクス](https://d.hatena.ne.jp/keyword/%A5%B8%A5%A7%A5%CD%A5%EA%A5%AF%A5%B9) とかと相性がいいですよ。 unit typeの()のデフォルト値は()ですから（いいですか、前者が型の()で、後者が値の()です…よく見てください（大丈夫、同じ文字列です））

[https://doc.rust-lang.org/std/primitive.unit.html](https://doc.rust-lang.org/std/primitive.unit.html)

## Q15

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    type T = (u8, ());
    let mut a = (3u8, Default::default());
    let mut b = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q15
a: (u8, ())
b: (u8, ())
a: &mut (u8, ())
b: &mut (u8, ())
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
(a, b) @ (0x7ffcdaddd2c6, 0x7ffcdaddd2c7) = ((3, ()), (5, ()))
(a, b) @ (0x7ffcdaddd2c6, 0x7ffcdaddd2c7) = ((5, ()), (3, ()))
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
```

### 解説

これ [もリフ](https://d.hatena.ne.jp/keyword/%A4%E2%A5%EA%A5%D5) ァクタリングで、(u8, ())って毎度書くのがだるいので、type T =... という形で型の別名定義をしました。それ以上の深い理由はありません（ここで目をそらす…）

## Q16

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::Pin;

fn main() {
    type T = (u8, PhantomPinned);
    let mut a = (3u8, Default::default());
    let mut b = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = Pin::new(a);
    let mut b = Pin::new(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q16
error[E0277]: \`PhantomPinned\` cannot be unpinned
  --> examples/q16.rs:16:26
   |
16 |     let mut a = Pin::new(a);
   |                 -------- ^ within \`(u8, PhantomPinned)\`, the trait \`Unpin\` is not implemented for \`PhantomPinned\`
   |                 |
   |                 required by a bound introduced by this call
   |
   = note: consider using the \`pin!\` macro
           consider using \`Box::pin\` if you need to access the pinned value outside of the current scope
   = note: required because it appears within the type \`(u8, PhantomPinned)\`
note: required by a bound in \`Pin::<Ptr>::new\`
  --> /rustc/9fc6b43126469e3858e2fe86cafb4f0fd5068869/library/core/src/pin.rs:1191:5

error[E0277]: \`PhantomPinned\` cannot be unpinned
  --> examples/q16.rs:17:26
   |
17 |     let mut b = Pin::new(b);
   |                 -------- ^ within \`(u8, PhantomPinned)\`, the trait \`Unpin\` is not implemented for \`PhantomPinned\`
   |                 |
   |                 required by a bound introduced by this call
   |
   = note: consider using the \`pin!\` macro
           consider using \`Box::pin\` if you need to access the pinned value outside of the current scope
   = note: required because it appears within the type \`(u8, PhantomPinned)\`
note: required by a bound in \`Pin::<Ptr>::new\`
  --> /rustc/9fc6b43126469e3858e2fe86cafb4f0fd5068869/library/core/src/pin.rs:1191:5

For more information about this error, try \`rustc --explain E0277\`.
error: could not compile \`pinquiz\` (example "q16") due to 2 previous errors
```

### 解説

すいません、伏線でした。いままでタプルの右側の型は()でしたが、今度はPhantomPinnedとかいう謎の型になっています。

[https://doc.rust-lang.org/std/marker/struct.PhantomPinned.html](https://doc.rust-lang.org/std/marker/struct.PhantomPinned.html)

こいつがPinの世界における鍵のひとつです。…ひとつであって全てではありません。悲しいね！ まあ端的にいうと、この子はUnpinトレイトを実装していない型です。（ [否定の否定](https://d.hatena.ne.jp/keyword/%C8%DD%C4%EA%A4%CE%C8%DD%C4%EA) 、頭がこんがらかるね、よくない…）

[https://doc.rust-lang.org/std/marker/trait.Unpin.html](https://doc.rust-lang.org/std/marker/trait.Unpin.html)

まあ詳細は省きますが、上のエラーが言っていることを解説すると、Pin::newはUnpinを実装している型を引数にとるが、いま渡されている値はUnpinを実装しない型だから呼び出せないぞ！っていうことです。

実際、Pin::newの定義を見に行くと、そう書いてあります。

[https://doc.rust-lang.org/src/core/pin.rs.html#1169](https://doc.rust-lang.org/src/core/pin.rs.html#1169)

```
impl<Ptr: Deref<Target: Unpin>> Pin<Ptr> {
...
    pub const fn new(pointer: Ptr) -> Pin<Ptr> {
        // SAFETY: the value pointed to is \`Unpin\`, and so has no requirements
        // around pinning.
        unsafe { Pin::new_unchecked(pointer) }
    }
```

ね？じゃあなぜ今までエラーが出てなかったのかというと、Unpinトレイトってやつが自動的に実装されるやばいトレイトだからです。

…まあ別にやばくはないんですが、基本的にどの型も構造体も、その内部にUnpinトレイトを実装しない型が含まれていなければ、Unpinトレイトが実装されるのです。

…えーっと、言い換えれば、ある型のすべてのメンバがUnpinトレイトを実装していれば、そのようなメンバからなる型もUnpinトレイトが実装されるのです。

そう、あなたがタプルを作ったりstructを作ったりしているとき、たいていのばあい、Unpinトレイトが実装されるのです。気づいていましたか？（通常は気にしなくていい。通常は、ね…）

ま、結論をいうと、Unpinトレイトが実装されていない奇妙な型 PhantomPinnedを含むようにタプルを書き換えた結果、そのタプルもUnpinトレイトが実装されなくなってしまい、Pin::new()を呼び出す資格なしと [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さんに言われてしまったわけです。でも、どうしてPinはそんな制限をかけてるんですかねえ…（すっとぼけ）

まあいいや、なんか [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さん曰く"note: consider using the `pin!` macro", 要するにpin!()マクロ使えってことらしいので、それ使ってみましょう！

（よい子のみんなは、 [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さんの言っていることを素直に受け止めるのもいいけれど、ドキュメントもちらっと見ておくといいぞ！今回は話の都合上、私は素通りしますが…（だめですよ！））

[https://doc.rust-lang.org/std/pin/macro.pin.html](https://doc.rust-lang.org/std/pin/macro.pin.html)

## Q17

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::pin;

fn main() {
    type T = (u8, PhantomPinned);
    let mut a = (3u8, Default::default());
    let mut b = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = &mut a;
    let b = &mut b;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q17
a: (u8, core::marker::PhantomPinned)
b: (u8, core::marker::PhantomPinned)
a: &mut (u8, core::marker::PhantomPinned)
b: &mut (u8, core::marker::PhantomPinned)
a: core::pin::Pin<&mut &mut (u8, core::marker::PhantomPinned)>
b: core::pin::Pin<&mut &mut (u8, core::marker::PhantomPinned)>
(a, b) @ (0x7fff54dd76f0, 0x7fff54dd7700) = ((3, PhantomPinned), (5, PhantomPinned))
(a, b) @ (0x7fff54dd76f0, 0x7fff54dd7700) = ((5, PhantomPinned), (3, PhantomPinned))
a: core::pin::Pin<&mut &mut (u8, core::marker::PhantomPinned)>
b: core::pin::Pin<&mut &mut (u8, core::marker::PhantomPinned)>
```

### 解説

やった〜！ [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) 通った〜！なんかpin!()マクロをPin::new()の代わりに使ったら通っちゃった〜

…いや、通らないでほしかったんだけど…なんで…

あ、型を冷静に見てみましょう。 `core::pin::Pin<&mut &mut (u8, core::marker::PhantomPinned)>` とかいう奇妙な型になってますね。二重の参照をPinでくるんでいるという…なかなかワイルドな型です。

そうか、pin!()マクロに渡すのは参照ではなく、Pinが指すべき値を突っ込むべきなんですね〜おーけー、じゃあ&mutとってる部分消しましょか…

## Q18

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::pin;

fn main() {
    type T = (u8, PhantomPinned);
    let a = (3u8, Default::default());
    let b = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q18
error[E0596]: cannot borrow data in dereference of \`Pin<&mut (u8, PhantomPinned)>\` as mutable
  --> examples/q18.rs:17:26
   |
17 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<&mut (u8, PhantomPinned)>\`

error[E0596]: cannot borrow data in dereference of \`Pin<&mut (u8, PhantomPinned)>\` as mutable
  --> examples/q18.rs:17:42
   |
17 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<&mut (u8, PhantomPinned)>\`

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q18") due to 2 previous errors
```

### 解説

消したらまた [コンパイラ](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%E9) さんがだめだって言ってます。にゃーん…。

えっと、DerefMutがPin<&mut(u8, PhantomPinned)>にないって言われちゃいました。えー…さっきは似たようなやつで通ってたのに…

いえ、これで正しいんです。Pin型にDerefMutが実装される条件は、

```
impl<Ptr> DerefMut for Pin<Ptr>
where
    Ptr: DerefMut,
    <Ptr as Deref>::Target: Unpin,
```

というわけで、 `Pin<Ptr>の<Ptr as Deref>::Target` がUnpinを実装している場合のみなので、PhantomPinnedさんが入ってきてUnpinトレイトが実装されなくなったので、私達はもうDerefMutを呼び出す資格を失ってしまったのです。

これこそが、Pinがいかに値のmoveを抑制するのか、の具体例です。Unpinトレイトを実装していない型を指すようなポインタ型PtrをくるむPin 型があったとき、その内部への可変参照を取得できないようにしてあげることで、swapなどをはじめとした、値のmoveを行いかねない行動をunsafeなものとして制限しているのです。

## Q19

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::marker::PhantomPinned;
use std::pin::pin;

fn main() {
    type T = (u8, PhantomPinned);
    let a: T = (3u8, Default::default());
    let b: T = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let a = pin!(a);
    let b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    //core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q19
a: (u8, core::marker::PhantomPinned)
b: (u8, core::marker::PhantomPinned)
a: core::pin::Pin<&mut (u8, core::marker::PhantomPinned)>
b: core::pin::Pin<&mut (u8, core::marker::PhantomPinned)>
(a, b) @ (0x7ffce402b167, 0x7ffce402b177) = ((3, PhantomPinned), (5, PhantomPinned))
(a, b) @ (0x7ffce402b167, 0x7ffce402b177) = ((3, PhantomPinned), (5, PhantomPinned))
a: core::pin::Pin<&mut (u8, core::marker::PhantomPinned)>
b: core::pin::Pin<&mut (u8, core::marker::PhantomPinned)>
```

### 解説

そういうわけで、ひとつ前の [ソースコード](https://d.hatena.ne.jp/keyword/%A5%BD%A1%BC%A5%B9%A5%B3%A1%BC%A5%C9) のswapを [コメントアウト](https://d.hatena.ne.jp/keyword/%A5%B3%A5%E1%A5%F3%A5%C8%A5%A2%A5%A6%A5%C8) してあげれば、このコードは [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) できるようになります。

可変参照を防げたバンザイ！Pinで値の安住の地が約束された！やった〜

…安住の地を得るのはこんなにも難しいものなのです。ええ。Unpinを外し忘れると、余裕で引っ越しを迫られるわけです。気をつけましょうね…。

## Q20

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::pin;

fn main() {
    type T = (u8, PhantomPinned);
    let a: T = (3u8, Default::default());
    let b: T = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q20
error[E0596]: cannot borrow data in dereference of \`Pin<&mut (u8, PhantomPinned)>\` as mutable
  --> examples/q20.rs:17:26
   |
17 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<&mut (u8, PhantomPinned)>\`

error[E0596]: cannot borrow data in dereference of \`Pin<&mut (u8, PhantomPinned)>\` as mutable
  --> examples/q20.rs:17:42
   |
17 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<&mut (u8, PhantomPinned)>\`

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q20") due to 2 previous errors
```

### 解説

今一度、Pinがswapの立ち退き要求を跳ね返す様をご覧にいれましょう。よく目に焼き付けておいてくださいね…。

## Q21

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::pin;

fn main() {
    type T = (u8, ());
    let a: T = (3u8, Default::default());
    let b: T = (5u8, Default::default());
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q21
a: (u8, ())
b: (u8, ())
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
(a, b) @ (0x7fff4131c4b7, 0x7fff4131c4c7) = ((3, ()), (5, ()))
(a, b) @ (0x7fff4131c4b7, 0x7fff4131c4c7) = ((5, ()), (3, ()))
a: core::pin::Pin<&mut (u8, ())>
b: core::pin::Pin<&mut (u8, ())>
```

### 解説

復習ですが、PhantomPinnedを()に書き換えると、確かに [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) が通ってswapできてしまいます。PhantomPinnedはだいじに身に着けておきましょう。

## Q22

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::pin;

fn main() {
    type T = u8;
    let a: T = 3u8;
    let b: T = 5u8;
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q22
a: u8
b: u8
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
(a, b) @ (0x7ffca8478dd7, 0x7ffca8478de7) = (3, 5)
(a, b) @ (0x7ffca8478dd7, 0x7ffca8478de7) = (5, 3)
a: core::pin::Pin<&mut u8>
b: core::pin::Pin<&mut u8>
```

### 解説

そういえばしばらくタプルで説明していましたが、もちろんu8そのままの値でも同様の挙動になります。再確認です。

## Q23

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::pin;

fn main() {
    type T = Box<u8>;
    let a: T = Box::new(3u8);
    let b: T = Box::new(5u8);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q23
a: alloc::boxed::Box<u8>
b: alloc::boxed::Box<u8>
a: core::pin::Pin<&mut alloc::boxed::Box<u8>>
b: core::pin::Pin<&mut alloc::boxed::Box<u8>>
(a, b) @ (0x7ffdbbe735d8, 0x7ffdbbe735e8) = (3, 5)
(a, b) @ (0x7ffdbbe735d8, 0x7ffdbbe735e8) = (5, 3)
a: core::pin::Pin<&mut alloc::boxed::Box<u8>>
b: core::pin::Pin<&mut alloc::boxed::Box<u8>>
```

### 解説

さて、&mutをPinでくるんだときの挙動はわかりましたが、Pinがくるむことのできる「ポインタ型」は&や&mutに限りません。 Box という、ヒープ上にメモリを確保してそこに対するポインタを保持する型も、Pinでくるむことができます。

ただ、雑にpin!()マクロにBox型を渡してしまうと、&mutが余計についてしまいます。これでは、Pinの効果が発揮できません。

## Q24

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::pin;

fn main() {
    type T = Box<(u8, PhantomPinned)>;
    let a: T = Box::new((3u8, Default::default()));
    let b: T = Box::new((5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    let mut a = pin!(a);
    let mut b = pin!(b);
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q24
a: alloc::boxed::Box<(u8, core::marker::PhantomPinned)>
b: alloc::boxed::Box<(u8, core::marker::PhantomPinned)>
a: core::pin::Pin<&mut alloc::boxed::Box<(u8, core::marker::PhantomPinned)>>
b: core::pin::Pin<&mut alloc::boxed::Box<(u8, core::marker::PhantomPinned)>>
(a, b) @ (0x7ffc58ed5198, 0x7ffc58ed51a8) = ((3, PhantomPinned), (5, PhantomPinned))
(a, b) @ (0x7ffc58ed5198, 0x7ffc58ed51a8) = ((5, PhantomPinned), (3, PhantomPinned))
a: core::pin::Pin<&mut alloc::boxed::Box<(u8, core::marker::PhantomPinned)>>
b: core::pin::Pin<&mut alloc::boxed::Box<(u8, core::marker::PhantomPinned)>>
```

### 解説

実際、この状況で()をPhantomPinnedに書き換えても、Pinの効果は発動しません。これは、 `core::pin::Pin<&mut alloc::boxed::Box<(u8, core::marker::PhantomPinned)>>` を注意深く見ていただければわかるのですが、Pin<ポインタ型<ポインタ型<(値)>>>という構造になっているため、Pinでくるまれた直下のポインタのTarget(=alloc::boxed::Box<(u8, core::marker::PhantomPinned)>)はUnpinを実装している型であるために、Pinの保護効果が発生しないのです。だから、Boxに対してpinをしたいときは、 [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) が通るからと言ってBoxしてpin!するのではなく、Box::pin()という専用のメソッドがあるので、そちらを利用すると&mutが挟まるのを回避でき、めでたくPin直下のポインタのTarget(=(u8, core::marker::PhantomPinned))がUnpinを実装していない型になるので、うまく効果が発動するようになります（次の問題を参照）

## Q25

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::pin::Pin;

fn main() {
    type T = (u8, PhantomPinned);
    let mut a: Pin<Box<T>> = Box::pin((3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin((5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q25
error[E0596]: cannot borrow data in dereference of \`Pin<Box<(u8, PhantomPinned)>>\` as mutable
  --> examples/q25.rs:13:26
   |
13 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<Box<(u8, PhantomPinned)>>\`

error[E0596]: cannot borrow data in dereference of \`Pin<Box<(u8, PhantomPinned)>>\` as mutable
  --> examples/q25.rs:13:42
   |
13 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<Box<(u8, PhantomPinned)>>\`

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q25") due to 2 previous errors
```

### 解説

ほら、DerefMutが実装されてないよ〜と言われて弾かれています。正しく使えば正しく [コンパイル](https://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) エラーにしてくれるんです、Pinは。

## Q26

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

fn main() {
    type T = (u8, ());
    let mut a: Pin<Box<T>> = Box::pin((3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin((5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q26
a: core::pin::Pin<alloc::boxed::Box<(u8, ())>>
b: core::pin::Pin<alloc::boxed::Box<(u8, ())>>
(a, b) @ (0x562a3fab3b10, 0x562a3fab3b30) = ((3, ()), (5, ()))
(a, b) @ (0x562a3fab3b10, 0x562a3fab3b30) = ((5, ()), (3, ()))
a: core::pin::Pin<alloc::boxed::Box<(u8, ())>>
b: core::pin::Pin<alloc::boxed::Box<(u8, ())>>
```

### 解説

もちろん、Boxを使っていても、Boxの指す先がUnpinを実装している型だったら、DerefMutできちゃいますからね。気をつけてください。

…やっぱりPinって名前が悪いよ！ `PinPtrTargetIfItDoesNotImplUnpin` とかにしたほうがいいって…（ [Objective-C](https://d.hatena.ne.jp/keyword/Objective-C) 的長い名前推進過激派）

## Q27

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::pin::Pin;

#[derive(Debug)]
#[allow(unused)]
struct Wrapper(u8, ());

fn main() {
    type T = Wrapper;
    let mut a: Pin<Box<T>> = Box::pin(Wrapper(3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin(Wrapper(5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q27
a: core::pin::Pin<alloc::boxed::Box<q27::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q27::Wrapper>>
(a, b) @ (0x55e937e0ab10, 0x55e937e0ab30) = (Wrapper(3, ()), Wrapper(5, ()))
(a, b) @ (0x55e937e0ab10, 0x55e937e0ab30) = (Wrapper(5, ()), Wrapper(3, ()))
a: core::pin::Pin<alloc::boxed::Box<q27::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q27::Wrapper>>
```

### 解説

あと、メンバが全員Unpinトレイトを実装している場合にUnpinトレイトが自動実装されるよって話は、自前でstructを定義した際にも **もちろん** 適用されます。Unpin by default, いいね？（つまり、Pin is no op by default, いいね？（つらい））

## Q28

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::ops::Drop;
use std::pin::Pin;

#[derive(Debug)]
#[allow(unused)]
struct Wrapper(u8, ());
impl Drop for Wrapper {
    fn drop(&mut self) {
        println!("dropped: {self:?} @ {self:p}")
    }
}

fn main() {
    type T = Wrapper;
    let mut a: Pin<Box<T>> = Box::pin(Wrapper(3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin(Wrapper(5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q28
a: core::pin::Pin<alloc::boxed::Box<q28::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q28::Wrapper>>
(a, b) @ (0x55e69849fb10, 0x55e69849fb30) = (Wrapper(3, ()), Wrapper(5, ()))
(a, b) @ (0x55e69849fb10, 0x55e69849fb30) = (Wrapper(5, ()), Wrapper(3, ()))
a: core::pin::Pin<alloc::boxed::Box<q28::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q28::Wrapper>>
dropped: Wrapper(3, ()) @ 0x55e69849fb30
dropped: Wrapper(5, ()) @ 0x55e69849fb10
```

### 解説

ちなみにこうやって自分で構造体に [Drop](https://d.hatena.ne.jp/keyword/Drop) を実装してあげれば、その値の生存期間を知ることができるわけですが、swapはメモリ上を移動するのに生存期間は終わらないんですよ。まあ、そういうことになっているからそうなんですが、そうなんですよ。変数が生存しているからと言って、ずっと同じメモリアドレスにいると思ったら大間違いなんですね。みなさんも目が覚めたら突然知らない天井を見上げることになるかもしれないんです。多くの人はそんな可能性を検討していないかもしれませんが。気をつけてね！

## Q29

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::ops::Drop;
use std::pin::Pin;

#[derive(Debug)]
#[allow(unused)]
struct Wrapper(u8, PhantomPinned);
impl Drop for Wrapper {
    fn drop(&mut self) {
        println!("dropped: {self:?} @ {self:p}")
    }
}

fn main() {
    type T = Wrapper;
    let mut a: Pin<Box<T>> = Box::pin(Wrapper(3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin(Wrapper(5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q29
error[E0596]: cannot borrow data in dereference of \`Pin<Box<Wrapper>>\` as mutable
  --> examples/q29.rs:23:26
   |
23 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<Box<Wrapper>>\`

error[E0596]: cannot borrow data in dereference of \`Pin<Box<Wrapper>>\` as mutable
  --> examples/q29.rs:23:42
   |
23 |     core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
   |                                          ^^^^^^^^^^^^^^ cannot borrow as mutable
   |
   = help: trait \`DerefMut\` is required to modify through a dereference, but it is not implemented for \`Pin<Box<Wrapper>>\`

For more information about this error, try \`rustc --explain E0596\`.
error: could not compile \`pinquiz\` (example "q29") due to 2 previous errors
```

### 解説

もちろん、自前で定義した構造体のメンバの一部がUnpinを実装しない子(e.g. PhantomPinned)だったら、Unpinは実装されません。なので、PinしたいオブジェクトにはPhantomPinnedを含めてあげればよいです。

…でもね、

## Q30

### これをコンパイル・実行するとどうなる？

```
use std::any::type_name_of_val;
use std::borrow::BorrowMut;
use std::marker::PhantomPinned;
use std::ops::Drop;
use std::pin::Pin;

#[derive(Debug)]
#[allow(unused)]
struct Wrapper(u8, PhantomPinned);
impl Drop for Wrapper {
    fn drop(&mut self) {
        println!("dropped: {self:?} @ {self:p}")
    }
}
impl Unpin for Wrapper {}

fn main() {
    type T = Wrapper;
    let mut a: Pin<Box<T>> = Box::pin(Wrapper(3u8, Default::default()));
    let mut b: Pin<Box<T>> = Box::pin(Wrapper(5u8, Default::default()));
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    core::mem::swap::<T>(a.borrow_mut(), b.borrow_mut());
    println!("(a, b) @ ({a:p}, {b:p}) = ({a:?}, {b:?})");
    println!("a: {}", type_name_of_val(&a));
    println!("b: {}", type_name_of_val(&b));
}
```

### こたえ

```
$ cargo --quiet run --example q30
a: core::pin::Pin<alloc::boxed::Box<q30::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q30::Wrapper>>
(a, b) @ (0x556d228dcb10, 0x556d228dcb30) = (Wrapper(3, PhantomPinned), Wrapper(5, PhantomPinned))
(a, b) @ (0x556d228dcb10, 0x556d228dcb30) = (Wrapper(5, PhantomPinned), Wrapper(3, PhantomPinned))
a: core::pin::Pin<alloc::boxed::Box<q30::Wrapper>>
b: core::pin::Pin<alloc::boxed::Box<q30::Wrapper>>
dropped: Wrapper(3, PhantomPinned) @ 0x556d228dcb30
dropped: Wrapper(5, PhantomPinned) @ 0x556d228dcb10
```

### 解説

`impl Unpin for Wrapper {}` ってやるのはsafeなんですよ。これをやってしまえば、その中にPhantomPinnedがいようがいまいが、Pinの保護機構は働かないのです。

## あとがき

こんなことをしている場合ではなかった。でも、Pinがその名前やドキュメント上の解説からは読み取りづらい挙動をしているのは事実で、しかも基本的に非常によくできていて過去の失敗をいい感じに回避してきたRustという言語の中でも、互換性とか歴史的事情とか諸々の要因でこんな辛い部分があるのは、現実ってしょっぱいね、という気持ちを新たにさせてくれる、いい機会だったと思う。

もうちょっと頭の中が整理されたら、ドキュメントとか、もしくはPin自体の改善提案をできたらいいなあと思いつつ、勢いで書き上げてしまったのでインターネットに放流します。 積んでるタスクが片付いたら、また戻ってきたいですね。

ということで、Pinは用法用量を守って正しくお使いください。

## 参考

[github.com](https://github.com/hikalium/pinquiz)

[github.com](https://github.com/rust-lang/rust/pull/133489)

![](https://www.youtube.com/watch?v=ii6Sek4q2oM)[www.youtube.com](https://www.youtube.com/watch?v=ii6Sek4q2oM)

[« UTF-8 範囲外の文字がLinux kernel のコミ…](https://hikalium.hatenablog.jp/entry/2025/08/31/003338) [2024年の振り返りと2025年の抱負 »](https://hikalium.hatenablog.jp/entry/2025/01/01/191744)