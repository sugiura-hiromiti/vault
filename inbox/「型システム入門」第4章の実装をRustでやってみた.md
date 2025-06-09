---
title: 「型システム入門」第4章の実装をRustでやってみた
source: https://opaupafz2.hatenablog.com/entry/2022/07/03/235845
author:
  - "[[なんか考えてることとか]]"
published: 2022-07-03
created: 2025-05-22
description: 型システム入門 プログラミング言語と型の理論作者:ＢｅｎｊａｍｉｎＣ．Ｐｉｅｒｃｅ,住井英二郎オーム社Amazon「型システム入門 −プログラミング言語と型の理論−」（以下TaPL）は、型システムを理解するうえで必要な基礎知識を学ぶことができる、文字通り型システムの入門書である。最近、型とは実際に何なのかを知るために、この本を読んで勉強している。第4章の型なし計算体系の実装がRustでもできそうだと思ったので、Rustで実装した。
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
[![型システム入門 プログラミング言語と型の理論](https://m.media-amazon.com/images/I/41lT4kD300L._SL500_.jpg "型システム入門 プログラミング言語と型の理論")](https://www.amazon.co.jp/dp/B07CBB69SS?tag=hatena-22&linkCode=ogi&th=1&psc=1)

[型システム入門 プログラミング言語と型の理論](https://www.amazon.co.jp/dp/B07CBB69SS?tag=hatena-22&linkCode=ogi&th=1&psc=1)

- 作者:[ＢｅｎｊａｍｉｎＣ．Ｐｉｅｒｃｅ](http://d.hatena.ne.jp/keyword/%A3%C2%A3%E5%A3%EE%A3%EA%A3%E1%A3%ED%A3%E9%A3%EE%A3%C3%A1%A5%A3%D0%A3%E9%A3%E5%A3%F2%A3%E3%A3%E5),[住井英二郎](http://d.hatena.ne.jp/keyword/%BD%BB%B0%E6%B1%D1%C6%F3%CF%BA)
- [オーム社](http://d.hatena.ne.jp/keyword/%A5%AA%A1%BC%A5%E0%BC%D2)
[Amazon](https://www.amazon.co.jp/dp/B07CBB69SS?tag=hatena-22&linkCode=ogi&th=1&psc=1)

「型システム入門 − [プログラミング言語](http://d.hatena.ne.jp/keyword/%A5%D7%A5%ED%A5%B0%A5%E9%A5%DF%A5%F3%A5%B0%B8%C0%B8%EC) と型の理論−」（以下TaPL）は、型システムを理解するうえで必要な基礎知識を学ぶことができる、文字通り型システムの入門書である。最近、型とは実際に何なのかを知るために、この本を読んで勉強している。

第4章の型なし計算体系の実装がRustでもできそうだと思ったので、Rustで実装した。

### 環境

Rust 1.61.0 安定板

### 1\. 前提の知識

#### 1.1 型なし計算体系の操作的意味論

まず型なし計算体系を実装するためには、その操作的意味論における定義の要約は最低限必要である。それを以下に示す。ただし、ここで定義されているものは構造的操作的意味論によるものである。

![](https://cdn-ak.f.st-hatena.com/images/fotolife/o/opaupafz2/20220703/20220703205810.png)

`t` は **項** である。これは第4章において **正規形** [\*4](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-33eb48b3 "これ以上評価できない項のことである") **でないもの** も含めた **メタ変数** である。 `succ t1` の `t1` などは項 `t` の **部分項** という。

`v` は **値** である。第4章における値とは、数値だけでなく **ブール値** も含む。 `nv` は値のうち **数値** であることを示す。

`t` を評価して `t'` となるとき、 `t → t'` は **評価関係式** という。  
たとえば評価規則E-I F T RUE は `if true then t2 else t3 → t2` という評価関係式になっているが、これは「 `if true then t2 else t3` を評価することで `t2` を得る」ということを示している。  
評価規則にはE-I F など下の `if t1 then t2 else t3 → if t1' then t2 else t3` の上に `t1 → t1'` といった形の評価関係式がある場合もある。これは「 `t1 → t1'` のとき、 `if t1 then t2 else t3` を評価することで `if t1' then t2 else t3` を得る」ということを示している。

ちなみに、本来、ブール値が適用されるべきなのにブール値でなかったり、数値が適用されるべきなのに数値でなかったりする部分項が存在した場合、その部分項を持つ項はそれ以上評価できない。こういった項を **行き詰まり状態** という。たとえば `if nv1 then t2 else t3` は `nv1` が数値であるため、E-I F T RUE 、E-I F F ALSE 、E-I F のいずれも当てはまらない。したがってこの項はこれ以上評価できない行き詰まり状態となる。

#### 1.2 Rustにおける再帰型

まず今回の型なし計算体系を実装するにあたり、 **ツリー構造が必要** である。そのため、 **[再帰](http://d.hatena.ne.jp/keyword/%BA%C6%B5%A2) 型を定義しなければならない** のだが、Rustの型システムにおけるほとんどの場合においては **[コンパイル](http://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) 時に型のメモリサイズがわかっていることを前提としている** ので [再帰](http://d.hatena.ne.jp/keyword/%BA%C6%B5%A2) 型を容易に定義することはできない。しかし、定義する型の中で **ボクシング** [\*5](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-b1087855 "ボックス化ともいう") された同じ型を定義することで [再帰](http://d.hatena.ne.jp/keyword/%BA%C6%B5%A2) 型を定義することが可能となる。ちなみにわかっているとは思うが、ここでいうボクシングとは、スポーツのことではなく、 **値をヒープメモリに格納された値へのポインタに変換する** ことである。

Rustでボクシングするためには、 `Box<T>` **型を用いる** 。そして `Box<T>` 型を用いた簡単な [再帰](http://d.hatena.ne.jp/keyword/%BA%C6%B5%A2) 型の定義の例を以下に示す。

```rust
/// リスト型
enum MyList<T> {
    Cons(T, Box<MyList<T>>),
    Nil,
}
```

[Rust Playground](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=1a01033b9c93955ff1ef6730a61c603a)

ちなみにRustにおける `Box<T>` 型はポインタであるため、基本参照外し `*` が必要となる。

### 2\. 構造的操作的意味論を用いた型なし計算体系の実装

**構造的操作的意味論** は、1ステップずつ評価する操作的意味論であり、 **小ステップスタイル** とも呼ばれる。それを実装したRustコードを以下に示す。

```rust
/// 構文
#[derive(Debug, Eq, PartialEq, Clone)]
enum Term {
    TmTrue,                                 // 定数真
    TmFalse,                                // 定数偽
    TmIf(Box<Term>, Box<Term>, Box<Term>),  // 条件式
    TmZero,                                 // 定数ゼロ
    TmSucc(Box<Term>),                      // 後者値
    TmPred(Box<Term>),                      // 前者値
    TmIszero(Box<Term>),                    // ゼロ判定
}

impl Term {
    /// 条件式の単純化
    #[inline]
    fn tm_if(t1: Self, t2: Self, t3: Self) -> Self {
        Self::TmIf(Box::new(t1), Box::new(t2), Box::new(t3))
    }
    /// 後者値の単純化
    #[inline]
    fn tm_succ(t1: Self) -> Self {
        Self::TmSucc(Box::new(t1))
    }
    /// 前者値の単純化
    #[inline]
    fn tm_pred(t1: Self) -> Self {
        Self::TmPred(Box::new(t1))
    }
    /// ゼロ判定の単純化
    #[inline]
    fn tm_iszero(t1: Self) -> Self {
        Self::TmIszero(Box::new(t1))
    }

    /// 項が数値であるか判定
    fn is_numeric_val(&self) -> bool {
        match self {
            Self::TmZero => true,
            Self::TmSucc(t) => t.is_numeric_val(),
            _ => false,
        }
    }

    /// 項が値であるか判定
    fn is_val(&self) -> bool {
        match self {
            Self::TmTrue | Self::TmFalse => true,
            t => t.is_numeric_val(),
        }
    }

    /// 構造的操作的意味論による評価
    fn eval1(&self) -> Option<Self> {
        match self {
            Self::TmIf(t1, t2, t3) => match &**t1 {
                // E-IfTrue
                Self::TmTrue => Some((**t2).clone()),

                // E-IfFalse
                Self::TmFalse => Some((**t3).clone()),

                // E-If
                t1_ => t1_.eval1()
                          .map(|t1__| {
                               Self::tm_if(t1__, (**t2).clone(), (**t3).clone())
                           }),
            },

            // E-Succ
            Self::TmSucc(t1) => t1.eval1().map(Self::tm_succ),

            Self::TmPred(t1) => match &**t1 {
                // E-PredZero
                Self::TmZero => Some(Self::TmZero),

                // E-PredSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => Some((**nv1).clone()),

                // E-Pred
                t1_ => t1_.eval1().map(Self::tm_pred),
            },

            Self::TmIszero(t1) => match &**t1 {
                // E-IszeroZero
                Self::TmZero => Some(Self::TmTrue),

                // E-IszeroSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => Some(Self::TmFalse),

                // E-Iszero
                t1_ => t1_.eval1().map(Self::tm_iszero),
            },

            // 正規形
            _ => None,
        }
    }

    /// 評価
    /// 正規形(\`None\`)になるまで評価を繰り返す
    fn eval(self) -> Self {
        if let Some(t) = self.eval1() {
            t.eval()
        } else {
            self
        }
    }
}
```

一つずつ見ていこう。

#### 2.1 構文

1.1にて定義した構文通りにRustで書いたのが以下の部分である。

```rust
/// 構文
#[derive(Debug, Eq, PartialEq, Clone)]
enum Term {
    TmTrue,                                 // 定数真
    TmFalse,                                // 定数偽
    TmIf(Box<Term>, Box<Term>, Box<Term>),  // 条件式
    TmZero,                                 // 定数ゼロ
    TmSucc(Box<Term>),                      // 後者値
    TmPred(Box<Term>),                      // 前者値
    TmIszero(Box<Term>),                    // ゼロ判定
}
```

`Term` 型の値そのものが項であり、部分項の型も `Term` 型である・・・のだが、1.2よりRustでは部分項となる値はボクシングされている必要があるのだった。そのため、部分項の型は `Box<Term>` 型となる。

あとは、構文通り定義していくだけである。

ちなみにTaPLではすべての項にその項がどこを示しているのかなどといった情報を表現する `info` 型の値が要素として含まれているがこの記事ではわかりやすさのために省略している。もし `info` 型の値も含めて定義したいならば、独自に `Info` 型を定義し、以下のように書く必要があるだろう。

```rust
/// 構文
#[derive(Debug, Eq, PartialEq, Clone)]
enum Term {
    TmTrue(Info),                                   // 定数真
    TmFalse(Info),                                  // 定数偽
    TmIf(Info, Box<Term>, Box<Term>, Box<Term>),    // 条件式
    TmZero(Info),                                   // 定数ゼロ
    TmSucc(Info, Box<Term>),                        // 後者値
    TmPred(Info, Box<Term>),                        // 前者値
    TmIszero(Info, Box<Term>),                      // ゼロ判定
}
```

これ以降、 `Info` 型については無視して考える。もし含めたいならば、以降のコードは読み替える必要があることに注意。

#### 2.2 部分項のある項の単純化

部分項のある項を生成するとき、部分項にいちいち `Box::new()` によって部分項をボクシングしなければならない。それを軽減させるために、普通の部分項に適用するだけで自動でボクシングしてくれる関連関数を定義した。それを以下に示す。

```rust
impl Term {
    /// 条件式の単純化
    #[inline]
    fn tm_if(t1: Self, t2: Self, t3: Self) -> Self {
        Self::TmIf(Box::new(t1), Box::new(t2), Box::new(t3))
    }
    /// 後者値の単純化
    #[inline]
    fn tm_succ(t1: Self) -> Self {
        Self::TmSucc(Box::new(t1))
    }
    /// 前者値の単純化
    #[inline]
    fn tm_pred(t1: Self) -> Self {
        Self::TmPred(Box::new(t1))
    }
    /// ゼロ判定の単純化
    #[inline]
    fn tm_iszero(t1: Self) -> Self {
        Self::TmIszero(Box::new(t1))
    }
    
    /* 省略 */

}
```

これによって項の生成がある程度楽になる。以下は単 [純化](http://d.hatena.ne.jp/keyword/%BD%E3%B2%BD) しない場合とする場合の比較である。

```rust
// 条件式
Term::TmIf(Box::new(t1), Box::new(t2), Box::new(t3));

// 条件式(単純化)
Term::tm_if(t1, t2, t3);

// 後者値
Term::TmSucc(Box::new(t1));

// 後者値(単純化)
Term::tm_succ(t1);

// 前者値
Term::TmPred(Box::new(t1));

// 前者値(単純化)
Term::tm_pred(t1);

// ゼロ判定
Term::TmIszero(Box::new(t1));

// ゼロ判定(単純化)
Term::tm_iszero(t1);
```

なお、わかっているとは思うが、これらは項の生成時の負担を軽減させるためのものでしかないので、項を生成するだけなら必要はない。ただ、あったほうが圧倒的に楽になることは間違いないだろう。

#### 2.3 「項が値であるか判定するメソッド」の定義

後の評価で必要となってくる「項が値であるか判定するメソッド」の定義を以下に示す。

```rust
/// 項が数値であるか判定
    fn is_numeric_val(&self) -> bool {
        match self {
            Self::TmZero => true,
            Self::TmSucc(t) => t.is_numeric_val(),
            _ => false,
        }
    }

    /// 項が値であるか判定
    fn is_val(&self) -> bool {
        match self {
            Self::TmTrue | Self::TmFalse => true,
            t => t.is_numeric_val(),
        }
    }
```

`Term::is_numeric_val()` メソッドが項でいうところの `nv` の判定に相当し、 `Term::is_val()` メソッドが項でいうところの `v` の判定に相当する。

なお、ここで注意してほしいのは、 `Term::is_val()` メソッドは実際のところ使わないという点である。これはTaPLでは `isVal` 関数といった形で定義されている。それが評価の実装では使わないというだけのことである。よって、Rustでは使っていない関数があると [コンパイル](http://d.hatena.ne.jp/keyword/%A5%B3%A5%F3%A5%D1%A5%A4%A5%EB) 時に警告を出されるので、 `#[allow(dead_code)]` を関数定義の上に付け加える必要があることを付加しておく。

#### 2.4 評価

最後に評価の実装を行う。TaPLの [OCaml](http://d.hatena.ne.jp/keyword/OCaml) による実装では単純にパターンマッチングさせているだけだが、Rustでは **手動でボクシングする必要性がある都合上、パターンマッチングだけでなく一工夫必要である** [\*6](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-2baa569b "一応RustのバージョンをNightlyにして、Unstable Featureである「box_syntax」を有効にすることでOcamlと同じように単純なパターンマッチングのみで解決した実装も可能となるが、今回はStable Rustのみで実装する") 。そのため、 [Ocaml](http://d.hatena.ne.jp/keyword/Ocaml) の実装よりも少々複雑な実装となっている。それを以下に示す。

```rust
/// 構造的操作的意味論による評価
    fn eval1(&self) -> Option<Self> {
        match self {
            Self::TmIf(t1, t2, t3) => match &**t1 {
                // E-IfTrue
                Self::TmTrue => Some((**t2).clone()),

                // E-IfFalse
                Self::TmFalse => Some((**t3).clone()),

                // E-If
                t1_ => t1_.eval1()
                          .map(|t1__| {
                               Self::tm_if(t1__, (**t2).clone(), (**t3).clone())
                           }),
            },

            // E-Succ
            Self::TmSucc(t1) => t1.eval1().map(Self::tm_succ),

            Self::TmPred(t1) => match &**t1 {
                // E-PredZero
                Self::TmZero => Some(Self::TmZero),

                // E-PredSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => Some((**nv1).clone()),

                // E-Pred
                t1_ => t1_.eval1().map(Self::tm_pred),
            },

            Self::TmIszero(t1) => match &**t1 {
                // E-IszeroZero
                Self::TmZero => Some(Self::TmTrue),

                // E-IszeroSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => Some(Self::TmFalse),

                // E-Iszero
                t1_ => t1_.eval1().map(Self::tm_iszero),
            },

            // 正規形
            _ => None,
        }
    }

    /// 評価
    /// 正規形(\`None\`)になるまで評価を繰り返す
    fn eval(self) -> Self {
        if let Some(t) = self.eval1() {
            t.eval()
        } else {
            self
        }
    }
```

構築子 `Term::TmIf` の部分を例に見てほしい。 [OCaml](http://d.hatena.ne.jp/keyword/OCaml) の実装では以下のように実装されていた。

```ocaml
(** 構造的操作的意味論による評価 *)
let rec eval1 t = match t with
      (* E-IfTrue *)
      TmIf(TmTrue, t2, _) -> t2
      (* E-IfFalse *)
    | TmIf(TmFalse, _, t3) -> t3
      (* E-If *)
    | TmIf(t1, t2, t3) ->
        let t1' = eval1 t1 in
        TmIf(t1', t2, t3)

    (* 省略 *)
```

ところがRustではパターンマッチングをさせるときに、部分項がボクシングされていると特定の定数にマッチしてくれない。つまりあくまで部分項の型は `Box<Term>` 型であるので、 **一度アンボクシング** [\*7](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-e4c6bc6c "ボクシングを解除すること。ボックス化解除、非ボックス化とも呼ばれる") **をする必要がある** 。

```rust
/// 構造的操作的意味論による評価
    fn eval1(&self) -> Option<Self> {
        match self {
            Self::TmIf(t1, t2, t3) => match &**t1 {
                // E-IfTrue
                Self::TmTrue => Some((**t2).clone()),

                // E-IfFalse
                Self::TmFalse => Some((**t3).clone()),

                // E-If
                t1_ => t1_.eval1()
                          .map(|t1__| {
                               Self::tm_if(t1__, (**t2).clone(), (**t3).clone())
                           }),
            },

            /* 省略 */

        }
    }
```

ちなみに要所要所で **2度参照外しを行っている** が、これには理由がある。実は構造的操作的意味論による評価の実装では、あまり効率の良い実装が思いつかなかった [\*8](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-822dcaae "ちなみに後に紹介する自然意味論による実装では効率の良い実装ができた。これはTaPLでも書かれていたが、どうやら構造的操作的意味論は効率の良い実装が難しいようである") 。その関係で、 **部分項は厳密には** `&Box<Term>` **型となっており、これにより所有権のムーブが起こらないようにしている** 。そのため、参照→Box→部分項といった感じで2度参照外しする必要があるわけである。  
また `Term` **型に** `Clone` **トレイトを実装する** ことによって **部分項を返すときに値のコピーを行う** ようにしている。

ほかの構築子も一部 `Term::is_numeric_val()` メソッドを使いガードをしている [\*9](https://opaupafz2.hatenablog.com/entry/2022/07/03/#f-687f70e4 "ガードをしている理由は、部分項が数値以外である場合を避けるためである") 以外は同様である。

そして、今回の実装は構造的操作的意味論によるものなので、1ステップの評価しかされない。そのため、項が正規形となるまで繰り返すメソッド `Term::eval()` を定義している。

```rust
/// 評価
    /// 正規形(\`None\`)になるまで評価を繰り返す
    fn eval(self) -> Self {
        if let Some(t) = self.eval1() {
            t.eval()
        } else {
            self
        }
    }
```

以上で今回の実装について大雑把にではあるが、一通りの解説をした。以下の外部リンクにより、評価を試すことができる。

[Rust Playground](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=9b669d2709cf39058cba25c12b60e137)  

### 3\. 自然意味論を用いた型なし計算体系の実装

**自然意味論** とは、「項が最終的に正規形に評価される」ことを定式化した操作的意味論であり、 **大ステップスタイル** とも呼ばれる。構文は構造的操作的意味論と同様であるが、評価規則は以下のようになっている。

![](https://cdn-ak.f.st-hatena.com/images/fotolife/o/opaupafz2/20220703/20220703223543.png)

以上の評価規則をもとにした実装を以下に示す。

```rust
/// 構文
#[derive(Debug, Eq, PartialEq)]
enum Term {
    TmTrue,                                 // 定数真
    TmFalse,                                // 定数偽
    TmIf(Box<Term>, Box<Term>, Box<Term>),  // 条件式
    TmZero,                                 // 定数ゼロ
    TmSucc(Box<Term>),                      // 後者値
    TmPred(Box<Term>),                      // 前者値
    TmIszero(Box<Term>),                    // ゼロ判定
}

impl Term {
    /// 条件式の単純化
    #[inline]
    fn tm_if(t1: Self, t2: Self, t3: Self) -> Self {
        Self::TmIf(Box::new(t1), Box::new(t2), Box::new(t3))
    }
    /// 後者値の単純化
    #[inline]
    fn tm_succ(t1: Self) -> Self {
        Self::TmSucc(Box::new(t1))
    }
    /// 前者値の単純化
    #[inline]
    fn tm_pred(t1: Self) -> Self {
        Self::TmPred(Box::new(t1))
    }
    /// ゼロ判定の単純化
    #[inline]
    fn tm_iszero(t1: Self) -> Self {
        Self::TmIszero(Box::new(t1))
    }

    /// 項が数値であるか判定
    fn is_numeric_val(&self) -> bool {
        match self {
            Self::TmZero => true,
            Self::TmSucc(t) => t.is_numeric_val(),
            _ => false,
        }
    }

    /// 項が値であるか判定
    fn is_val(&self) -> bool {
        match self {
            Self::TmTrue | Self::TmFalse => true,
            t => t.is_numeric_val(),
        }
    }

    /// 自然意味論による評価
    fn eval(self) -> Self {
        match self {
            Self::TmIf(t1, t2, t3) => match t1.eval() {
                // B-IfTrue
                Self::TmTrue => t2.eval(),

                // B-IfFalse
                Self::TmFalse => t3.eval(),

                // Stuck
                t1_ => Self::tm_if(t1_, *t2, *t3),
            },

            // B-Succ
            Self::TmSucc(t1) => Self::tm_succ(t1.eval()),

            Self::TmPred(t1) => match t1.eval() {
                // B-PredZero
                Self::TmZero => Self::TmZero,

                // B-PredSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => *nv1,

                // Stuck
                t1_ => Self::tm_pred(t1_),
            },

            Self::TmIszero(t1) => match t1.eval() {
                // B-IszeroZero
                Self::TmZero => Self::TmTrue,

                // B-IszeroSucc
                Self::TmSucc(nv1) if nv1.is_numeric_val() => Self::TmFalse,

                // Stuck
                t1_ => Self::tm_iszero(t1_),
            },

            // 正規形
            v => v,
        }
    }
}
```

[Rust Playground](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=bda630c287718489703d3a78f73c2493)

この実装では行き詰まり状態となる項も返すようになっている。行き詰まり状態をエラーとしたい場合、実装を一部変更する必要がある点に注意。  
またこの実装は、TaPLでは演習問題となっているので、詳細は解説しない。

[« Rustにおいてbreakやreturnを含む式はどの…](https://opaupafz2.hatenablog.com/entry/2022/07/31/152932) [void型の関数は「値を返さない」のではない »](https://opaupafz2.hatenablog.com/entry/2022/05/14/182729)