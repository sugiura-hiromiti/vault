---
id: 25060119373093
aliases: []
tags: []
created: 250601 19:37:30
updated: 250609 08:46:45
---

# kernelから描画する


- [ ] bootloaderでdevice treeを取得 [due:: 250607]
	- [ ] system_table -> configuration tableを介して、GUIDを比較して取得
		- [x] configuration tableを取得する [completion:: 250606]


- [ ] device treeの解析

- [ ] gpu driverの作成
	- [ ] PCI情報を走査して（PCI enumeration）virtio-gpu-pciを探し出す
	- [ ] MMIOを介してgpuを初期化
	- [ ] FrameBufferの確保

