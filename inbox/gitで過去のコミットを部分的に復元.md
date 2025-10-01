---
id: 25070713131873
aliases:
  - git
  - git commit
  - 復元
tags:
  - git
created: 250707 13:13:18
updated: 250722 17:05:37
---

# gitで過去のコミットを部分的に復元

```bash
git rm <path to dir>
git checkout <commit hash> <path to dir>
git commit ...
```

acknowledge:
https://stackoverflow.com/questions/26048582/git-how-to-revert-entire-directory-to-specific-commit-removing-any-added-file