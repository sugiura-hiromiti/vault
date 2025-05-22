---
id: 25052212265334
aliases: 
tags:
  - index
created: 250522 12:26:53
updated: 250522 13:03:48
---
# bookmark

```dataviewjs
dv.table(
	["link", "tags"],
	dv.pages('#clippings').filter(p => {
		const st = p.file.frontmatter.status;
		return st === "bm";
	}).map(p => 
		[
			dv.fileLink(p.file.path, false, p.file.frontmatter.title),
			p.file.frontmatter.tags
		]
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