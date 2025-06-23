---
title: Zennでタブ文字の深さをカスタマイズする方法
emoji: 🌐
type: tech
topics:
  - css
  - zenn
  - safari
  - browser
published: true
published_at: 2023-01-06 15:46
created: 250426 08:55:26
updated: 250623 09:41:03
---

# 結論

まず

```css
body {
	tab-size: 3; /*お好きな数字をどうぞ*/
}
```

の記述があるcssファイルを作ります。safariの場合safariの設定のAdvancedのstyle sheetからこのファイルを読み込みます。

![](https://storage.googleapis.com/zenn-user-upload/8d6e50a7c65e-20230106.jpeg)

他のブラウザの場合も同様の設定があるかと思います。自分はsafariしか使ったことがないのでわかりませんが（ぇ

注意点としては、まぁわかると思いますがsafari全体の設定を変更しているためあらゆるサイトで`tab-size 3`します。

# 蛇足

読む必要はありません。Chromium系を使ってる方には美味しい情報があるかも？

## 動機

自分はインデントにtabを使っています（[tabを使う理由](https://zenn.dev/cp_r/articles/de8dd526aabd21)）。ですがそうするとエディタからzennへコピーした際に見辛くなってしまいます。というのはzenn上ではtab文字は８文字幅固定のため、コードによっては横幅がめちゃくちゃ広くなってしまいます。これをgithubのようにカスタムできる様にしたいわけです。

更に欲を言うと自分はインデント幅を３文字にしています。ですが大体の場合tabは２、４、８のいずれか。これもどうにかしたい。

## 解決

と言うことで[zennの運営さんに要望を送ってみました](https://github.com/zenn-dev/zenn-community/issues/484)。

最終的にzennにこの設定がくるのは難しそうですが、[stylebot](https://chrome.google.com/webstore/detail/stylebot/oiaejidbmkiecgbjeifoejpgmdaleoha?hl=en)という拡張機能を使うことで同様のことをすることが出来ると教えてもらいました。

ですがこの拡張機能、safariに対応していません。代替プラグインでsafariに対応しているものがあるにはあったのですが、なぜかインストできない（古いサイトあるある）。自分はcssの知識はないのですがどうやらタブサイズを設定できるらしいということは分かりました。そこからsafariにcssファイルを読み込ませる設定あったなと言うのを思い出し、読み込ませてみたらうまいこと機能してくれました。

## 締め

cssやhtmlには興味がありませんでしたがブラウザを頻繁に使用している以上、知識があると（今回の様に）便利だよなぁと思いました。
近いうちに勉強したいですねぇ