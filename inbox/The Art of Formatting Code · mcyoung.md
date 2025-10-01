---
title: The Art of Formatting Code · mcyoung
source: https://mcyoung.xyz/2025/03/11/formatters/
author: 
published: 
created: 2025-05-22
description: 
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
Every modern programming language needs a *formatter* to make your code look pretty and consistent. Formatters are source-transformation tools that parse source code and re-print the resulting AST in some canonical form that normalizes whitespace and optional syntactic constructs. They remove the tedium of matching indentation and brace placement to match a style guide.

Go is particularly well-known for providing a formatter as part of its toolchain from day one. It is not a *good* formatter, though, because it cannot enforce a maximum column width. Later formatters of the 2010s, such as rustfmt and clang-format, do provide this feature, which ensure that individual lines of code don’t get too long.

The reason Go doesn’t do this is because the naive approach to formatting code makes it intractable to do so. There are many approaches to implementing this, which can make it seem like a very complicated layout constraint solving problem.

So what’s so tricky about formatting code? Aren’t you just printing out an AST?

## “Just” an AST

An AST [^1] (abstract syntax tree) is a graph representation of a program’s syntax. Let’s consider something like JSON, whose naively-defined AST type might look something like this.

```rust
enum Json {
  Null,
  Bool(bool),
  Number(f64),
  String(String),
  Array(Vec<Json>),
  Object(HashMap<String, Json>)
}
```

Rust

The AST for the document `{"foo": null, "bar": 42}` might look something like this:

```rust
let my_doc = Json::Object([
  ("foo".to_string(), Json::Null),
  ("bar".to_string(), Json::Number(42)),
].into());
```

Rust

This AST has some pretty major problems. A formatter must *not* change the syntactic structure of the program (beyond removing things like redundant braces). Formatting must also be deterministic.

First off, `Json::Object` is a `HashMap`, which is unordered. So it will immediately discard the order of the keys. `Json::String` does not retain the escapes from the original string, so `"\n"` and `"\u000a"` are indistinguishable. `Json::Number` will destroy information: JSON numbers can specify values outside of the `f64` representable range, but converting to `f64` will quantize to the nearest float.

Now, JSON doesn’t have comments, but if it did, our AST has no way to record it! So it would destroy all comment information! Plus, if someone has a document that separates keys into stanzas [^2], as shown below, this information is lost too.

```json
{
  "this": "is my first stanza",
  "second": "line",

  "here": "is my second stanza",
  "fourth": "line"
}
```

JSON

Truth is, the AST for virtually all competent toolchains are much more complicated than this. Here’s some important properties an AST needs to have to be useful.

1. Retain *span* information. Every node in the graph remembers what piece of the file it was parsed from.
2. Retain whitespace information. “Whitespace” typically includes both whitespace characters, and comments.
3. Retain ordering information. The children of each node need to be stored in ordered containers.

The first point is achieved in a number of ways, but boils down to somehow associating to each token a pair of integers [^3], identifying the start and end offsets of the token in the input file.

Given the span information for each token, we can then define the span for each node to be the *join* of its tokens’ spans, namely the start is the min of its constituent tokens’ starts and its end is the max of the ends. This can be easily calculated recursively.

Once we have spans, it’s easy to recover the whitespace between any two adjacent syntactic constructs by calculating the text between them. This approach is more robust than, say, associating each comment with a specific token, because it makes it easier to discriminate stanzas for formatting.

Being able to retrieve the comments between any two syntax nodes is crucial. Suppose the user writes the following Rust code:

```rust
let x = false && // HACK: disable this check.
  some_complicated_check();
```

Rust

If we’re formatting the binary expression containing the `&&`, and we can’t query for comments between the LHS and the operator, or the operator and the RHS, the `// HACK` comment will get deleted on format, which is pretty bad!

An AST that retains this level of information is sometimes called a “concrete syntax tree”. I do not consider this a useful distinction, because any useful AST must retain span and whitespace information, and it’s kind of pointless to implement the same AST more than once. To me, an AST without spans is incomplete.

### Updating Our JSON AST

With all this in mind, the bare minimum for a “good” AST is gonna be something like this.

```rust
struct Json {
  kind: JsonKind,
  span: (usize, usize),
}

enum JsonKind {
  Null,
  Bool(bool),
  Number(f64),
  String(String),
  Array(Vec<Json>),
  Object(Vec<(String, Json)>),  // Vec, not HashMap.
}
```

Rust

There are various layout optimizations we can do: for example, the vast majority of strings exist literally in the original file, so there’s no need to copy them into a `String`; it’s only necessary if the string contains escapes. My `byteyarn` crate, which I wrote about [here](https://mcyoung.xyz/2023/08/09/yarns), is meant to make handling this case easy. So we might rewrite this to be lifetime-bound to the original file.

```rust
struct Json<'src> {
  kind: JsonKind<'src>,
  span: (usize, usize),
}

enum JsonKind<'src> {
  Null,
  Bool(bool),
  Number(f64),
  String(Yarn<'src, str>),
  Array(Vec<Json>),
  Object(Vec<(Yarn<'src, str>, Json)>),  // Vec, not HashMap.
}
```

Rust

But wait, there’s some things that don’t have spans here. We need to include spans for the braces of `Array` and `Object`, their commas, and the colons on object keys. So what we actually get is something like this:

```rust
struct Span {
  start: usize,
  end: usize,
}

struct Json<'src> {
  kind: JsonKind<'src>,
  span: Span,
}

enum JsonKind<'src> {
  Null,
  Bool(bool),
  Number(f64),
  String(Yarn<'src, str>),

  Array {
    open: Span,
    close: Span,
    entries: Vec<ArrayEntry>,
  },
  Object {
    open: Span,
    close: Span,
    entries: Vec<ObjectEntry>,
  },
}

struct ArrayEntry {
  value: Json,
  comma: Option<Span>,
}

struct ObjectEntry {
  key: Yarn<'src, str>,
  key_span: Span,
  colon: Span,
  value: Json,
  comma: Option<Span>,
}
```

Rust

Implementing an AST is one of my least favorite parts of writing a toolchain, because it’s tedious to ensure all of the details are recorded and properly populated.

## “Just” Printing an AST

In Rust, you can easily get a nice recursive print of any struct using the `#[derive(Debug)]` construct. This is implemented by recursively calling `Debug::fmt()` on the elements of a struct, but passing modified `Formatter` state to each call to increase the indentation level each time.

This enables printing nested structs in a way that looks like Rust syntax when using the `{:#?}` specifier.

```rust
Foo {
  bar: 0,
  baz: Baz {
    quux: 42,
  },
}
```

Rust

We can implement a very simple formatter for our JSON AST by walking it recursively.

```rust
fn fmt(out: &mut String, json: &Json, file: &str, indent: usize) {
  match &json.kind {
    Json::Null | Json::Bool(_) | Json::Number(_) | Json::String(_) => {
      // Preserve the input exactly.
      out.push_str(file[json.span.start..json.span.end]);
    }

    Json::Array { entries, .. } => {
      out.push('[');
      for entry in entries {
        out.push('\n');
        for _ in indent*2+2 {
          out.push(' ');
        }
        fmt(out, &entry.value, file, indent + 1)
        if entry.comma.is_some() {
          out.push(',');
        }
      }
      out.push('\n');
      for _ in indent*2 {
        out.push(' ');
      }
      out.push(']');
    }

    Json::Object { entries, .. } => {
      out.push('{');
      for entry in entries {
        out.push('\n');
        for _ in indent*2+2 {
          out.push(' ');
        }

        // Preserve the key exactly.
        out.push_str(file[entry.key_span.start..entry.key_span.end]);

        out.push_str(": ");
        fmt(out, &entry.value, file, indent + 1)
        if entry.comma.is_some() {
          out.push(',');
        }
      }
      out.push('\n');
      for _ in indent*2 {
        out.push(' ');
      }
      out.push('}');
    }
  }
}
```

Rust

This is essentially what every JSON serializer’s “pretty” mode looks like. It’s linear, it’s simple. But it has one big problem: small lists.

If I try to format the document `{"foo": []}` using this routine, the output will be

```json
{
  "foo": [
  ]
}
```

JSON

This is pretty terrible, but easy to fix by adding a special case:

```rust
Json::Array { entries, .. } => {
  if entries.is_empty() {
    out.push_str("[]");
    return
  }

  // ...
}
```

Rust

Unfortunately, this doesn’t handle the similar case of a small but non-empty list. `{"foo": [1, 2]}` formats as

```json
{
  "foo": [
    1,
    2
  ]
}
```

JSON

Really, we’d like to keep `"foo": [1, 2]` on one line. And now we enter the realm of column wrapping.

## How Wide Is a Codepoint?

The whole point of a formatter is to work with *monospaced text*, which is text formatted using a monospaced or *fixed-width* typeface, which means each character is the same width, leading to the measure of the width of lines in *columns*.

So how many columns does the string `cat` take up? Three, pretty easy. But we obviously don’t want to count bytes, this isn’t 1971. If we did, `кішка`, when UTF-8 encoded, it would be 10, rather than 5 columns wide. So we seem to want to count Unicode characters instead?

Oh, but what *is* a Unicode character? Well, we could say that you’re counting Unicode scalar values (what Rust’s `char` and Go’s `rune`) types represent. Or you could count grapheme clusters (like Swift’s `Character`).

But that would give wrong answers. CJK languages’ characters, such as `猫`, usually want to be rendered as *two* columns, even in monospaced contexts. So, you might go to Unicode and discover [UAX#11](https://www.unicode.org/reports/tr11/), and attempt to use it for assigning column widths. But it turns out that the precise rules that monospaced fonts use are not written down in a single place in Unicode. You would also discover that some scripts, such as Arabic, have complex ligature rules that mean that the width of a single character depends on the characters around it.

This is a place where you should hunt for a library. [`unicode_width`](https://docs.rs/unicode-width/latest/unicode_width/#rules-for-determining-width) is the one for Rust. Given that Unicode segmentation is a closely associated operation to width, segmentation libraries are a good place to look for a width calculation routine.

But most such libraries will still give wrong answers, because of tabs. The tab character `U+0009 CHARACTER TABULATION` ’s width depends on the width of all characters before it, because a tab is as wide as needed to reach the next *tabstop*, which is a column position an integer multiple of the *tab width* (usually 2, 4, or, on most terminals, 8).

With a tab width of 4, `"\t"`, `"a\t"`, and `"abc\t"` are all four columns wide. Depending on the context, you will either want to treat tabs as behaving as going to the next tabstop (and thus being variable width), or having a fixed width. The former is necessary for assigning correct column numbers in diagnostics, but we’ll find that the latter is a better match for what we’re doing.

The reason for being able to calculate the width of a string is to enable line wrapping. At some point in the 2010s, people started writing a lot of code on laptops, where it is not easy to have two editors side by side on the small screen. This removes the motivation to wrap all lines at 80 columns [^4], which in turn results in lines that tend to get arbitrarily long.

Line wrapping helps ensure that no matter how wide everyone’s editors are, the code *I* have to read fits on my very narrow editors.

## Accidentally Quadratic

A lot of folks’ first formatter recursively formats a node by formatting its children to determine if they fit on one line or not, and based on that, and their length if they are single-line, determine if their parent should break.

This is a naive approach, which has several disadvantages. First, it’s very easy to accidentally backtrack, trying to only break smaller and smaller subexpressions until things fit on one line, which can lead to quadratic complexity. The logic for whether a node can break is bespoke per node and that makes it easy to make mistakes.

Consider formatting `{"foo": [1, 2]}`. In our AST, this will look something like this:

```rust
Json {
  kind: JsonKind::Object {
    open: Span { start: 0, end: 1 },
    close: Span { start: 14, end: 15 },
    entries: vec![ObjectEntry {
      key: "foo",
      key_span: Span { start: 1, end: 4 },
      colon: Span { start: 4, end: 5 },
      value: Json {
        kind: JsonKind::Array {
          span: Span { start: 8, end: 9 },
          span: Span { start: 13, end: 14 },
          entries: vec![
            ArrayEntry {
              value: Json {
                kind: JsonKind::Number(1.0),
                span: Span { start: 9, end: 10 },
              },
              comma: Some(Span { start: 10, end: 11 }),
            },
            ArrayEntry {
              value: Json {
                kind: JsonKind::Number(s.0),
                span: Span { start: 12, end: 13 },
              },
              comma: None,
            },
          ],
        },
        span: Span { start: 8, end: 14 },
      },
      comma: None,
    }],
  },
  span: Span { start: 0, end: 15 },
}
```

Rust

To format the whole document, we need to know the width of each field in the object to decide whether the object fits on one line. To do that, we need to calculate the width of each value, and add to it the width of the key, and the width of the `: ` separating them.

How can this be accidentally quadratic? If we simply say “format this node” to obtain its width, that will recursively format all of the children it contains without introducing line breaks, performing work that is linear in how many transitive children that node contains. Having done this, we can now decide if we need to introduce line breaks or not, which increases the indentation at which the children are rendered. This means that the children cannot know ahead of time how much of the line is left for them, so we need to recurse into formatting them again, now knowing the indentation at which the direct children are rendered.

Thus, each node performs work equal to the number of nodes beneath it. This has resulted in many slow formatters.

Now, you could be more clever and have each node be capable of returning its width based on querying its children’s width directly, but that means you need to do complicated arithmetic for each node that needs to be synchronized with the code that actually formats it. Easy to make mistakes.

The solution is to invent some kind of model for your document that specifies how lines should be broken if necessary, and which tracks layout information so that it can be computed in one pass, and then used in a second pass to figure out whether to actually break lines or not.

This is actually how HTML works. The markup describes constraints on the layout of the content, and then a layout engine, over several passes, calculates sizes, solves constraints, and finally produces a raster image representing that HTML document. Following the lead of HTML, we can design…

The HTML DOM is a markup document: a tree of tags where each tag has a type, such as `<p>`, `<a>`, `<hr>`, or `<strong>`, properties, such as `<a href=...>`, and content consisting of nested tags (and bare text, which every HTML engine just handles as a special kind of tag), such as `<p>Hello <em>World</em>!</p>`.

We obviously want to have a tag for text that should be rendered literally. We also want a tag for line breaks that is distinct from the text tag, so that they can be merged during rendering. It might be good to treat text tags consisting of just whitespace, such as whitespace, specially: two newlines `\n\n` are a blank line, but we might want to merge consecutive blank lines. Similarly, we might want to merge consecutive spaces to simplify generating the DOM.

Consider formatting a language like C++, where a function can have many modifiers on it that can show up in any order, such as `inline`, `virtual`, `constexpr`, and `explicit`. We might want to canonicalize the order of these modifiers. We don’t want to accidentally wind up printing `inline constexpr Foo()` because we printed an empty string for `virtual`. Having special merging for spaces means that all entities are always one space apart if necessary. This is a small convenience in the DOM that multiplies to significant simplification when lowering from AST to DOM.

Another useful tag is something like `<indent by=" ">`, which increases the indentation level by some string (or perhaps simply a number of spaces; the string just makes supporting tabs easier) for the tags inside of it. This allows control of indentation in a carefully-scoped manner.

Finally, we need some way to group tags that are candidates for “breaking”: if the width of all of the tags inside of a `<group>` is greater than the maximum width that group can have (determined by indentation and any elements on the same line as that group), we can set that group to “broken”, and… well, what should breaking do?

We want breaking to not just cause certain newlines (at strategic locations) to appear, but we also want it to cause an indentation increase, and in languages with trailing commas like Rust and Go, we want (or in the case of Go, *need*) to insert a trailing comma only when broken into multiple lines. We can achieve this by allowing any tag to be *conditioned* on whether the enclosing group is broken or not.

Taken all together, we can render the AST for our `{"foo": [1, 2]}` document into this DOM, according to the tags we’ve described above.

```xml
<group>
  <text s="{" />
  <text s="\n" if=broken />
  <indent by="  ">
    <text s='"foo"' />
    <text s=":" />
    <text s=" " />
    <group>
      <text s="[" />
      <text s="\n" if=broken />
      <indent by="  ">
        <text s="1" />
        <text s="," />
        <text s=" " if=flat />
        <text s="\n" if=broken />
        <text s="2" />
      </indent>
      <text s="\n" if=broken />
      <text s="]"/>
    </group>
  </indent>
  <text s="\n" if=broken />
  <text s="}" />
</group>
```

XML

Notice a few things: All of the newlines are set to appear only `if=broken`. The space between the two commas only appears if the enclosing group is *not* broken, that is `if=flat`. The groups encompass everything that can move due to a break, which includes the outer braces. This is necessary because if that brace is not part of the group, and it is the only character past the line width limit, it will not cause the group to break.

### Laying Out Your DOM

The first pass is easy: it measures how wide every node is. But we don’t know whether any groups will break, so how can we measure that without calculating breaks, which depend on indentation, and the width of their children, and…

This is one tricky thing about multi-pass graph algorithms (or graph algorithms in general): it can be easy to become overwhelmed trying to factor the dependencies at each node so that they are not cyclic. I struggled with this algorithm, until I realized that the only width we care about is the width *if no groups are ever broken*.

Consider the following logic: if a group needs to break, all of its parents must obviously break, because the group will now contain a newline, so its parents must break no matter what. Therefore, we only consider the width of a node when deciding if a group must break intrinsically, i.e., because all of its children decided not to break. This can happen for a document like the following, where each inner node is quite large, but not large enough to hit the limit.

```json
[
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
]
```

JSON

Because we prefer to break outer groups rather than inner groups, we can measure the “widest a single line could be” in one pass, bottom-up: each node’s width is the sum of the width of its children, or its literal contents for `<text>` elements. However, we must exclude all text nodes that are `if=broken`, because they obviously do not contribute to the single-line length. We can also ignore indentation because indentation never happens in a single line.

However, this doesn’t give the full answer for whether a given group should break, because that depends on indentation and what nodes came before on the same line.

This means we need to perform a second pass: having laid everything out assuming no group is broken, we must lay things out as they would appear when we render them, taking into account breaking. But now that we know the maximum width of each group if left unbroken, we can make breaking decisions.

As we walk the DOM, we keep track of the current column and indentation value. For each group, we decide to break it if either:

1. Its width, plus the current column value, exceeds the maximum column width.
2. It contains any newlines, something that can be determined in the first pass.

The first case is why we can’t actually treat tabs as if they advance to a tabstop. We cannot know the column at which a node will be placed at the time that we measure its width, so we need to assume the worst case.

Whenever we hit a newline, we update the current width to the width induced by indentation, simulating a newline plus indent. We also need to evaluate the condition, if present, on each tag now, since by the time we inspect a non-group tag, we have already made a decision as to whether to break or not.

### Render It!

Now that everything is determined, rendering is super easy: just walk the DOM and print out all the text nodes that either have no condition or whose condition matches the innermost group they’re inside of.

And, of course, this is where we need to be careful with indentation: you don’t want to have lines that end in whitespace, so you should make sure to not print out any spaces until text is written after a newline. This is also a good opportunity to merge adjacent only-newlines text blocks. The merge algorithm I like is to make sure that when `n` and `m` newline blocks are adjacent, print `max(n, m)` newlines. This ensures that a DOM node containing `\n\n\n` is respected, while deleting a bunch of `\n` s in a row that would result in many blank lines.

What’s awesome about this approach is that the layout algorithm is highly generic: you can re-use it for whatever compiler frontend you like, without needing to fuss with layout yourself. There is a very direct conversion from AST to DOM, and the result is very declarative.

YAML is a superset of JSON that SREs use to write sentient configuration files. It has a funny list syntax that we might want to use for multi-line lists, but we might want to keep JSON-style lists for short ones.

A document of nested lists might look something like this:

```yaml
- [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
- [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
```

YAML

How might we represent this in the DOM? Starting from our original JSON document `{"foo": [1, 2]}`, we might go for something like this:

```xml
<group>
  <text s="{" if=flat />
  <indent by="  ">
    <text s='"foo"' />
    <text s=":" />
    <text s=" " />
    <group>
      <text s="[" if=flat />
      <text s="\n" if=broken />
      <text s="- " if=broken />
      <indent by="  ">
        <text s="1" />
      </indent>
      <text s="," if=flat />
      <text s=" " if=flat />
      <text s="\n" if=broken />
      <text s="- " if=broken />
      <indent by="  ">
        <text s="2" />
      </indent>
      <text s="\n" if=broken />
      <text s="]" if=flat />
    </group>
  </indent>
  <text s="\n" if=broken />
  <text s="}" if=flat />
</group>
```

XML

Here, we’ve made the `[]` and the comma only appear in flat mode, while in broken mode, we have a `- ` prefix for each item. The inserted newlines have also changed somewhat, and the indentation blocks have moved: now only the value is indented, since YAML allows the `-` s of list items to be at the same indentation level as the parent value for lists nested in objects. (This is a case where some layout logic is language-specific, but now the output is worrying about declarative markup rather than physical measurements.)

There are other enhancements you might want to make to the DOM I don’t describe here. For example, comments want to be word-wrapped, but you might not know what the width is until layout happens. Having a separate tag for word-wrapped blocks would help here.

Similarly, a mechanism for “partial breaks”, such as for the document below, could be implemented by having a type of line break tag that breaks if the text that follows overflows the column, which can be easily implemented by tracking the position of the last such break tag.

```json
{
  "foo": ["very", "long", "list",
          "of", "strings"]
}
```

JSON

## Using This Yourself

I think that a really good formatter is essential for any programming language, and I think that a high-quality library that does most of the heavy-lifting is important to make it easier to demand good formatters.

[So I wrote a Rust library.](https://github.com/mcy/strings/tree/main/allman) I haven’t released it on crates.io because I don’t think it’s quite at the state I want, but it turns out that the layout algorithm is very simple, so porting this to other languages should be EZ.

Now you have no excuse.:D

[^1]: Everyone pronounces this acronym “ay ess tee”, but I have a friend who really like to say *ast*, rhyming with *mast*, so I’m making a callout post my twitter dot com.

[^2]: In computing, a group of lines not separated by blank lines is called a stanza, in analogy to the stanzas of a poem, which are typeset with no blank lines between the lines of the stanza.

[^3]: You could also just store a string, containing the original text, but storing offsets is necessary for *diagnostics*, which is the jargon term for a compiler error. Compiler errors are recorded using an AST node as context, and to report the line at which the error occurred, we need to be able to map the node back to its offset in the file.

Once we have the offset, we can calculate the line in $O(\log n)$ time using binary search. Having pre-computed an array of the offset of each `\n` byte in the input file, binary search will tell us the index and offset of the `\n` before the token; this index is the zero-indexed line number, and the string from that `\n` to the offset can be used to calculate the column.

[^4]: The Rust people keep trying to convince me that it should be 100. They are wrong. 80 is perfect. They only think they need 100 because they use the incorrect tab width of four spaces, rather than two. This is the default for clang-format and it’s *perfect*.