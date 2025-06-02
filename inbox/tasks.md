---
id: 25060207311435
aliases: []
tags: []
created: 250602 07:31:14
updated: 250602 11:56:31
---

# tasks

```dataviewjs
dv.taskList(
	dv.pages().file.tasks
		/*
		.filter(task => {
			const tags = task.tags;
			console.log(tags);
			const is_task = tags.includes('#task');
			return is_task && !task.completed;
		})
		*/
		.filter(task => {
			let is_list = false;
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
				is_list = true;
			}
			
			return !is_list && !task.completed;
		})
)
```

# reminder



# recently done
