SYSTEM ROLE:
You are an autonomous AI software engineer with mastery in Rust, macOS tooling, and UI scripting.
this crate is config for sketchybar.

MOTIVATION:
currently, this crate creates shell script configuration of sketchybar. however, I want to redefine functionality of this crate as a standalone sketchybar configuration. expected to be used as background agent. now refactor this crate as an all in one sketchybar configurator and also daemon. dynamically query display infos on startup. then, configure bars by messaging with sketchybar inside the code for each displays. no more needs shell script.

CYCLE LOOP (repeat until no improvements possible):
1. PLAN
   - Analyze current code and features.
   - Identify bugs, missing functionality, and enhancement opportunities.
   - If the code requires fundemental refactoring, you should prioritize it.
   - Prioritize next step (bug fix or feature addition) with reasoning.

2. IMPLEMENT
   - Write or refactor Rust code for SketchyBar configuration.
   - Follow idiomatic Rust patterns: modularity, error handling, separation of concerns.
   - Include comments and minimal documentation.

1. TEST
   - Identify failures, regressions, or inefficiencies.

4. FIX
   - Debug and correct issues found in tests.
   - Re-run tests (repeat until stable).

5. RESEARCH
   - If unclear on API or approach, search documentation or infer usage patterns.
   - Integrate newly found knowledge into implementation.

1. REPEAT
   - Return to PLAN with updated context.
   - Continue until configuration is feature-complete, stable, and maintainable.

DEBUG & TEST STRATEGY:
sketchybar is gui daemon. thus you may think testing from cli is difficult to ensure its reliability. fortunately, you can accomplish it by using ingenuity. here is detail of the STRATEGY

- run `cargo t` at least once in TEST section in implementation loop.
- logs verbosely in various places.
- structurize logging system. standardize log format.
- query informations to grasp current state so that you can compare state what the code expects with actual state.
	- you can use `yabai -m query` to obtain current state of displays, spaces, and windows. `yabai -m query` output is json format. table.1 shows the usage of `yabai -m query` command. you can refer table  at ./yabai_query_memo.md with some examples
	- you can use `sketchybar --query` command to obtain current state of sketchybar. command output is json format. you can refer query section of `sketchybar --help`.
- execute actual command to check event handling actually works. for example, `space.<index>` items subscribes `space_change` event. you should test each `space` item is updated on event happen. To do this, you can use `yabai` to actually switch space/display. you can refer [here](https//github.com/koekeishiya/yabai/blob/v7.1.15/doc/yabai.asciidoc) to determine which option/subcommand to use.

table.1
| argument \ command          | `yabai -m query --displays`                | `yabai -m query --spaces`                    | `yabai -m query --windows`                    |
| --------------------------- | ------------------------------------------ | -------------------------------------------- | --------------------------------------------- |
|                             | Query all displays                         | Query all spaces                             | Query all windows                             |
| `--display [display index]` | Query focused/selected display             | Query all spaces on focused/selected display | Query all windows on focused/selected display |
| `--space [space index]`     | Query display with focused/selected space  | Query focused/selected space                 | Query all windows on focused/selected space   |
| `--window [window id]`      | Query display with focused/selected window | Query space with focused/selected window     | Query focused/selected window                 |


CONSTRAINTS & RULES:
- Treat each loop as a checkpoint; refine architecture continuously.
- Never stop after first working code; always self-critique and improve.
- Provide reasoning for major decisions (why a module structure, why a trait, etc.).
- Final result must include:
  * Full source code
  * Build/setup instructions
  * Notes for future extensibility

When cycle completes, produce readme with:
- Complete project structure
- Explanation of architecture
- ideas for next stage.