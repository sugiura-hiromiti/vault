---
id: 25060119373093
aliases: []
tags: []
created: 250601 19:37:30
updated: 2025-07-30 09:00:06
---

# kernelから描画する


- [x] bootloaderでdevice treeを取得 [due:: 250607] [completion:: 250617]
	- [x] system_table -> configuration tableを介して、GUIDを比較して取得 [completion:: 250617]
		- [x] configuration tableを取得する [completion:: 250617]

- [ ] パーサージェネレータの作成
	- [-] derive macroでパーサーの自動生成（serdeの様に）
	- [ ] ↑attribute macroの方が良いかも
	- [ ] tree walkerの実装
		- [ ] treeデータ構造も定義

- [ ] device treeの解析 [completion:: 250619]
	- [ ] dtbフォーマットのバイナリ解析 [completion:: 250619]
		- [ ] バイナリパーサーの作製 [completion:: 250619]
			- 汎用的にしたい

- [ ] gpu driverの作成
	- [ ] PCI情報を走査して（PCI enumeration）virtio-gpu-pciを探し出す
	- [ ] MMIOを介してgpuを初期化
	- [ ] FrameBufferの確保


- [ ] gpu driverを実装したら一度リファクタしたい