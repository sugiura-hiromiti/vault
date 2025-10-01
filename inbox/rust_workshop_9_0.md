# 9章 エラーハンドリング（Error Handling）

## 議論するポイント

- **回復可能エラーと回復不可能エラーの区別**
  - panic!とResult<T, E>の使い分け
  - エラーの性質による適切な処理方法の選択
  - 他の言語の例外処理との違い

- **Result型による明示的エラーハンドリング**
  - エラーの可能性をコンパイル時に強制
  - ?演算子による簡潔なエラー伝播
  - エラーチェーンとコンテキストの保持

- **panic!の適切な使用場面**
  - プロトタイピングとテスト
  - 契約違反とプログラムの不変条件
  - 回復不可能な状況の判断基準

- **エラー設計の哲学**
  - 失敗しやすい操作の明示化
  - エラー情報の有用性
  - パフォーマンスとエラーハンドリングのバランス

- **実践的なエラーハンドリングパターン**
  - カスタムエラー型の設計
  - エラーの変換と統合
  - ログとモニタリングとの連携

## 理解度チェック

1. 以下のコードで何が問題でしょうか？
```rust
fn divide(a: f64, b: f64) -> f64 {
    if b == 0.0 {
        panic!("Division by zero!");
    }
    a / b
}
```

2. `unwrap()`、`expect()`、`?`演算子の違いと適切な使用場面を説明してください。

3. 以下のコードを?演算子を使って書き換えてください：
```rust
fn read_file_content(path: &str) -> Result<String, std::io::Error> {
    let mut file = match std::fs::File::open(path) {
        Ok(file) => file,
        Err(e) => return Err(e),
    };
    
    let mut content = String::new();
    match file.read_to_string(&mut content) {
        Ok(_) => Ok(content),
        Err(e) => Err(e),
    }
}
```

4. カスタムエラー型を作成する利点は何ですか？

5. いつpanic!を使い、いつResult型を使うべきかの判断基準を説明してください。

## 課題

### 基礎課題

1. **安全な計算機**
   エラーハンドリングを適切に行う計算機を実装してください。
```rust
#[derive(Debug)]
enum CalculatorError {
    DivisionByZero,
    InvalidOperation,
    Overflow,
}

impl std::fmt::Display for CalculatorError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for CalculatorError {}

struct Calculator;

impl Calculator {
    fn add(a: i32, b: i32) -> Result<i32, CalculatorError> {
        // オーバーフローをチェック
    }
    
    fn subtract(a: i32, b: i32) -> Result<i32, CalculatorError> {
        // 実装
    }
    
    fn multiply(a: i32, b: i32) -> Result<i32, CalculatorError> {
        // 実装
    }
    
    fn divide(a: i32, b: i32) -> Result<i32, CalculatorError> {
        // ゼロ除算をチェック
    }
    
    fn power(base: i32, exp: u32) -> Result<i32, CalculatorError> {
        // 実装
    }
}
```

2. **設定ファイル読み込み**
   設定ファイルを安全に読み込む機能を実装してください。
```rust
use std::collections::HashMap;

#[derive(Debug)]
enum ConfigError {
    FileNotFound,
    ParseError(String),
    MissingField(String),
    InvalidValue(String),
}

impl std::fmt::Display for ConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for ConfigError {}

#[derive(Debug)]
struct Config {
    database_url: String,
    port: u16,
    debug: bool,
    max_connections: u32,
}

impl Config {
    fn from_file(path: &str) -> Result<Self, ConfigError> {
        // ファイルを読み込み、パースして設定を作成
    }
    
    fn from_env() -> Result<Self, ConfigError> {
        // 環境変数から設定を読み込み
    }
    
    fn validate(&self) -> Result<(), ConfigError> {
        // 設定値の妥当性をチェック
    }
}
```

3. **ユーザー入力バリデーター**
   ユーザー入力を検証する機能を実装してください。
```rust
#[derive(Debug)]
enum ValidationError {
    TooShort { min_length: usize },
    TooLong { max_length: usize },
    InvalidFormat(String),
    InvalidCharacter(char),
    Required,
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for ValidationError {}

struct Validator;

impl Validator {
    fn validate_email(email: &str) -> Result<(), ValidationError> {
        // メールアドレスの形式をチェック
    }
    
    fn validate_password(password: &str) -> Result<(), ValidationError> {
        // パスワードの強度をチェック
    }
    
    fn validate_username(username: &str) -> Result<(), ValidationError> {
        // ユーザー名の形式をチェック
    }
    
    fn validate_phone_number(phone: &str) -> Result<(), ValidationError> {
        // 電話番号の形式をチェック
    }
}
```

### 中級課題

4. **ファイル処理システム**
   複数のエラー型を統合したファイル処理システムを実装してください。
```rust
use std::io;
use std::num::ParseIntError;

#[derive(Debug)]
enum FileProcessError {
    Io(io::Error),
    Parse(ParseIntError),
    InvalidFormat(String),
    EmptyFile,
    TooLarge { size: u64, max_size: u64 },
}

impl From<io::Error> for FileProcessError {
    fn from(error: io::Error) -> Self {
        // 実装
    }
}

impl From<ParseIntError> for FileProcessError {
    fn from(error: ParseIntError) -> Self {
        // 実装
    }
}

impl std::fmt::Display for FileProcessError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for FileProcessError {}

struct FileProcessor;

impl FileProcessor {
    fn process_csv(path: &str) -> Result<Vec<Vec<String>>, FileProcessError> {
        // CSVファイルを処理
    }
    
    fn process_numbers(path: &str) -> Result<Vec<i32>, FileProcessError> {
        // 数値ファイルを処理
    }
    
    fn validate_file_size(path: &str, max_size: u64) -> Result<(), FileProcessError> {
        // ファイルサイズをチェック
    }
    
    fn backup_file(src: &str, dst: &str) -> Result<(), FileProcessError> {
        // ファイルをバックアップ
    }
}
```

5. **HTTPクライアント**
   エラーハンドリングを含むHTTPクライアントを実装してください。
```rust
#[derive(Debug)]
enum HttpError {
    NetworkError(String),
    InvalidUrl(String),
    Timeout,
    BadStatus { code: u16, message: String },
    ParseError(String),
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for HttpError {}

struct HttpClient {
    timeout: std::time::Duration,
    base_url: String,
}

impl HttpClient {
    fn new(base_url: String, timeout_secs: u64) -> Self {
        // 実装
    }
    
    fn get(&self, path: &str) -> Result<String, HttpError> {
        // GET リクエストを送信
    }
    
    fn post(&self, path: &str, body: &str) -> Result<String, HttpError> {
        // POST リクエストを送信
    }
    
    fn download_file(&self, url: &str, path: &str) -> Result<(), HttpError> {
        // ファイルをダウンロード
    }
}
```

## 高難易度の課題

### 上級課題

1. **分散システムエラーハンドリング**
   分散システムで発生する様々なエラーを統合的に処理するシステムを実装してください。
```rust
use std::time::Duration;

#[derive(Debug)]
enum DistributedError {
    NetworkPartition,
    NodeFailure { node_id: String },
    ConsensusFailure,
    ReplicationError { failed_nodes: Vec<String> },
    Timeout { operation: String, duration: Duration },
    DataCorruption { checksum_expected: String, checksum_actual: String },
    InsufficientReplicas { required: usize, available: usize },
}

impl std::fmt::Display for DistributedError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl std::error::Error for DistributedError {}

struct DistributedSystem {
    nodes: Vec<String>,
    replication_factor: usize,
}

impl DistributedSystem {
    fn new(nodes: Vec<String>, replication_factor: usize) -> Self {
        // 実装
    }
    
    fn write(&mut self, key: String, value: String) -> Result<(), DistributedError> {
        // 分散書き込み（レプリケーション付き）
    }
    
    fn read(&self, key: &str) -> Result<String, DistributedError> {
        // 分散読み込み（一貫性チェック付き）
    }
    
    fn handle_node_failure(&mut self, node_id: &str) -> Result<(), DistributedError> {
        // ノード障害の処理
    }
    
    fn recover_from_partition(&mut self) -> Result<(), DistributedError> {
        // ネットワーク分断からの回復
    }
}
```

2. **リトライ機構付きエラーハンドリング**
   指数バックオフとサーキットブレーカーパターンを実装してください。
```rust
use std::time::{Duration, Instant};

#[derive(Debug)]
enum RetryError<E> {
    MaxRetriesExceeded { attempts: usize, last_error: E },
    CircuitBreakerOpen,
    Timeout,
}

impl<E: std::fmt::Display> std::fmt::Display for RetryError<E> {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // 実装
    }
}

impl<E: std::error::Error + 'static> std::error::Error for RetryError<E> {}

#[derive(Debug, Clone)]
struct RetryConfig {
    max_attempts: usize,
    initial_delay: Duration,
    max_delay: Duration,
    backoff_multiplier: f64,
    timeout: Duration,
}

enum CircuitState {
    Closed,
    Open { opened_at: Instant },
    HalfOpen,
}

struct CircuitBreaker {
    state: CircuitState,
    failure_count: usize,
    failure_threshold: usize,
    recovery_timeout: Duration,
}

impl CircuitBreaker {
    fn new(failure_threshold: usize, recovery_timeout: Duration) -> Self {
        // 実装
    }
    
    fn call<F, T, E>(&mut self, operation: F) -> Result<T, RetryError<E>>
    where
        F: FnOnce() -> Result<T, E>,
        E: std::error::Error,
    {
        // サーキットブレーカー付きで操作を実行
    }
}

struct RetryExecutor {
    config: RetryConfig,
    circuit_breaker: CircuitBreaker,
}

impl RetryExecutor {
    fn new(config: RetryConfig, circuit_breaker: CircuitBreaker) -> Self {
        // 実装
    }
    
    fn execute<F, T, E>(&mut self, operation: F) -> Result<T, RetryError<E>>
    where
        F: Fn() -> Result<T, E>,
        E: std::error::Error + Clone,
    {
        // リトライ機構付きで操作を実行
    }
}
```

3. **エラー追跡とメトリクス**
   エラーの発生状況を追跡し、メトリクスを収集するシステムを実装してください。
```rust
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};

#[derive(Debug, Clone)]
struct ErrorMetrics {
    error_type: String,
    count: u64,
    first_occurrence: SystemTime,
    last_occurrence: SystemTime,
    average_frequency: f64,
}

struct ErrorTracker {
    metrics: Arc<Mutex<HashMap<String, ErrorMetrics>>>,
    alert_thresholds: HashMap<String, u64>,
}

impl ErrorTracker {
    fn new() -> Self {
        // 実装
    }
    
    fn record_error<E: std::error::Error>(&self, error: &E) {
        // エラーを記録
    }
    
    fn get_metrics(&self, error_type: &str) -> Option<ErrorMetrics> {
        // 指定されたエラータイプのメトリクスを取得
    }
    
    fn get_all_metrics(&self) -> HashMap<String, ErrorMetrics> {
        // 全てのメトリクスを取得
    }
    
    fn set_alert_threshold(&mut self, error_type: String, threshold: u64) {
        // アラート閾値を設定
    }
    
    fn check_alerts(&self) -> Vec<String> {
        // 閾値を超えたエラーのリストを返す
    }
    
    fn reset_metrics(&self) {
        // メトリクスをリセット
    }
}

// エラートラッキング付きのResult型
struct TrackedResult<T, E> {
    result: Result<T, E>,
    tracker: Arc<ErrorTracker>,
}

impl<T, E: std::error::Error> TrackedResult<T, E> {
    fn new(result: Result<T, E>, tracker: Arc<ErrorTracker>) -> Self {
        if let Err(ref error) = result {
            tracker.record_error(error);
        }
        Self { result, tracker }
    }
    
    fn unwrap(self) -> T {
        self.result.unwrap()
    }
    
    fn map<U, F>(self, f: F) -> TrackedResult<U, E>
    where
        F: FnOnce(T) -> U,
    {
        TrackedResult::new(self.result.map(f), self.tracker)
    }
    
    fn and_then<U, F>(self, f: F) -> TrackedResult<U, E>
    where
        F: FnOnce(T) -> Result<U, E>,
    {
        TrackedResult::new(self.result.and_then(f), self.tracker)
    }
}
```

### 実践プロジェクト

4. **障害耐性システムの構築**
   実際のプロダクションシステムで使われる障害耐性パターンを実装してください：
   - 複数レベルのフォールバック機構
   - 段階的な機能縮退（graceful degradation）
   - 自動回復とヘルスチェック
   - 分散トレーシングとエラー相関

この課題では、Netflix OSS、Google SRE、Amazon Well-Architected Frameworkなどで使われる実際の障害耐性パターンを学び、Rustのエラーハンドリング機能を使った堅牢なシステムの構築を体験できます。
