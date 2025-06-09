---
title: "Exploring Modding Systems: A Journey With Lua and Rust"
source: https://medium.com/better-programming/exploring-modding-systems-a-journey-with-lua-and-rust-951ad01894cf
author:
  - "[[Stefan Kupresak]]"
published: 2023-04-10
created: 2025-05-22
description: In the ever-evolving world of game development, modding has become a powerful way to enhance gameplay experiences and breathe new life into existing titles. It allows creators and players to bring…
tags:
  - clippings
status: unread
aliases: 
updated: 2025-06-10T06:33
---
[Sitemap](https://medium.com/sitemap/sitemap.xml)

[![Better Programming](https://miro.medium.com/v2/resize:fill:38:38/1*QNoA3XlXLHz22zQazc0syg.png)](https://medium.com/better-programming?source=post_page---post_publication_sidebar-d0b105d10f0a-951ad01894cf---------------------------------------)

Advice for programmers.

[Follow publication](https://medium.com/m/signin?actionUrl=https%3A%2F%2Fmedium.com%2F_%2Fsubscribe%2Fcollection%2Fbetter-programming&operation=register&redirect=https%3A%2F%2Fmedium.com%2Fbetter-programming%2Fexploring-modding-systems-a-journey-with-lua-and-rust-951ad01894cf&collection=Better+Programming&collectionId=d0b105d10f0a&source=post_page---post_publication_sidebar-d0b105d10f0a-951ad01894cf---------------------post_publication_sidebar------------------)

![](https://miro.medium.com/v2/resize:fit:640/format:webp/1*szWPEIIS7INvDh0_yFcSAw.jpeg)

Foto: Pixbay

In the ever-evolving world of game development, modding has become a powerful way to enhance gameplay experiences and breathe new life into existing titles. It allows creators and players to bring their unique ideas to life, enriching the gaming ecosystem with fresh content and endless possibilities. As developers, we’re always looking for innovative ways to build and support modding systems that are both efficient and user-friendly. Today, we embark on a captivating journey to explore the synergy between two remarkable technologies, Lua and Rust, as we delve into the realm of modding systems.

Lua, a lightweight and versatile scripting language, has long been a popular choice for game developers to implement modding support. Its flexibility and ease of use make it an ideal candidate for extending game functionality and allowing user-generated content. On the other hand, Rust, a systems programming language focused on safety and performance, has quickly gained momentum for its powerful features and impressive capabilities. By combining the best of both worlds, we set out to create a robust, yet accessible modding system that opens the door to endless creativity.

Join us as we experiment with the unique strengths of Lua and Rust, sharing our insights, challenges, and triumphs along the way. Whether you’re a seasoned developer or just starting your journey in game development, this adventure promises to be an exciting exploration of modding systems and the potential of Lua and Rust.

## Making a cargo project and integrating Lua

Let’s embark on this journey by creating a new Cargo project and setting up a simple Lua script.

First, create a new Cargo project and navigate to the project directory:

```hs
cargo new modding-example && cd modding-example
```

Next, add the `rlua` crate to your project:

```hs
cargo add rlua
```

Now, let’s create a `main.rs` file with the following code to execute a Lua script:

```hs
// File: src/main.rs
use rlua::{Lua, Result};
use std::fs;

fn exec_lua_code() -> Result<()> {
    let lua_code = fs::read_to_string("game/main.lua").expect("Unable to read the Lua script");

    let lua = Lua::new();
    lua.context(|lua_ctx| {
        lua_ctx.load(&lua_code).exec()?;

        Ok(())
    })
}

fn main() -> Result<()> {
    exec_lua_code()
}
```

If we try to run this, we’ll notice that the script can’t execute because the `game/main.lua` file doesn't exist yet. Let's create the necessary directory and file:

```hs
mkdir game
touch game/main.lua
```

Now, let’s add some flair to our Lua script by printing some information:

```hs
-- File: game/main.lua
print(_VERSION)
print("🌙 Lua is working!")
```

With this setup, you should see the Lua version and the “Lua is working!” message printed to the console when you run your Rust program.

## Making the Stdout More Interesting

Our texts look plain and we can’t differentiate between lua outputs and rust outputs. Let’s change that, by utilizing colors from the popular `colored` crate.

First, let’s add `colored` crate to our project:

```hs
cargo add colored
```

Now let’s re-implement Lua’s `print` statement with our own.

```hs
-- File: game/main.lua

function print(...)
  local args = {...}
  
  for _, arg in ipairs(args) do
    if type(arg) == "table" then
      __rust_bindings_print(tostring(arg))
    elseif type(arg) == "string" then
      __rust_bindings_print(arg)
    else
      __rust_bindings_print(tostring(arg))
    end
  end
end

-- rest of game/main.lua
```

Now, we need to pass `__rust_bindings_print` to the lua context, so it calls our `rust` code. We are also going to create a `log` function for our `rust` runtime:

```hs
// File: src/main.rs
use rlua::{Lua, Result};
use std::fs;

mod logger;

/* rest of main.rs */
```

And now we must create this file:

```hs
touch src/logger.rs
```

Finally, we can implement the colorized output:

```hs
// File: src/logger.rs
use colored::*;
use rlua::{Result, Value};
use std::io::Write;

pub fn lua_print<'lua>(lua_ctx: rlua::Context<'lua>, value: Value<'lua>) -> Result<()> {
    let mut str = String::from("nil");
    if let Some(lua_str) = lua_ctx.coerce_string(value)? {
        str = lua_str.to_str()?.to_string();
    }

    match writeln!(std::io::stdout(), "[{}] {}", "lua".cyan(), str) {
        Ok(_) => Ok(()),
        Err(e) => Err(rlua::Error::external(e)),
    }
}

pub fn log(message: &str) {
    println!("[{}] {}", "rust".red(), message);
}
```

Now we can utilize these functions in our `src/main.rs`

```hs
// File: src/main.rs
use logger::{log, lua_print}; // new line
// rest of use statements

// ...

fn exec_lua_code() -> Result<()> {
    let lua_code = fs::read_to_string("game/main.lua").expect("Unable to read the Lua script");
    
    let lua = Lua::new();
    lua.context(|lua_ctx| {
        log("🔧 Loading Lua bindings");
        lua_ctx
            .globals()
            .set("__rust_bindings_print", lua_ctx.create_function(lua_print)?)?;        
        lua_ctx.load(&lua_code).exec()?;

        Ok(())
    })
}

// ...
```

Our colorized output now works! And now we can easily differentiate between our `rust` and `lua` runtime.

![](https://miro.medium.com/v2/resize:fit:640/format:webp/1*cBpS98kGyhe81VmgZQnpFA.png)

Working colorized output

## Making the mods structure

Let’s think for a second about what our mods will look like.

What comes to mind is the following structure:

```hs
/game
|--/mods
  |--/base
  |----mod.json
  |----mod.lua
  |--/dlc
  |----mod.json
  |----mod.lua
|--main.lua
```

The `.json` file will have the following schema:

```hs
{
  "name": "base",
  "version": "0.0.1",
  "description": "A mod for the base game.",
  "author": "Stefan Kupresak"
}
```

## Loading mods in Rust

Similar to how we created the `logger` module, we are going to create a `mods` rust module now:

```hs
touch src/mods.rs
```

And add a reference to it in our `main.rs`

```hs
// File: src/main.rs
mod mods;
```

For this module, we’ll also need to pull in some new cargo dependencies for helping us parse the mod `json` manifest files:

```hs
cargo add serde_json
```

And for `serde` we’re going to manually add it to `Cargo.toml`

```hs
[dependecies]
...
serde = { version = "*", features = ["derive"] }
```

Now, we can implement the `mods.rs` module:

```hs
// File: src/mods.rs
use std::fs;
use rlua::{MetaMethod, UserData, UserDataMethods};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
pub struct Mod {
    pub name: String,
    pub version: String,
    pub description: String,
    pub author: String,
}

/**
 * UserData is used from rlua so 
 * we can pass the Vec<Mod> to our 
 * Lua context
**/
impl UserData for Mod {}

/**
 * This helps us later to convert
 * the mods struct to a lua table
**/
pub fn items_to_lua_table<'lua>(lua_ctx: &Context<'lua>, items: Vec<Mod>) -> Result<Table<'lua>> {
    let table = lua_ctx.create_table()?;
    for (i, item) in items.iter().enumerate() {
        // lua tables start from index 1 :)
        // see: https://www.tutorialspoint.com/why-do-lua-arrays-tables-start-at-1-instead-of-0
        table.set(i + 1, item.clone())?;
    }
    Ok(table)
}

fn list_mods_root() -> Vec<String> {
    let mut mods = vec![];

    for entry in fs::read_dir("game/mods").expect("Unable to read the mods directory") {
        let entry = entry.expect("Unable to read the mods directory");
        let path = entry.path();

        if path.is_dir() {
            let mod_json_path = path.join("mod.json");
            if mod_json_path.exists() {
                mods.push(mod_json_path.to_str().unwrap().to_string());
            }
        }
    }

    mods
}

pub fn load() -> Vec<Mod> {
    let mod_paths = list_mods_root();
    let mut mods = vec![];

    for mod_json_path in mod_paths {
        let mod_json = fs::read_to_string(mod_json_path).expect("Unable to read the mod.json file");
        let mod_json = serde_json::from_str(&mod_json).expect("Unable to parse the mod.json file");
        mods.push(mod_json);
    }

    mods
}
```

Exciting! Now we can load the mods from our `main.rs` file.

```hs
// File src/main.rs
fn main() -> Result<()> {
  let mods = mods::load();
  log(format!("Loaded {} mods", mods.len()).as_str());
  exec_lua_code();
}
```

Now we should have the following output:

```hs
[rust] Loaded 2 mods
[rust] 🔧 Loading Lua bindings
[lua] Lua 5.4
[lua] 🌙 Lua is working!
```

Keep in mind that our `game/` directory looks like this:

![](https://miro.medium.com/v2/resize:fit:640/format:webp/1*PurD-MXIH6TJKHgDph3wHA.png)

How our current game directory looks

## Passing our mods vector to Lua

So far so good. Finally, we need to pass our vector to `lua` and start building out the “framework” for loading these mods.

First, let’s pass our mods to our `exec_lua_code` function:

```hs
// File src/main.rs
fn exec_lua_code(mods: Vec<Mod>) -> Result<()> {
  /* function body */
}

fn main() -> Result<()> {
  let mods = mods::load();
  /* ... */
  exec_lua_code(mods)
}
```

Now we can pass along our struct to the Lua context:

```hs
// File src/main.rs
fn exec_lua_code(mods: Vec<Mod>) -> Result<()> {
  /* ... */
  lua.context(|lua_ctx| {
    /* ... */
    let mods_table = mods::items_to_lua_table(&lua_ctx, mods)?;
    lua_ctx.globals().set("mods", mods_table)?;
    /* ... */
  })
}
```

We can verify it works by doing the following in our `main.lua`

```hs
print("number of mods -> " .. #mods)
```

## UserData and Lua

One strange thing though, is if we try to access a particular mod, we get this `userdata` construct.

```hs
print("first mod: ", mods[1]) -- userdata 0x5587a65d49e8
```

This is a special construct in lua, which points to a block of raw memory. What’s interesting is that we can’t access it as a table in the way you expect:

```hs
print("first mod name: ", mods[1].name) -- throws an error
```

The reason this happens is because `lua` doesn’t know how to index this data structure. In order to make it indexable” we have to implement the `__index` function in its meta table.

`rlua` adds a convenient way for us to do so. By implementing the `UserData` trait we can extend this user data and add this metamethod which will allow us to index this data in Lua:

```hs
// File: src/mods.rs
impl UserData for Mod {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(MetaMethod::Index, |_, modd: &Mod, key: String| {
            match key.as_str() {
                "name" => Ok(modd.name.clone()),
                "version" => Ok(modd.version.clone()),
                "description" => Ok(modd.description.clone()),
                "author" => Ok(modd.author.clone()),
                _ => Err(rlua::Error::external(format!("Unknown key: {}", key))),
            }
        })
    }
}
```

Now if we try the same line again, it simply works!

```hs
print("first mod name: ", mods[1].name)
```
```hs
[lua] first mod name: 
[lua] base
```

## Building out a small Lua game framework

With the rust part completed, we can now extend the Lua script and make a few `mod.lua` files to play around with our new system.

In this system, I’ve decided to have a single `mod.lua` entry file for each mod and force it to be a module.

```hs
-- File: game/main.lua

-- rest of main.lua file

Game = {}
function Game:new()
  o = {}
  self.__index = self
  return setmetatable(o, self)
end

function Game:load()
  -- Starts loading the game
  print("⚡ Loading game")

  -- Load the game mods
  print("🚧 Loading " .. #mods .. " mod(s)")

  for _, mod in ipairs(mods) do
    print("✅ Loading mod " .. mod.name)
    local f, err = loadfile("game/mods/" .. mod.name .. "/mod.lua")

    if f then
      m = f()

      if m and m.init then
        m:init(mod)
      else
        print("❌ Mod " .. mod.name .. " does not have an init function")
      end
    else
      print("❌ Mod " .. mod.name .. " failed to load: " .. err)
    end
  end
end

game = Game:new()
game:load()
```

Keep in mind this example works with the following `game/mods/base/mod.lua` file

```hs
-- File: game/mods/base/mod.lua
mod = {}

function mod:init(mod) 
  print("🕹️ Initializing mod " .. mod.name)
end

return mod
```

Will produce:

```hs
➜ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.01s
     Running \`target/debug/modding-example\`
[rust] 🔧 Loading Lua bindings
[rust] 🚀 executing lua script
[lua] ⚡ Loading game
[lua] 🚧 Loading 2 mod(s)
[lua] ✅ Loading mod base
[lua] 🕹️ Initializing mod base
[lua] ✅ Loading mod dlc
[lua] ❌ Mod dlc does not have an init function
```

## Summary

In this article, we explore the powerful combination of Lua and Rust to create a flexible and high-performance modding system for games. We walk through setting up a new Cargo project and integrating Lua, followed by designing a clear and organized mod structure. By leveraging the strengths of both technologies, we demonstrate how Lua and Rust can work together to enable endless creativity and bring new life to games through user-generated content.

🎊🎊 Congratulations if you’ve made it this far! You’ve successfully ventured into the world of Lua and Rust, creating a solid foundation for a flexible and high-performance modding system. As you continue to explore and experiment, you’ll undoubtedly uncover even more exciting possibilities and ideas to enhance your gaming projects. The journey you’ve embarked on is just the beginning — the potential of Lua and Rust working together is vast, and we can’t wait to see what you create next. Keep pushing the boundaries and happy modding!

This article has an open-source GitHub [repo](https://github.com/dev-cyprium/rust-mods-example).

[![Better Programming](https://miro.medium.com/v2/resize:fill:48:48/1*QNoA3XlXLHz22zQazc0syg.png)](https://medium.com/better-programming?source=post_page---post_publication_info--951ad01894cf---------------------------------------)

[![Better Programming](https://miro.medium.com/v2/resize:fill:64:64/1*QNoA3XlXLHz22zQazc0syg.png)](https://medium.com/better-programming?source=post_page---post_publication_info--951ad01894cf---------------------------------------)

[Last published Nov 11, 2023](https://medium.com/better-programming/let-a-thousand-programming-publications-bloom-bf37baef8f27?source=post_page---post_publication_info--951ad01894cf---------------------------------------)

Advice for programmers.

Hello. I’m a full-stack developer specializing in Elixir/Phoenix and React, and I love going into lots of details in any problem.

## More from Stefan Kupresak and Better Programming

## Recommended from Medium

[

See more recommendations

](https://medium.com/?source=post_page---read_next_recirc--951ad01894cf---------------------------------------)