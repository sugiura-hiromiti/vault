---
id: 25062511413213
aliases: []
tags: []
created: 250625 11:41:32
updated: 250625 12:41:37
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
