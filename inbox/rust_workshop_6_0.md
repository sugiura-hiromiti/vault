# 6章 列挙型とパターンマッチング（Enums and Pattern Matching）

## 議論するポイント

- **列挙型の表現力**
  - 他の言語の列挙型との違い
  - データを持つバリアントの威力
  - 型安全性と表現力のバランス

- **Option型の哲学**
  - null参照問題の解決
  - 明示的なnull可能性の表現
  - コンパイル時の安全性保証

- **パターンマッチングの威力**
  - match式による網羅的チェック
  - 値の分解と束縛
  - ガード条件の活用

- **if letとmatchの使い分け**
  - 簡潔性と可読性のトレードオフ
  - 単一パターンマッチングの最適化
  - コードの意図を明確にする書き方

- **関数型プログラミングとの関連**
  - 代数的データ型としての列挙型
  - パターンマッチングによる構造化プログラミング
  - 不変性と安全性の追求

## 理解度チェック

1. 以下のコードで何が問題でしょうか？
```rust
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
}

fn process_message(msg: Message) {
    match msg {
        Message::Quit => println!("Quit"),
        Message::Write(text) => println!("Write: {}", text),
    }
}
```

2. Option<T>型を使う利点は何ですか？他の言語のnullとの違いを説明してください。

3. 以下のコードをif let文を使って書き換えてください：
```rust
match some_option {
    Some(value) => println!("Got: {}", value),
    None => {},
}
```

4. パターンマッチングで値を分解する際の所有権の動きについて説明してください。

5. match式が「網羅的」であることの重要性について説明してください。

## 課題

### 基礎課題

1. **図形の面積計算（列挙型版）**
   異なる図形を列挙型で表現し、面積を計算してください。
```rust
enum Shape {
    Circle(f64),                    // 半径
    Rectangle(f64, f64),           // 幅、高さ
    Triangle(f64, f64),            // 底辺、高さ
}

impl Shape {
    fn area(&self) -> f64 {
        // 実装
    }
    
    fn perimeter(&self) -> f64 {
        // 実装
    }
}
```

2. **計算機の実装**
   四則演算を表現する列挙型を作成し、計算機を実装してください。
```rust
enum Operation {
    Add(f64, f64),
    Subtract(f64, f64),
    Multiply(f64, f64),
    Divide(f64, f64),
}

impl Operation {
    fn calculate(&self) -> Result<f64, String> {
        // 実装（ゼロ除算エラーも考慮）
    }
}
```

3. **HTTPステータスコード**
   HTTPステータスコードを列挙型で表現してください。
```rust
enum HttpStatus {
    Ok,
    NotFound,
    InternalServerError,
    BadRequest,
    Unauthorized,
}

impl HttpStatus {
    fn code(&self) -> u16 {
        // 実装
    }
    
    fn message(&self) -> &'static str {
        // 実装
    }
    
    fn is_success(&self) -> bool {
        // 実装
    }
}
```

### 中級課題

4. **JSONライクなデータ構造**
   JSONの値を表現する列挙型を実装してください。
```rust
use std::collections::HashMap;

enum JsonValue {
    Null,
    Bool(bool),
    Number(f64),
    String(String),
    Array(Vec<JsonValue>),
    Object(HashMap<String, JsonValue>),
}

impl JsonValue {
    fn type_name(&self) -> &'static str {
        // 実装
    }
    
    fn is_truthy(&self) -> bool {
        // 実装
    }
    
    fn get(&self, key: &str) -> Option<&JsonValue> {
        // オブジェクトの場合のみキーで値を取得
    }
    
    fn pretty_print(&self, indent: usize) -> String {
        // 整形された文字列を返す
    }
}
```

5. **ファイルシステムエントリ**
   ファイルシステムのエントリを表現する列挙型を実装してください。
```rust
use std::time::SystemTime;

enum FileSystemEntry {
    File {
        name: String,
        size: u64,
        modified: SystemTime,
        content: Vec<u8>,
    },
    Directory {
        name: String,
        entries: Vec<FileSystemEntry>,
        modified: SystemTime,
    },
    SymLink {
        name: String,
        target: String,
    },
}

impl FileSystemEntry {
    fn name(&self) -> &str {
        // 実装
    }
    
    fn size(&self) -> u64 {
        // ディレクトリの場合は中身のサイズの合計
    }
    
    fn find(&self, name: &str) -> Option<&FileSystemEntry> {
        // 名前でエントリを検索
    }
    
    fn list_files(&self) -> Vec<&str> {
        // ファイル名のリストを返す
    }
}
```

## 高難易度の課題

### 上級課題

1. **式評価器**
   数式を表現し評価する列挙型を実装してください。
```rust
enum Expr {
    Number(f64),
    Variable(String),
    Add(Box<Expr>, Box<Expr>),
    Subtract(Box<Expr>, Box<Expr>),
    Multiply(Box<Expr>, Box<Expr>),
    Divide(Box<Expr>, Box<Expr>),
    Power(Box<Expr>, Box<Expr>),
    Function(String, Vec<Expr>),
}

use std::collections::HashMap;

struct Context {
    variables: HashMap<String, f64>,
    functions: HashMap<String, fn(&[f64]) -> Result<f64, String>>,
}

impl Expr {
    fn evaluate(&self, context: &Context) -> Result<f64, String> {
        // 実装
    }
    
    fn simplify(&self) -> Expr {
        // 式の簡約（例：0 + x → x, 1 * x → x）
    }
    
    fn derivative(&self, var: &str) -> Expr {
        // 指定された変数での微分
    }
    
    fn to_string(&self) -> String {
        // 数式を文字列として表現
    }
}
```

2. **状態機械**
   ジェネリックな状態機械を列挙型で実装してください。
```rust
trait State {
    type Event;
    type Error;
    
    fn handle_event(self, event: Self::Event) -> Result<Self, Self::Error>
    where
        Self: Sized;
}

// 使用例：信号機の状態機械
#[derive(Debug, Clone)]
enum TrafficLight {
    Red { remaining_seconds: u32 },
    Yellow { remaining_seconds: u32 },
    Green { remaining_seconds: u32 },
}

#[derive(Debug)]
enum TrafficEvent {
    Tick,
    EmergencyStop,
    Resume,
}

#[derive(Debug)]
enum TrafficError {
    InvalidTransition,
    SystemError,
}

impl State for TrafficLight {
    type Event = TrafficEvent;
    type Error = TrafficError;
    
    fn handle_event(self, event: Self::Event) -> Result<Self, Self::Error> {
        // 実装
    }
}

struct StateMachine<S: State> {
    current_state: S,
}

impl<S: State> StateMachine<S> {
    fn new(initial_state: S) -> Self {
        // 実装
    }
    
    fn handle_event(&mut self, event: S::Event) -> Result<(), S::Error> {
        // 実装
    }
    
    fn current_state(&self) -> &S {
        // 実装
    }
}
```

3. **パーサーコンビネータ**
   関数型プログラミングスタイルのパーサーコンビネータを実装してください。
```rust
type ParseResult<'a, T> = Result<(T, &'a str), ParseError>;

#[derive(Debug, Clone)]
struct ParseError {
    message: String,
    position: usize,
}

struct Parser<T> {
    parse_fn: Box<dyn Fn(&str) -> ParseResult<T>>,
}

impl<T> Parser<T> {
    fn new<F>(parse_fn: F) -> Self
    where
        F: Fn(&str) -> ParseResult<T> + 'static,
    {
        // 実装
    }
    
    fn parse(&self, input: &str) -> ParseResult<T> {
        // 実装
    }
    
    fn map<U, F>(self, f: F) -> Parser<U>
    where
        F: Fn(T) -> U + 'static,
        T: 'static,
    {
        // 実装
    }
    
    fn and_then<U, F>(self, f: F) -> Parser<U>
    where
        F: Fn(T) -> Parser<U> + 'static,
        T: 'static,
    {
        // 実装
    }
    
    fn or(self, other: Parser<T>) -> Parser<T>
    where
        T: 'static,
    {
        // 実装
    }
}

// 基本的なパーサー
fn char_parser(expected: char) -> Parser<char> {
    // 実装
}

fn string_parser(expected: &'static str) -> Parser<String> {
    // 実装
}

fn number_parser() -> Parser<f64> {
    // 実装
}

// 使用例：簡単な計算式パーサー
fn expression_parser() -> Parser<f64> {
    // 実装
}
```

### 実践プロジェクト

4. **ドメイン特化言語（DSL）の実装**
   設定ファイルやクエリ言語のような小さなDSLを列挙型を使って実装してください：
   - 字句解析器（トークン化）
   - 構文解析器（AST構築）
   - インタープリター（実行エンジン）
   - エラーハンドリングと報告

この課題では、実際のプログラミング言語処理系で使われる技術を学び、列挙型とパターンマッチングの真の威力を体験できます。
