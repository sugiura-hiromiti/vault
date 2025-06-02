---
id: 25060207311435
aliases: []
tags: []
created: 250602 07:31:14
updated: 250602 11:44:29
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


		})
)
```

# reminder



# recently done
