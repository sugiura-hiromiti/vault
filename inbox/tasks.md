---
id: 25060207311435
aliases: 
tags:
  - index
created: 250602 07:31:14
updated: 2025-07-25 13:08:44
---

# tasks

```dataviewjs
let script=await dv.io.load('script/task.js');
script=`const tl = ${script}`;
script = `${script}.filter(task => !task.completed)`;
script = `${script}.filter(task => !task.text.includes('(@'));`;
script =`${script} dv.taskList(tl);`;

dv.executeJs(script);
```

# reminder

```dataviewjs
let script=await dv.io.load('script/task.js');
script=`const tl = ${script}`;
script = `${script}.filter(task => !task.completed)`;
script = `${script}.filter(task => task.text.includes('(@'));`;
script =`${script} dv.taskList(tl);`;

dv.executeJs(script);
```

# recently done

```dataviewjs
const today = new Date();
const lw = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
const lw_year = (lw.getFullYear() % 100) * 10000;
const lw_month = (lw.getMonth() + 1) * 100;
const lw_date = lw.getDate();
const lw_int = lw_year + lw_month + lw_date;

let script=await dv.io.load('script/task.js');
script=`const tl = ${script}
.filter(task => task.completed)
.filter(task => {
	const when_completed = parseInt(task.completion);
	console.log('wc', when_completed);
	console.log('lw', ${lw_int});
	return when_completed > ${lw_int};
});
 dv.taskList(tl);
`;

dv.executeJs(script);

```