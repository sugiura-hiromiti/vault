---
created: 250522 09:36:44
updated: 250523 13:23:12
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
---
```dataviewjs
dv.table(
	["slice", "formatted"],
	dv.pages()
	.filter(p => p.file.frontmatter.created !== undefined)
	.map(p => {
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
		return [
			p.file.frontmatter.created.slice(0, 6),
			formatted_today
		];
	})
)
```

---
