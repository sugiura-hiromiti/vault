---
id: <% tp.file.creation_date("YYMMDDHHmmssSS") %>
aliases: [<% tp.date.now("YYMMDD") %>]
tags: [daily/<% tp.date.now("YYMMDD") %>]
created: <% tp.file.creation_date("YYMMDD HH:mm:ss") %>
updated: <% tp.file.creation_date("YYMMDD HH:mm:ss") %>
---
```dataviewjs
dv.list(
	dv.pages()
		.filter(p => p.file.frontmatter.created !== undefined)
		.filter(p => {
			const date = p.file.frontmatter.created.slice(0,6);
			
			const today = new Date();
			
			const year = `${today.getYear() % 100}`;
			const month = `${today.getMonth() + 101}`.slice(1, 3);
			const day = `${today.getDate() + 100}`.slice(1, 3);
			
			const formatted_today = `${year}${month}${day}`;
			
			return date === formatted_today;
		})
		.map(p => dv.fileLink(p.file.path, false, p.file.path))
)
```