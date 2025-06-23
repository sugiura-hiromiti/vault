---
id: 25062309430009
aliases:
  - binary parser idea
  - parser generator
tags:
  - rust
  - parser
created: 250623 09:43:00
updated: 250623 13:18:34
---

- パーサ生成フレームワーク
	- 型主導
		- [i] データと操作を型で表現することで堅牢に
		- 型に対してパーサーを付与するマクロ
			- [attribute macro](https://doc.rust-lang.org/reference/procedural-macros.html#r-macro.proc.attribute)が適していそう
				- 構造体や列挙型に対して
	- コンビネータ
		- 必要そうなprimitiveコンビネータ
			- Functor/Monad的操作：map, flat_map, and_then
			- フロー制御操作：or, optional, many0, many1
			- 構造文脈適応：preced, terminate, delimiter
		- [?] コンビネータを型で表すには
	- 状態と意味論を持ち込める様に
		- [i] 型で表現された意味論を受け取る
			- [?] const genericsか[PhantomData](https://qnighy.hatenablog.com/entry/2018/01/14/220000)でマークか
		- 状態は動的に決まるためデータとして表す方が良い