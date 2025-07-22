---
id: 25070717133689
aliases:
  - zsh
  - pid
tags:
  - zsh
  - cli
created: 250707 17:13:36
updated: 250722 17:05:37
---

# 結論

```sh
❯ ps -t $(tty) -o pid,ppid,tty,command
  PID  PPID TTY      COMMAND
58958 58938 ttys003  /bin/zsh
90508 58958 ttys003  /bin/zsh
90509 90508 ttys003  q _ inline-shell-completion --buffer ps -t $(tty) -o pid,ppid,tty,command
90513 58958 ttys003  ps -t /dev/ttys003 -o pid,ppid,tty,command
```

他には

```sh
ps -p $PPID
```

とすると親プロセスをゲットできる

>[!Info] コピペ用
>```sh
>ps -t $(tty) -o pid,ppid,command
>```