---
id: 25062511413213
aliases:
  - dataviewjs
  - cheetsheet
tags: 
created: 250625 11:41:32
updated: 2025-07-25 13:20:47
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

### dynamic header

```dataviewjs
dv.header(4, new Date().toString());
```

abc

# interactive text

```dataviewjs
dv.span("ノート検索");
const a = dv.el("input");
a.placeholder = "keyword";
a.style = "font-size:22px;background:whitesmoke;width:100%;padding:5px 10px;border-radius:6px;";

dv.paragraph("---");

const counter = dv.el("div","");
const list_views = dv.el("div", '');

a.onkeyup = function(){
	const inp = a.value;
	const d = dv.pages()
		.filter(x => {
			const fname = x.file.name;
			const fname_match = fname.includes(inp);
			
			let alias_match = false;
			if (x.file.frontmatter.aliases !== undefined
				&& x.file.frontmatter.aliases !== null) {
				const note_alias = x.file.frontmatter.aliases;
				console.log('note_alias', note_alias);
				alias_match = note_alias.filter(
					a => a.toString().includes(inp))
					.length !== 0;
			}
			
			return fname_match || alias_match;
		})
		.sort(x => x.file.mday, "desc")
		.map(n =>
			'<a '
			+ 'data-tooltip-position="top"'
			+ 'aria-label="' + n.file.path + '"'
			+ 'data-href="' + n.file.path + '"'
			+ 'href="' + n.file.path + '"'
			+ 'class="internal-link"'
			+ 'target="_blank"'
			+ 'rel="noopener nofollow"'
			+ '>'
			+ n.file.name
			+ '</a>'
		);
	/*
	const mdl = dv.markdownList(d);
	dv.span(mdl);
	*/
	list_views.innerHTML = d.join("<br>");
	counter.innerHTML = d.length;
}
```
