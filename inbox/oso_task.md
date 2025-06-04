---
id: 25060119373093
aliases: []
tags: []
created: 250601 19:37:30
updated: 250604 16:42:06
---

# kernelから描画する

- [ ] gpu driverの作成
	- [ ] PCI情報を走査して（PCI enumeration）virtio-gpu-pciを探し出す
	- [ ] MMIOを介してgpuを初期化
	- [ ] FrameBufferの確保


- [ ] bootloaderでdevice treeを取得 [due:: 250607]
	- [ ] system_table -> configuration tableを介して、GUIDを比較して取得
		- [ ] configuration tableを取得する

