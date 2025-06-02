---
id: 25060119373093
aliases: []
tags: []
created: 250601 19:37:30
updated: 250602 11:57:46
---
- [ ] gpu driverの作成
	- [ ] bootloaderでdevice treeを取得
		- [ ] system_table -> configuration tableを介して、GUIDを比較して取得
	- [ ] PCI情報を走査して（PCI enumeration）を用いてvirtio-gpu-pciを探し出す
	- [ ] MMIOを介してgpuを初期化
	- [ ] FrameBufferの確保

