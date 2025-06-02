---
id: 25060207311435
aliases: []
tags: []
created: 250602 07:31:14
updated: 250602 11:32:22
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
		.filter(task => !task.completed)
)
```

# reminder



# recently done
