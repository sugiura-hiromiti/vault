---
aliases: [{{date}}]
tags: [{{date}}]
---

#### todo-today

- [ ] ckecks todo today!(@[[{{date}}]] 7:00)

```dataviewjs
const key ='(@[[{{date}}]]'

let script = await dv.io.load('script/task.js');
script = `const tl = ${script}
.filter(task => !task.completed)
.filter(task => task.text.includes('${key}'));
dv.taskList(tl);`;

dv.executeJs(script);
```

#### notes-today

```dataviewjs
const today = '{{date}}'
dv.list(
	dv.pages()
		.filter(p => {
			const date = p.file.mday;
			const year = `${date.c.year}`;
			const month = `${date.c.month + 100}`.slice(1, 3);
			const day = `${date.c.day + 100}`.slice(1, 3);

			const formatted_today = `${year}-${month}-${day}`;

			return today === formatted_today;
		})
		.map(p => dv.fileLink(p.file.path, false, p.file.path))
)
```

---
