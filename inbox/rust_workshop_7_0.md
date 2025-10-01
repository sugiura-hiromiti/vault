# 7章 パッケージ、クレート、モジュールによる成長するプロジェクトの管理

## 議論するポイント

- **モジュールシステムの階層構造**
  - パッケージ、クレート、モジュールの関係性
  - ファイルシステムとモジュール構造の対応
  - 論理的な構造と物理的な構造の分離

- **可視性とカプセル化**
  - pub キーワードによる公開制御
  - プライベートな実装詳細の隠蔽
  - APIの設計と後方互換性

- **use文とパス解決**
  - 絶対パスと相対パスの使い分け
  - use文による名前空間の管理
  - 再エクスポートによるAPI設計

- **大規模プロジェクトの組織化**
  - 機能別モジュール分割の戦略
  - 依存関係の管理
  - テストコードの配置

- **Cargoエコシステムとの連携**
  - クレートの公開と依存関係管理
  - ワークスペースによる複数クレート管理
  - セマンティックバージョニング

## 理解度チェック

1. パッケージ、クレート、モジュールの違いと関係性を説明してください。

2. 以下のモジュール構造で、`main.rs`から`utils::math::add`関数を呼び出すにはどのようなuse文が必要ですか？
```
src/
├── main.rs
├── utils/
│   ├── mod.rs
│   └── math.rs
```

3. `pub(crate)`、`pub(super)`、`pub(in path)`の違いは何ですか？

4. モジュールをファイルに分割する際の命名規則について説明してください。

5. 再エクスポート（re-export）とは何ですか？どのような場面で使用しますか？

## 課題

### 基礎課題

1. **図書館管理システムの構造化**
   図書館管理システムを適切なモジュール構造で実装してください。
```
library/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── book/
│   │   ├── mod.rs
│   │   └── catalog.rs
│   ├── user/
│   │   ├── mod.rs
│   │   └── account.rs
│   └── lending/
│       ├── mod.rs
│       └── transaction.rs
```

各モジュールに適切な構造体と関数を定義し、適切な可視性を設定してください。

2. **設定管理モジュール**
   アプリケーション設定を管理するモジュール群を実装してください。
```rust
// config/mod.rs
pub mod database;
pub mod server;
pub mod logging;

pub use database::DatabaseConfig;
pub use server::ServerConfig;
pub use logging::LoggingConfig;

pub struct AppConfig {
    pub database: DatabaseConfig,
    pub server: ServerConfig,
    pub logging: LoggingConfig,
}

impl AppConfig {
    pub fn load() -> Result<Self, ConfigError> {
        // 実装
    }
}
```

3. **ユーティリティライブラリ**
   汎用的なユーティリティ関数をモジュール別に整理してください。
```rust
// utils/mod.rs
pub mod string_utils;
pub mod file_utils;
pub mod date_utils;
pub mod validation;

// 便利な関数を再エクスポート
pub use string_utils::capitalize;
pub use file_utils::read_lines;
pub use date_utils::format_timestamp;
```

### 中級課題

4. **Webアプリケーションの構造化**
   RESTful APIを提供するWebアプリケーションを適切なモジュール構造で実装してください。
```
webapp/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── users.rs
│   │   └── posts.rs
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── post.rs
│   ├── database/
│   │   ├── mod.rs
│   │   └── connection.rs
│   └── middleware/
│       ├── mod.rs
│       ├── auth.rs
│       └── logging.rs
```

5. **プラグインシステム**
   動的にプラグインを読み込めるシステムを実装してください。
```rust
// plugins/mod.rs
pub trait Plugin {
    fn name(&self) -> &str;
    fn version(&self) -> &str;
    fn execute(&self, input: &str) -> Result<String, PluginError>;
}

pub struct PluginManager {
    plugins: Vec<Box<dyn Plugin>>,
}

impl PluginManager {
    pub fn new() -> Self {
        // 実装
    }
    
    pub fn register_plugin(&mut self, plugin: Box<dyn Plugin>) {
        // 実装
    }
    
    pub fn execute_plugin(&self, name: &str, input: &str) -> Result<String, PluginError> {
        // 実装
    }
    
    pub fn list_plugins(&self) -> Vec<&str> {
        // 実装
    }
}
```

## 高難易度の課題

### 上級課題

1. **マイクロサービスアーキテクチャ**
   複数のサービスからなるマイクロサービスアーキテクチャを実装してください。
```
microservices/
├── shared/
│   ├── src/
│   │   ├── lib.rs
│   │   ├── models/
│   │   ├── errors/
│   │   └── utils/
├── user-service/
│   ├── src/
│   │   ├── main.rs
│   │   ├── handlers/
│   │   └── repository/
├── order-service/
│   ├── src/
│   │   ├── main.rs
│   │   ├── handlers/
│   │   └── repository/
└── api-gateway/
    ├── src/
    │   ├── main.rs
    │   ├── routing/
    │   └── middleware/
```

共通ライブラリを作成し、各サービスで適切に利用してください。

2. **コンパイラフロントエンド**
   プログラミング言語のコンパイラフロントエンドを実装してください。
```rust
// compiler/
pub mod lexer {
    pub struct Token { /* ... */ }
    pub struct Lexer { /* ... */ }
    
    impl Lexer {
        pub fn tokenize(&mut self, input: &str) -> Result<Vec<Token>, LexError> {
            // 実装
        }
    }
}

pub mod parser {
    use crate::lexer::Token;
    
    pub struct AST { /* ... */ }
    pub struct Parser { /* ... */ }
    
    impl Parser {
        pub fn parse(&mut self, tokens: Vec<Token>) -> Result<AST, ParseError> {
            // 実装
        }
    }
}

pub mod semantic {
    use crate::parser::AST;
    
    pub struct SemanticAnalyzer { /* ... */ }
    
    impl SemanticAnalyzer {
        pub fn analyze(&mut self, ast: AST) -> Result<AST, SemanticError> {
            // 実装
        }
    }
}

pub mod codegen {
    use crate::parser::AST;
    
    pub struct CodeGenerator { /* ... */ }
    
    impl CodeGenerator {
        pub fn generate(&self, ast: &AST) -> Result<String, CodegenError> {
            // 実装
        }
    }
}
```

3. **ゲームエンジンアーキテクチャ**
   モジュラーなゲームエンジンを実装してください。
```rust
// engine/
pub mod core {
    pub mod time;
    pub mod math;
    pub mod events;
}

pub mod graphics {
    pub mod renderer;
    pub mod mesh;
    pub mod texture;
    pub mod shader;
}

pub mod physics {
    pub mod world;
    pub mod body;
    pub mod collision;
}

pub mod audio {
    pub mod source;
    pub mod listener;
    pub mod mixer;
}

pub mod input {
    pub mod keyboard;
    pub mod mouse;
    pub mod gamepad;
}

pub mod scene {
    pub mod node;
    pub mod camera;
    pub mod light;
}

// 各システムを統合するメインエンジン
pub struct Engine {
    // 各システムのインスタンス
}

impl Engine {
    pub fn new() -> Self {
        // 実装
    }
    
    pub fn run(&mut self) -> Result<(), EngineError> {
        // メインループの実装
    }
}
```

### 実践プロジェクト

4. **分散システムフレームワーク**
   分散システムを構築するためのフレームワークを実装してください：
   - ノード間通信
   - 分散コンセンサス
   - 障害検出と回復
   - 負荷分散
   - 設定管理

この課題では、実際の分散システムで使われるアーキテクチャパターンを学び、大規模なRustプロジェクトの構造化技術を体験できます。各モジュールが独立して開発・テストできるような設計を心がけてください。
