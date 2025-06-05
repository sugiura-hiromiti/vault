---
id: 25052212265334
aliases: 
tags:
  - index
created: 250522 12:26:53
updated: 250605 12:48:23
---
# bookmark

```dataviewjs
dv.table(
	["link", "tags", "file"],
	dv.pages('#clippings').filter(p => {
		const st = p.file.frontmatter.status;
		return st === "bm";
	}).map(p => {
		const title = p.file.frontmatter.title;
		const source = p.file.frontmatter.source;
		const link = `[${title}](${source})`;
		return [
			link,
			p.file.frontmatter.tags,
			dv.fileLink(p.file.path, false, p.file.path),
		];

		}
	)
)
```

# reading list

```dataviewjs
dv.table(
	["link", "status"],
	dv.pages('#clippings').filter(p => {
		const st = p.file.frontmatter.status;
		return st === "unread" || st === "read";
	}).map(p => 
		[
			dv.fileLink(p.file.path, false, p.file.frontmatter.title),
			p.file.frontmatter.status
		]
	)
)
```