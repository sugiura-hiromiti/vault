---
id: 25062516281837
aliases: []
tags: []
created: 250625 16:28:18
updated: 250625 16:28:18
---

## Rust勉強会レジュメ：第2章 数当てゲーム

### 📘 Chapter Summary

Rustの構文に触れながら、CLIツールの基本構成を体験するチュートリアルです。  
標準入力、マッチング、ループ、外部クレートなどの基本機能が一通り登場します。

---

## 🔥 Discussion

Rustを知るための視野を広げる問いを提示します：

- Rustは「安全性、速度、並行性」を掲げていますが、この小さなCLIゲームにおいて**「安全性」**はどこで発揮されているのでしょうか？
    
- C言語でこの数当てゲームを実装する場合、どのようなバグ・落とし穴が考えられるか？Rustでそれらがどう防がれているかを考えてみてください。
    
- `Result<T, E>` や `match` など、Rustの「エラー処理哲学」はこのチュートリアルからどう読み取れるでしょうか？
    
- なぜ `rand` クレートを使う必要があるのか？標準ライブラリにはないのか？それはどんな設計思想に由来しているか？
    

---

## 🧠 Quiz

「Rustの文法・動作理解」を確認する基礎問題です。

1. `let mut guess = String::new();` における `mut` の役割は何ですか？
    
2. `match guess.cmp(&secret_number)` の `cmp` 関数は何を返しますか？
    
3. `io::stdin().read_line(&mut guess)` はどのような値を返し、それをどう処理していますか？
    
4. `expect()` を使う理由と、`unwrap()` との違いは何ですか？
    
5. `use std::io;` のような `use` 宣言がなぜ必要なのでしょうか？
    

---

## 🧪 Challenge

Rustの基本構文・型システムに親しむ応用課題です。

### 課題1: 入力回数の表示

- 現在のコードに「何回目の試行か」を表示する機能を加えてみてください。
    
- 条件：
    
    - `loop` の中で試行回数をカウントする。
        
    - プレイヤーに回数を表示する（例: "3回目の入力です"）
        

### 課題2: 入力値のバリデーション強化

- 入力が数値でない場合に再入力を促し、ゲームが落ちないように改善してください。
    
- `parse::<u32>()` を失敗したときに `continue` でループを再開させてみましょう。
    

---

## 🏆 Homework

より実用的・難度の高い応用課題です。

### 宿題1: 数値範囲のカスタマイズ機能

- ユーザーが開始時に「最小値・最大値」を入力できるようにしてください。
    
- `rand::thread_rng().gen_range(min..=max)` によってランダムな数を生成します。
    

```rust
// ユーザーに範囲を聞く
println!("最小値を入力してください:");
let min = read_number_from_stdin();
println!("最大値を入力してください:");
let max = read_number_from_stdin();
```

※ read_number_from_stdin() は自作してください。`Result` をうまく使ってエラーハンドリングをしましょう。

### 宿題2: 回数制限付きゲームモード

- 最大 `n` 回までしか挑戦できないゲームモードを追加してください。
    
- プレイヤーが当てられなかった場合はゲームオーバーと表示するようにしましょう。
    

**仕様：**

- `let max_attempts = 5;`
    
- 回数が尽きたら `"ゲームオーバー！正解は {secret_number} でした"` と表示して終了。
    

---

## ✅ Wrap Up

- 今回の章ではRustの「安全な型変換」「標準入出力」「マッチング構文」「クレート利用」など、多くのRust的構文に触れました。
    
- 次回以降では、関数、所有権、エラー処理など、よりRustらしい概念を掘り下げていきます。
    

---

## 📚 予習・参考資料

- [Rust by Example - Guessing Game](https://doc.rust-lang.org/rust-by-example/std_misc/file/guessing_game.html)
    
- [The Book 英語版 第2章](https://doc.rust-lang.org/book/ch02-00-guessing-game-tutorial.html)
    

---

## 🛠️ Appendix: 補助コードスニペット

```rust
fn read_number_from_stdin() -> u32 {
    loop {
        let mut input = String::new();
    da    io::stdin().read_line(&mut input).expect("入力失敗");

        match input.trim().parse() {
            Ok(num) => return num,
            Err(_) => println!("数字を入力してください。"),
        }
    }
}
```