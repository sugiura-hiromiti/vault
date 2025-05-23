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
			const created = p.file.frontmatter.created.slice(0, 6);
			
			const today = new Date();
			
			const year = today.getFullYear() % 100;
			const month = today.getMonth() + 1;
			const date = today.getDate();
			
		
			let formatted_month = '';
			if (month < 10) {
				formatted_month = `0${month}`;
			} else {
				formatted_month = `${month}`;
			}
		
			let formatted_date = '';
			if (date < 10) {
				formatted_date = `0${date}`;
			} else {
				formatted_date = `${date}`;
			}
			
			const formatted_today = `${year}${formatted_month}${formatted_date}`;
			
			return formatted_today === created;
		})
		.map(p => dv.fileLink(p.file.path, false, p.file.path))
)
```