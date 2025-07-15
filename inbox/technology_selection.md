---
id: 25071514075689
aliases: []
tags: []
created: 250715 14:07:56
updated: 250715 14:34:21
---

first, let me explain this repository. this repository has collection of commit summary which is of my github repositories. each commit summary is generated for certain range of commit history of the repository. each html files in the doc/ are a summary one by one. the file name of the summary follows certain format. it's "<repository name>_<year>_<month>_<day>_<hour>_<minute>_<second>.html". this repository has remote repository on github. we use github pages to deploy our summaries. index.html is the entrypoint of the deployed web page. index.html should be a powerful search hub and dashboard of statistics. Currently, there is no index.html. I've made requirements definition document. the file name is RDD.md. now I want to make decision of architecture/technology selection. thus, first, read the eintire repository. then tell me every questions, suggestions and ideas

I'll mention your Questions & Clarifications at first. 1: yes. standardize to commit_summary. I want to normalize timestamp. 2: this is because /docs is better name than /doc. and I don't care about backward compatibility. 3: yes. and parse should be done at client-side. 4: yes. this is the custom ssh config. integration with github api is nice.

Here is my answer to key questions for next steps. 1: I prefer Option A. 2: repository stats, real-time commit counts and issue/pr counts. 3: on-demad. 4: tag filtering.