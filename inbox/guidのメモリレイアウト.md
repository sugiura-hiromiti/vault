---
id: 25042717052138
aliases:
  - memory_layout_of_guid
tags:
  - tech/guid
  - tech/osdev
  - tech/uefi
created: 250427 17:05:21
updated: 250427 17:11:00
---

[[RustとCにおける列挙型の違い|enum_diff_between_rust_and_c]]

Guidのメモリレイアウトは初めの8byteのみメモリースワップされる

例
`964e5b22-6459-11d2-8e39-00a0c969723b`のメモリ上の表現

| part                        | raw(big endian)     | raw(little endian)  |
| :-------------------------- | ------------------- | ------------------- |
| time_low                    | `96 4e 58 22`       | `22 5b 4e 96`       |
| time_mid                    | `64 59`             | `59 64`             |
| time_high_and_version       | `11 d2`             | `d2 11`             |
| clock_seq_high_and_reserved | `8e`                | `8e`                |
| clock_seq_low               | `39`                | `39`                |
| node                        | `00 a0 c9 69 72 3b` | `00 a0 c9 69 72 3b` |
