# 8章 一般的なコレクション（Common Collections）

## 議論するポイント

- **ヒープ上のデータ構造**
  - スタックとヒープの使い分け
  - 動的サイズのデータ管理
  - メモリ効率とパフォーマンスのトレードオフ

- **Vec<T>の内部実装**
  - 動的配列の成長戦略
  - 容量（capacity）と長さ（length）の違い
  - 再配置（reallocation）のコスト

- **Stringの複雑さ**
  - UTF-8エンコーディングの取り扱い
  - 文字、バイト、グラフェムクラスターの違い
  - 文字列操作の安全性

- **HashMap<K, V>の特性**
  - ハッシュ関数とハッシュ衝突
  - 所有権とライフタイムの考慮
  - パフォーマンス特性（O(1)平均時間計算量）

- **コレクション選択の指針**
  - 用途に応じた適切なコレクションの選択
  - メモリ使用量とアクセスパターンの考慮
  - 標準ライブラリの他のコレクション型

## 理解度チェック

1. 以下のコードで何が起こりますか？
```rust
let mut v = vec![1, 2, 3];
let first = &v[0];
v.push(4);
println!("{}", first);
```

2. `String`と`&str`の違いを、メモリ配置の観点から説明してください。

3. HashMapのキーとして使える型の条件は何ですか？

4. 以下の文字列操作のうち、どれが最も効率的ですか？理由も説明してください。
```rust
// A
let s = "Hello".to_string() + " " + "World";

// B
let mut s = String::from("Hello");
s.push_str(" ");
s.push_str("World");

// C
let s = format!("{} {}", "Hello", "World");
```

5. ベクターの容量が不足した時の再配置について説明してください。

## 課題

### 基礎課題

1. **動的配列の操作**
   整数のベクターに対する基本操作を実装してください。
```rust
struct IntVector {
    data: Vec<i32>,
}

impl IntVector {
    fn new() -> Self {
        // 実装
    }
    
    fn push(&mut self, value: i32) {
        // 実装
    }
    
    fn pop(&mut self) -> Option<i32> {
        // 実装
    }
    
    fn sum(&self) -> i32 {
        // 実装
    }
    
    fn average(&self) -> Option<f64> {
        // 実装
    }
    
    fn find_max(&self) -> Option<i32> {
        // 実装
    }
    
    fn remove_duplicates(&mut self) {
        // 実装
    }
}
```

2. **文字列処理ユーティリティ**
   文字列操作の便利関数を実装してください。
```rust
struct StringUtils;

impl StringUtils {
    fn reverse(s: &str) -> String {
        // 実装
    }
    
    fn is_palindrome(s: &str) -> bool {
        // 実装（大文字小文字、空白を無視）
    }
    
    fn word_count(s: &str) -> usize {
        // 実装
    }
    
    fn capitalize_words(s: &str) -> String {
        // 各単語の最初の文字を大文字にする
    }
    
    fn remove_whitespace(s: &str) -> String {
        // 全ての空白文字を削除
    }
}
```

3. **単語頻度カウンター**
   テキスト内の単語の出現頻度を数える機能を実装してください。
```rust
use std::collections::HashMap;

struct WordCounter {
    counts: HashMap<String, usize>,
}

impl WordCounter {
    fn new() -> Self {
        // 実装
    }
    
    fn add_text(&mut self, text: &str) {
        // テキストを単語に分割して頻度をカウント
    }
    
    fn get_count(&self, word: &str) -> usize {
        // 指定された単語の出現回数を返す
    }
    
    fn most_frequent(&self) -> Option<(&String, &usize)> {
        // 最も頻度の高い単語を返す
    }
    
    fn top_n(&self, n: usize) -> Vec<(&String, &usize)> {
        // 頻度の高い順にn個の単語を返す
    }
}
```

### 中級課題

4. **学生成績管理システム**
   学生の成績を管理するシステムを実装してください。
```rust
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Student {
    id: u32,
    name: String,
    grades: Vec<f64>,
}

struct GradeManager {
    students: HashMap<u32, Student>,
}

impl GradeManager {
    fn new() -> Self {
        // 実装
    }
    
    fn add_student(&mut self, id: u32, name: String) -> Result<(), String> {
        // 学生を追加
    }
    
    fn add_grade(&mut self, student_id: u32, grade: f64) -> Result<(), String> {
        // 成績を追加
    }
    
    fn get_average(&self, student_id: u32) -> Option<f64> {
        // 学生の平均点を計算
    }
    
    fn get_class_average(&self) -> f64 {
        // クラス全体の平均点を計算
    }
    
    fn get_top_students(&self, n: usize) -> Vec<(u32, String, f64)> {
        // 成績上位n人を返す
    }
    
    fn get_grade_distribution(&self) -> HashMap<char, usize> {
        // A, B, C, D, Fの分布を返す
    }
}
```

5. **キャッシュシステム**
   LRU（Least Recently Used）キャッシュを実装してください。
```rust
use std::collections::HashMap;

struct LRUCache<K, V> {
    capacity: usize,
    cache: HashMap<K, V>,
    order: Vec<K>,
}

impl<K, V> LRUCache<K, V>
where
    K: Clone + Eq + std::hash::Hash,
    V: Clone,
{
    fn new(capacity: usize) -> Self {
        // 実装
    }
    
    fn get(&mut self, key: &K) -> Option<&V> {
        // 値を取得し、アクセス順序を更新
    }
    
    fn put(&mut self, key: K, value: V) {
        // 値を設定し、必要に応じて古いエントリを削除
    }
    
    fn len(&self) -> usize {
        // 実装
    }
    
    fn is_empty(&self) -> bool {
        // 実装
    }
}
```

## 高難易度の課題

### 上級課題

1. **高性能テキスト検索エンジン**
   転置インデックスを使った検索エンジンを実装してください。
```rust
use std::collections::{HashMap, HashSet};

struct Document {
    id: usize,
    title: String,
    content: String,
}

struct SearchEngine {
    documents: Vec<Document>,
    inverted_index: HashMap<String, HashSet<usize>>,
    word_frequencies: HashMap<usize, HashMap<String, f64>>,
}

impl SearchEngine {
    fn new() -> Self {
        // 実装
    }
    
    fn add_document(&mut self, title: String, content: String) -> usize {
        // ドキュメントを追加し、インデックスを更新
    }
    
    fn search(&self, query: &str) -> Vec<(usize, f64)> {
        // TF-IDFスコアを使った検索結果を返す
    }
    
    fn search_phrase(&self, phrase: &str) -> Vec<usize> {
        // フレーズ検索を実装
    }
    
    fn suggest(&self, partial_word: &str) -> Vec<String> {
        // 単語の補完候補を返す
    }
    
    fn get_similar_documents(&self, doc_id: usize, limit: usize) -> Vec<(usize, f64)> {
        // 類似ドキュメントを返す
    }
}
```

2. **分散ハッシュテーブル**
   一貫性ハッシュを使った分散ハッシュテーブルを実装してください。
```rust
use std::collections::{BTreeMap, HashMap};
use std::hash::{Hash, Hasher};

struct ConsistentHash<T> {
    ring: BTreeMap<u64, T>,
    replicas: usize,
}

impl<T> ConsistentHash<T>
where
    T: Clone + Hash,
{
    fn new(replicas: usize) -> Self {
        // 実装
    }
    
    fn add_node(&mut self, node: T) {
        // ノードをリングに追加
    }
    
    fn remove_node(&mut self, node: &T) {
        // ノードをリングから削除
    }
    
    fn get_node(&self, key: &str) -> Option<&T> {
        // キーに対応するノードを取得
    }
    
    fn get_nodes(&self, key: &str, count: usize) -> Vec<&T> {
        // 複数のレプリカノードを取得
    }
}

struct DistributedHashTable<K, V> {
    nodes: HashMap<String, HashMap<K, V>>,
    hash_ring: ConsistentHash<String>,
    replication_factor: usize,
}

impl<K, V> DistributedHashTable<K, V>
where
    K: Clone + Eq + Hash + std::fmt::Debug,
    V: Clone,
{
    fn new(replication_factor: usize) -> Self {
        // 実装
    }
    
    fn add_node(&mut self, node_id: String) {
        // 新しいノードを追加
    }
    
    fn put(&mut self, key: K, value: V) -> Result<(), String> {
        // キー・バリューペアを保存
    }
    
    fn get(&self, key: &K) -> Option<V> {
        // 値を取得
    }
    
    fn remove(&mut self, key: &K) -> Option<V> {
        // キーを削除
    }
}
```

3. **メモリ効率的なデータ構造**
   大量のデータを効率的に扱うためのカスタムデータ構造を実装してください。
```rust
// Bloom Filter - 確率的データ構造
struct BloomFilter {
    bit_array: Vec<bool>,
    hash_functions: usize,
    size: usize,
}

impl BloomFilter {
    fn new(expected_items: usize, false_positive_rate: f64) -> Self {
        // 実装
    }
    
    fn add(&mut self, item: &str) {
        // アイテムを追加
    }
    
    fn contains(&self, item: &str) -> bool {
        // アイテムが存在する可能性があるかチェック
    }
    
    fn estimated_count(&self) -> usize {
        // 追加されたアイテム数の推定値
    }
}

// Trie - 文字列の効率的な検索
struct TrieNode {
    children: HashMap<char, TrieNode>,
    is_end_of_word: bool,
    value: Option<String>,
}

struct Trie {
    root: TrieNode,
}

impl Trie {
    fn new() -> Self {
        // 実装
    }
    
    fn insert(&mut self, word: &str, value: String) {
        // 単語と値を挿入
    }
    
    fn search(&self, word: &str) -> Option<&String> {
        // 完全一致検索
    }
    
    fn starts_with(&self, prefix: &str) -> Vec<&String> {
        // プレフィックス検索
    }
    
    fn delete(&mut self, word: &str) -> bool {
        // 単語を削除
    }
}
```

### 実践プロジェクト

4. **リアルタイムデータ処理システム**
   ストリーミングデータを効率的に処理するシステムを実装してください：
   - 時系列データの効率的な保存
   - スライディングウィンドウによる集計
   - メモリ使用量の制限と古いデータの自動削除
   - 複数の集計関数（平均、最大、最小、分散など）

この課題では、実際のビッグデータ処理で使われる技術を学び、Rustのコレクションを使った高性能なデータ処理システムの実装を体験できます。
