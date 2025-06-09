---
id: 25060614592354
aliases: []
tags:
  - zenn
  - osdev
  - rust
created: 250606 14:59:23
updated: 2025-06-10T06:33
---

- カーネルが呼び出せない
	- x86_64向けビルドでは動作する
- 原因の洗い出し
	- exit_boot_servicesが失敗した？
	- カーネルのアドレスが間違ってる？
		- elfのパースが間違ってる？
	- 例外が発生した？
	- boot service終了後にboot serviceを呼び出している？
- デバッグ
	- printデバッグ
	- mnemonicデバッグ（バイナリブレークポイント）
		- qemuコンソールでのコマンド
			- `info registers`
			- `x /10i 0xXXXXXXX`
	- `wfi`と`wfe`
		- panic_handlerには`wfi`、バイナリブレークポイントには`wfe`というような使い分けをした
- 解決
	- UEFIはMMUを有効化する
	- uefiが管理するメモリ領域においてはidentity mappedである
	- そのほかの領域については実装によって異なる
	- つまりx86_64向けビルドではMMUがtity mappedだった
	- MMUを無効化すると良い