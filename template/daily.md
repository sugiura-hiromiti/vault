---
aliases: [{{date}}]
tags: [{{date}}]
created: {{date}} {{time}}
updated: {{date}} {{time}}
---

- [ ] ckecks todo today!(@[[{{date}}]] 7:00)

---

#### todo-today

```dataviewjs
const today = new Date();
const year = today.getFullYear();
const month = `${today.getMonth() + 101}`.substring(1);
const date = today.getDate();
const key = `(@[[${year}-${(month)}-${date}]]`;

let script = await dv.io.load('script/task.js');
script = `const tl = ${script}
.filter(task => !task.completed)
.filter(task => task.text.includes('${key}'));
dv.taskList(tl);`;

dv.executeJs(script);
```

#### created notes

```dataviewjs
dv.list(
	dv.pages()
		.filter(p => p.file.frontmatter.created !== undefined)
		.filter(p => {
			const date = p.file.frontmatter.created.slice(0,11);

			const today = new Date();

			const year = `${today.getYear()}`;
			const month = `${today.getMonth() + 101}`.slice(1, 3);
			const day = `${today.getDate() + 100}`.slice(1, 3);

			const formatted_today = `${year}-${month}-${day}`;

			return date === formatted_today;
		})
		.map(p => dv.fileLink(p.file.path, false, p.file.path))
)
```
