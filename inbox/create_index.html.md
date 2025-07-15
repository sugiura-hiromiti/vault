---
id: 25071513112025
aliases: []
tags: []
created: 250715 13:11:20
updated: 250715 13:52:44
---

first, let me explain this repository. this repository has collection of commit summary which is of my github repositories. each commit summary is generated for certain range of commit history of the repository. each html files in the doc/ are a summary one by one. the file name of the summary follows certain format. it's "<repository name>_<year>_<month>_<day>_<hour>_<minute>_<second>.html". this repository has remote repository on github. we use github pages to deploy our summaries. index.html is the entrypoint of the deployed web page. index.html should be a powerful search hub and dashboard of statistics. Currently, there is no index.html. thus I'd like to make requirements definition document. read the entire repository. then tell me every questions, suggestions and ideas of creating index.html

I'll answer your critical questions at first. 1: to discover and parse html files, scan the /doc directory by client-side js script. 2: they should be treated as separate repository. 3: github pages configuration is, deploying from root. you can move /doc to /docs. 4: repository names, commit messages, date ranges and tags/categories should be searchable. 5: At least, I want all of your suggested statistics. And here is my thoughts to your questions for decision making. 1: index.html can require a build process. 2: I prefer real-time updating. 3: I want this site to be modern and powerful dashboard. But I do not forget simplicity as well. 4: No need to provide user preferences. 5: I prefer to be everything public, howerver I would accept authentication if necessary. 6: it seems good if this site runs well at/on all browsers/devices. 7: dashboard can rely on network. It's enough on working at online. Now, we may step a little forward to make requirements definition. We are still working in progress. tell me anything you notice.

here is answer for your questions of critical issues. 1: update all existing html files. 2: every commit. 3: generate manifest file. 4: fix the source files. 5: yes. then, I'll answer questions of Immediate decisions. 1: yes. 2: I prefer github actions. 3: on every commit. And Design Decisions. 1: yes. support dark mode. 2: chronological timeline. 3: simplified interface. Next, I'd like to answer Integration Questions. 1: currently, commit summary is automatically generated when pushing local changes to remote at the repositories. you can hook into it. 2: display alt text. 3: only render html which does not rely on manifest. Now I would like you to generate our conclusion as requirements definition document. the document name is RDD.md. save the conclusion to the RDD.md.

