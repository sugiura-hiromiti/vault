dv.pages().file.tasks
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
