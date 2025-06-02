---
id: 25060119373093
aliases: []
tags: []
created: 250601 19:37:30
updated: 250602 10:04:00
---
- [ ] #task gpu driverの作成
	- [ ] #task bootloaderでdevice treeを取得 
		- [ ] #task system_table -> configuration tableを介して、GUIDを比較して取得
	- [ ] #task PCI情報を走査して（PCI enumeration）を用いてvirtio-gpu-pciを探し出す
	- [ ] #task MMIOを介してgpuを初期化
	- [ ] #task FrameBufferの確保

