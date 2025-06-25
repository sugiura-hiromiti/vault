---
id: 25062511413213
aliases:
  - dataviewjs
  - cheetsheet
tags: 
created: 250625 11:41:32
updated: 250625 12:56:01
---

### inline query

`= this.file.cday` `= this.file.mday`

### span

```dataviewjs
const a = 666;
const b = 666;
dv.span(a+b)
```

### (markdown) table

```dataviewjs
const s = [
	["a", 0, "zero"],
	["b", 1, "one"],
	["c", 2, "two"],
];
const dvs = dv.array(s);

const header = ["alpha", "literal", "char"];
dv.table(header, dvs);

const mdt = dv.markdownTable(header, dvs);

// https://blacksmithgu.github.io/obsidian-dataview/api/code-reference/#render
dv.paragraph(mdt);
dv.span(mdt);
dv.el('div', "hoge",
	{
		attr: {
			style: "color:blue;text-align:center;"
		}
	}
);

// copy contents to clipboard
// navigator.clipboard.writeText(mdt);
```

where is matter?

[defines-react-components:: true]

### with element

```dataviewjs
s = [
  ["阪神", 20, 13],
  ["DeNA", 19, 14],
  ["広島", 18, 16]
]

dv.table(["チーム", "勝ち", "負け"], dv.array(s))

const e = dv.el("button", "copy")
e.onclick = function(){
  new Notice("copy")
  t = dv.markdownTable(["チーム", "勝ち", "負け"], dv.array(s))
  navigator.clipboard.writeText(t)
}
```