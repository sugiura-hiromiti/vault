---
id: 25060207311435
aliases: 
tags:
  - index
created: 250602 07:31:14
updated: 2025-07-28T21:22
---

# reminder

```dataviewjs
let script=await dv.io.load('script/task.js');
script=`const tl = ${script}`;
script = `${script}.filter(task => !task.completed)`;
script = `${script}.filter(task => !task.text.includes("{{date}}"))`;
script = `${script}.filter(task => task.text.includes('(@'));`;
script =`${script} dv.taskList(tl);`;

dv.executeJs(script);
```

# tasks

```dataviewjs
let script=await dv.io.load('script/task.js');
script=`const tl = ${script}`;
script = `${script}.filter(task => !task.completed)`;
script = `${script}.filter(task => !task.text.includes('(@'));`;
script =`${script} dv.taskList(tl);`;

dv.executeJs(script);
```
