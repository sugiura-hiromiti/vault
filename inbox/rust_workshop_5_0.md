# 5章 構造体を使った関連データの構造化（Using Structs to Structure Related Data）

## 議論するポイント

- **構造体とタプルの比較**
  - いつ構造体を使い、いつタプルを使うべきか？
  - 名前付きフィールドの利点と可読性
  - データの意味を明確にする重要性

- **Rustの型システムと構造体**
  - コンパイル時型チェックの恩恵
  - 構造体とenumによる新しい型の作成
  - ドメイン駆動設計における構造体の役割

- **オブジェクト指向言語との違い**
  - 構造体はデータのみを持つ
  - メソッドと関連関数の概念
  - 継承ではなくコンポジションによる設計

- **メモリレイアウトと効率性**
  - 構造体のメモリ配置
  - フィールドの順序とパディング
  - ゼロコスト抽象化の実現

## 理解度チェック

1. 構造体とタプルの主な違いは何ですか？どのような場面でそれぞれを使い分けますか？

2. 以下のコードで何が問題でしょうか？
```rust
struct User {
    username: String,
    email: String,
    active: bool,
}

fn create_user() -> User {
    User {
        username: "user1",
        email: "user@example.com",
        active: true,
    }
}
```

3. 構造体のフィールドに対する所有権の考え方について説明してください。

4. 関連関数とメソッドの違いは何ですか？

5. 構造体の更新記法（struct update syntax）とは何ですか？どのような場面で有用ですか？

## 課題

### 基礎課題

1. **座標系の実装**
   2D座標を表す構造体を定義し、基本的な操作を実装してください。
```rust
struct Point {
    // フィールドを定義
}

impl Point {
    fn new(x: f64, y: f64) -> Self {
        // 実装
    }
    
    fn distance_from_origin(&self) -> f64 {
        // 原点からの距離を計算
    }
    
    fn distance_to(&self, other: &Point) -> f64 {
        // 他の点との距離を計算
    }
}
```

2. **書籍管理システム**
   書籍情報を管理する構造体を作成してください。
```rust
struct Book {
    // 必要なフィールドを定義
}

impl Book {
    fn new(title: String, author: String, pages: u32) -> Self {
        // 実装
    }
    
    fn is_long_book(&self) -> bool {
        // 300ページ以上なら長い本とする
    }
    
    fn summary(&self) -> String {
        // 本の概要を文字列で返す
    }
}
```

3. **温度変換器**
   摂氏と華氏の温度変換を行う構造体を実装してください。
```rust
struct Temperature {
    // フィールドを定義
}

impl Temperature {
    fn from_celsius(celsius: f64) -> Self {
        // 実装
    }
    
    fn from_fahrenheit(fahrenheit: f64) -> Self {
        // 実装
    }
    
    fn to_celsius(&self) -> f64 {
        // 実装
    }
    
    fn to_fahrenheit(&self) -> f64 {
        // 実装
    }
}
```

### 中級課題

4. **図形の面積計算**
   異なる図形を表現し、面積を計算する構造体群を実装してください。
```rust
struct Rectangle {
    width: f64,
    height: f64,
}

struct Circle {
    radius: f64,
}

struct Triangle {
    base: f64,
    height: f64,
}

// 各構造体に面積計算メソッドを実装
```

5. **ユーザー管理システム**
   ユーザー情報を管理し、バリデーション機能を持つ構造体を実装してください。
```rust
struct User {
    username: String,
    email: String,
    age: u8,
    active: bool,
}

impl User {
    fn new(username: String, email: String, age: u8) -> Result<Self, String> {
        // バリデーション付きコンストラクタ
    }
    
    fn is_adult(&self) -> bool {
        // 18歳以上かチェック
    }
    
    fn deactivate(&mut self) {
        // ユーザーを非アクティブにする
    }
}
```

## 高難易度の課題

### 上級課題

1. **ジェネリック行列ライブラリ**
   任意の型に対応した行列演算ライブラリを実装してください。
```rust
struct Matrix<T> {
    data: Vec<Vec<T>>,
    rows: usize,
    cols: usize,
}

impl<T> Matrix<T> 
where 
    T: Clone + Default + std::ops::Add<Output = T> + std::ops::Mul<Output = T>
{
    fn new(rows: usize, cols: usize) -> Self {
        // 実装
    }
    
    fn from_vec(data: Vec<Vec<T>>) -> Result<Self, String> {
        // 実装
    }
    
    fn get(&self, row: usize, col: usize) -> Option<&T> {
        // 実装
    }
    
    fn set(&mut self, row: usize, col: usize, value: T) -> Result<(), String> {
        // 実装
    }
    
    fn multiply(&self, other: &Matrix<T>) -> Result<Matrix<T>, String> {
        // 行列の乗算
    }
    
    fn transpose(&self) -> Matrix<T> {
        // 転置行列
    }
}
```

2. **設定管理システム**
   アプリケーションの設定を型安全に管理するシステムを実装してください。
```rust
use std::collections::HashMap;

struct Config {
    database: DatabaseConfig,
    server: ServerConfig,
    logging: LoggingConfig,
    features: FeatureFlags,
}

struct DatabaseConfig {
    host: String,
    port: u16,
    username: String,
    password: String,
    database_name: String,
    max_connections: u32,
}

struct ServerConfig {
    host: String,
    port: u16,
    workers: usize,
    timeout_seconds: u64,
}

struct LoggingConfig {
    level: LogLevel,
    file_path: Option<String>,
    max_file_size: u64,
}

#[derive(Debug, Clone)]
enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
}

struct FeatureFlags {
    flags: HashMap<String, bool>,
}

impl Config {
    fn from_file(path: &str) -> Result<Self, ConfigError> {
        // ファイルから設定を読み込み
    }
    
    fn validate(&self) -> Result<(), Vec<String>> {
        // 設定の妥当性をチェック
    }
    
    fn merge_with(&mut self, other: Config) {
        // 他の設定とマージ
    }
}

#[derive(Debug)]
enum ConfigError {
    FileNotFound,
    ParseError(String),
    ValidationError(Vec<String>),
}
```

3. **イベント駆動システム**
   型安全なイベント処理システムを構造体を使って実装してください。
```rust
use std::collections::HashMap;
use std::any::{Any, TypeId};

struct EventBus {
    handlers: HashMap<TypeId, Vec<Box<dyn Any>>>,
}

trait Event: 'static {
    fn event_type(&self) -> &'static str;
}

trait EventHandler<T: Event> {
    fn handle(&mut self, event: &T);
}

impl EventBus {
    fn new() -> Self {
        // 実装
    }
    
    fn register<T: Event, H: EventHandler<T> + 'static>(&mut self, handler: H) {
        // イベントハンドラーを登録
    }
    
    fn emit<T: Event>(&mut self, event: T) {
        // イベントを発行し、対応するハンドラーを実行
    }
}

// 使用例のイベント定義
struct UserCreated {
    user_id: u64,
    username: String,
    email: String,
}

struct OrderPlaced {
    order_id: u64,
    user_id: u64,
    amount: f64,
}

impl Event for UserCreated {
    fn event_type(&self) -> &'static str {
        "user_created"
    }
}

impl Event for OrderPlaced {
    fn event_type(&self) -> &'static str {
        "order_placed"
    }
}
```

### 実践プロジェクト

4. **ゲームエンジンのエンティティシステム**
   ゲームオブジェクトを効率的に管理するEntity-Component-Systemアーキテクチャを実装してください：
   - エンティティの生成・削除
   - コンポーネントの動的な追加・削除
   - システムによるコンポーネントの一括処理
   - メモリ効率的なデータ配置

この課題では、大規模なゲーム開発で使われる実際のアーキテクチャパターンを学び、構造体を使った高度なデータ構造設計を体験できます。
