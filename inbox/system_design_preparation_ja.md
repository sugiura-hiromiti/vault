# システムデザイン準備

-   システムデザインの質問にどう準備し、どう答えるか

## 目的

*大規模分散システムを学んで実装することは簡単ではありません。1か月で習得できるものだと誤解させたくはありません。*\
このリポジトリが目指すのは、ソフトウェアエンジニアや学生が、大規模システムを設計する際の思考プロセスや、大手企業がどのように難しい課題を解決してきたかについて大まかな理解を得ることです。\
また最近では、企業がシステムデザインに関するオープンエンドな面接を行う傾向があり、実際にそのようなシステムを扱った経験がないエンジニアにとっては難しいこともあります。

この資料は次のユースケース向けのリンク/ドキュメント集です： a)
システムデザインやオープンエンド面接の準備\
b)
大規模システムがどのように動き、新しいシステムを設計する思考プロセスを学ぶ

## インデックス

-   [ ] [出発点](#start)\
-   [ ] [基礎](#basics)\
-   [ ] [面接での答え方](#howtoans)\
-   [ ] [私の面接でのアプローチ手順](#myapproach)\
-   [ ] [よくあるデザイン問題](#designques)\
-   [ ] [アーキテクチャ](#architecture)\
-   [ ] [企業エンジニアリングブログリンク](#blog)\
-   [ ] [時間がないとき](#tldr)

## `<a name='start'>`{=html}出発点`</a>`{=html}

まずは全体像をつかむために以下の講義を見ることを推奨します。とても有用です：

-   [Gaurav Sen
    のシステムデザインシリーズ](https://www.youtube.com/playlist?list=PLMCXHnjXnTnvo6alSjVkgxV-VH6EPyvoX)\
    ロードバランシングやメッセージキューといった基礎から始まり、WhatsappやTinderのようなシステム全体の構築に進みます。

-   [David Malan の CS75
    スケーラビリティ講義](https://www.youtube.com/watch?v=-W9F__D3oY4&list=PLmhRNZyYVpDmLpaVQm3mK5PY5KB_4hLjE&index=10)\
    他の講義も必要に応じて見てください。

-   [David Huffman
    のスケーリング講義](https://www.udacity.com/course/web-development--cs253)
    ([Youtubeリンク](https://www.youtube.com/watch?v=pjNTgULVVf4&list=PLVi1LmRuKQ0NINQfjKLVen7J2lZFL35wP&index=1))

-   [Scalability for Dummies](http://www.lecloud.net/tagged/scalability)

-   [Designing Data Intensive Applications](https://dataintensive.net/)\
    大規模システムや実際の構築時に直面する課題について書かれた最高の本のひとつです。特にデータ指向アプリケーションに焦点を当てています。

-   [System Design Interview Preparation Series by
    CodeKarle](https://www.youtube.com/watch?v=3loACSxowRU&list=PLhgw50vUymycJPN6ZbGTpVKAJ0cL4OEH3)\
    よく聞かれるシステムデザイン面接の質問を、非常に詳細かつわかりやすく解説しています。

これらの講演を見れば、この種の問題にどう向き合うかの出発点を得られるでしょう。

## `<a name='basics'>`{=html}基礎`</a>`{=html}

進む前に、以下のトピックについてある程度理解しておくべきです（順不同）。

1.  OSの基礎：ファイルシステム、仮想メモリ、ページング、命令実行サイクルの仕組みなど\
    （初心者ならSilbershatz、本格的に学ぶならStallingsの本）
2.  ネットワーク基礎：TCP/IPスタック、インターネット、HTTP、TCP/IPの基礎。\
    cs75の最初の講義が概要を掴むのに良い。[Computer Networking: A
    Top-Down
    Approach](http://www.amazon.com/Computer-Networking-Top-Down-Approach-Edition/dp/0132856204)推奨。
3.  並行性基礎：スレッド、プロセス、言語におけるスレッド、ロック、ミューテックスなど。
4.  DB基礎：SQL vs
    NoSQL、ハッシュとインデックス、EAV、シャーディング、キャッシュ、マスター/スレーブ。
5.  基本的なWebアーキテクチャ：ロードバランサ、プロキシ、サーバ、DBサーバ、キャッシュサーバ、ログ、大規模データ処理などの役割。
6.  [CAP定理](http://robertgreiner.com/2014/08/cap-theorem-revisited/)の概要。直接問われることは少ないが、大規模設計の助けになる。

## `<a name='howtoans'>`{=html}面接での答え方`</a>`{=html}

-   [hiredintech](http://www.hiredintech.com/system-design)の動画が非常に有用。ユースケース定義
    → 抽象的にコンポーネントと相互作用を考える →
    ボトルネックやトレードオフを説明、という流れ。

-   [Cracking the Coding Interview
    のシステムデザイン章](http://www.flipkart.com/cracking-coding-interview-150-programming-questions-solutions-english-5th/p/itmdz4pvzbhcv6uv)：小さなケースから始め、大きく広げる方法。

-   最良の準備は模擬面接。質問を選び、自分で設計 →
    実際の設計事例と比較。練習に勝るものなし。

## `<a name='myapproach'>`{=html}私の面接でのアプローチ手順`</a>`{=html}

面接時に私が取る思考手順：

a)  問題を正しく理解する。必ず最初に確認する。\
b)  ユースケース。利用目的、規模、制約（RPS,
    書き込み/読み込み量など）を把握する。\
c)  小規模（100ユーザー）で解いてみる。データ構造やコンポーネントを抽象化できる。\
d)  コンポーネントを列挙し、相互作用を整理。\
e)  必ず以下を考慮：処理/サーバ、ストレージ、キャッシュ、並行性/通信、セキュリティ、LB/プロキシ、CDN、収益化。\
f)  特殊ケース。例：サムネイル保存はFSで十分か？大規模ならNoSQL？\
g)  各コンポーネントでユースケースに沿った最適化やトレードオフを検討。\
h)  [スケールアウト/アップ](http://highscalability.com/blog/2014/5/12/4-architecture-issues-when-scaling-web-applications-bottlene.html)。\
i)  面接官に追加ケースがあるか確認。その会社のアーキを知っておくと有利。

## `<a name='designques'>`{=html}よくあるデザイン問題`</a>`{=html}

-   Amazonの「最近見た商品」ページ\
-   マルチプレイヤーのオンラインポーカーゲーム\
-   URL短縮サービス\
-   検索エンジン（クローリング、ハッシュなど）\
-   Dropboxのアーキテクチャ\
-   写真共有サイト（Instagram等）\
-   ニュースフィード（Facebook, Twitter）\
-   地図を用いたアプリ（ホテル/ATM検索）\
-   malloc/freeとGC設計\
-   価格比較サイト（junglee.com等）\
-   IMアプリ（Whatsapp, FBチャット）\
-   Google Docsのような共同編集システム\
-   ストリームからの上位N件集計\
-   選挙管理システム（投票集計）\
-   ログ監視システム（例外/容量警告）\
-   Google Mapsの設計\
-   Zoomのようなビデオ会議システム

## `<a name='architecture'>`{=html}アーキテクチャ`</a>`{=html}

-   Google検索の基礎\
-   Kafka, RabbitMQ\
-   Redis, MongoDB, Cassandra の概要\
-   Google File System 論文\
-   Googleアーキテクチャ\
-   Instagram、Facebookメモリキャッシュ拡張、Twitterスケーリングなど\
-   Facebook Graph API, Haystack Storage\
-   YouTube最適化

## `<a name='blog'>`{=html}企業エンジニアリングブログリンク`</a>`{=html}

企業ごとのブログは面接で極めて有用。面接官の領域と関連する質問が出る。

Airbnb, Amazon, AWS, Dropbox, Quora, Etsy, Facebook, Flickr, Foursquare,
Google, Groupon, Instagram, LinkedIn, Pinterest, SoundCloud, Square,
Reddit, GitHub, Netflix, Twilio, Twitter, Uber, Walmart Labs, Yelp
...など多数。

## `<a name='tldr'>`{=html}時間がないとき`</a>`{=html}

ショートカットは推奨しないが、1週間以内に面接がある場合：

a)  CS76とUdacityのスケーリング講義を見る\
b)  面接先の企業ブログを読む\
c)  [hiredintechのプロセス解説](http://www.hiredintech.com/system-design/the-system-design-process/)を見る\
d)  以下のキーワードを頭に入れておく：処理/サーバ、ストレージ、キャッシュ、並行性/通信、セキュリティ、LB/プロキシ、CDN、収益化

頑張ってください 👍\
プルリク歓迎！
