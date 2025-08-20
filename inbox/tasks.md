---
id: 25060207311435
aliases: 
tags:
  - index
created: 250602 07:31:14
updated: 2025-07-30 09:00:06
---

# reminder

```dataviewjs
const tl = dv.pages().file.tasks
	.filter(task => !task.not_task)
	.filter(task => {
		const task_status = task.status;

		if (
			task_status === "?"
			|| task_status === "!"
			|| task_status === "b"
			|| task_status === "c"
			|| task_status === "d"
			|| task_status === "f"
			|| task_status === "i"
			|| task_status === "k"
			|| task_status === "l"
			|| task_status === "p"
			|| task_status === "u"
			|| task_status === "w"
		) {
			return false;
		} else {
			return true;
		}

	})
	.filter(task => !task.completed)
	.filter(task => !task.text.includes("{{date}}"))
	.filter(task => task.text.includes('(@'));

dv.taskList(tl);
```

# tasks

```dataviewjs
const tl = dv.pages().file.tasks
	.filter(task => !task.not_task)
	.filter(task => {
		const task_status = task.status;

		if (
			task_status === "?"
			|| task_status === "!"
			|| task_status === "b"
			|| task_status === "c"
			|| task_status === "d"
			|| task_status === "f"
			|| task_status === "i"
			|| task_status === "k"
			|| task_status === "l"
			|| task_status === "p"
			|| task_status === "u"
			|| task_status === "w"
		) {
			return false;
		} else {
			return true;
		}

	})
	.filter(task => !task.completed)
	.filter(task => !task.text.includes('(@'));
dv.taskList(tl);
```
