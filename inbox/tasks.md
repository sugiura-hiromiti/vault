---
id: 25060207311435
aliases: 
tags:
  - index
created: 250602 07:31:14
updated: 250604 20:02:55
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
		.filter(task => !task.text.includes('(@'))
)
```

# reminder

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
		.filter(task => task.text.includes('(@'))
)
```

# recently done

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
			
			return !is_list && task.completed;
		})
		.filter(task => {
			const when_completed = parseInt(task.completion);
			console.log('————————————---',when_completed);
			
			const today = new Date();
			const last_week = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
			const last_week_year = (last_week.getFullYear() % 100) * 10000;
			const last_week_month = (last_week.getMonth() + 1) * 100;
			const last_week_date = last_week.getDate();
			
			const last_week_int = last_week_year + last_week_month + last_week_date;
			console.log('————————————————————————————————————————————————---',last_week_int);
			
			return when_completed > last_week_int;
		})
)
```