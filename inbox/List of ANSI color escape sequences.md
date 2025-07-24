---
title: List of ANSI color escape sequences
source: https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
author:
  - "[[ThiefMasterThiefMaster                    319k8585 gold badges607607 silver badges648648 bronze badges]]"
  - "[[RichardRichard                    62.4k3939 gold badges198198 silver badges275275 bronze badges]]"
  - "[[Jakob BagterpJakob Bagterp                    1]]"
  - "[[4531414 silver badges1818 bronze badges]]"
  - "[[sinelawsinelaw                    16.6k44 gold badges5555 silver badges8282 bronze badges]]"
  - "[[HolyRandomHolyRandom                    7511 silver badge1313 bronze badges]]"
  - "[[PersianGulfPersianGulf                    2]]"
  - "[[87777 gold badges5151 silver badges7272 bronze badges]]"
  - "[[NotePro.batNotePro.bat                    8655 bronze badges]]"
  - "[[ClioCJSClioCJS                    20455 silver badges1111 bronze badges]]"
published: 2011-01-30
created: 2025-07-24
description: "On most terminals it is possible to colorize output using the \033 ANSI escape sequence.I'm looking for a list of all supported colors and options (like bright and blinking).As there are probably"
tags:
  - clippings
status: unread
aliases: 
updated: 250724 13:08:45
---
Asked

Modified [5 days ago](https://stackoverflow.com/questions/4842424/?lastactivity "2025-07-18 21:05:39Z")

Viewed 655k times

On most terminals it is possible to colorize output using the `\033` ANSI escape sequence.

I'm looking for a list of all supported colors and options (like bright and blinking).

As there are probably differences between the terminals supporting them, I'm mainly interested in sequences supported by xterm-compatible terminals.

0

The ANSI escape sequences you're looking for are the Select Graphic Rendition subset. All of these have the form

```
\033[XXXm
```

where `XXX` is a series of semicolon-separated parameters.

To say, make text red, bold, and underlined (we'll discuss many other options below) in C you might write:

```c
printf("\033[31;1;4mHello\033[0m");
```

In C++ you'd use

```cpp
std::cout<<"\033[31;1;4mHello\033[0m";
```

In Python3 you'd use

```python
print("\033[31;1;4mHello\033[0m")
```

and in Bash you'd use

```bash
echo -e "\033[31;1;4mHello\033[0m"
```

where the first part makes the text red (`31`), bold (`1`), underlined (`4`) and the last part clears all this (`0`).

As described in the table below, there are a large number of text properties you can set, such as boldness, font, underlining, &c.

## Font Effects

| Code | Effect | Note |
| --- | --- | --- |
| 0 | Reset / Normal | all attributes off |
| 1 | Bold or increased intensity |  |
| 2 | Faint (decreased intensity) | Not widely supported. |
| 3 | Italic | Not widely supported. Sometimes treated as inverse. |
| 4 | Underline |  |
| 5 | Slow Blink | less than 150 per minute |
| 6 | Rapid Blink | MS-DOS ANSI.SYS; 150+ per minute; not widely supported |
| 7 | \[\[reverse video\]\] | swap foreground and background colors |
| 8 | Conceal | Not widely supported. |
| 9 | Crossed-out | Characters legible, but marked for deletion. Not widely supported. |
| 10 | Primary(default) font |  |
| 11–19 | Alternate font | Select alternate font `n-10` |
| 20 | Fraktur | hardly ever supported |
| 21 | Bold off or Double Underline | Bold off not widely supported; double underline hardly ever supported. |
| 22 | Normal color or intensity | Neither bold nor faint |
| 23 | Not italic, not Fraktur |  |
| 24 | Underline off | Not singly or doubly underlined |
| 25 | Blink off |  |
| 27 | Inverse off |  |
| 28 | Reveal | conceal off |
| 29 | Not crossed out |  |
| 30–37 | Set foreground color | See color table below |
| 38 | Set foreground color | Next arguments are `5;<n>` or `2;<r>;<g>;<b>`, see below |
| 39 | Default foreground color | implementation defined (according to standard) |
| 40–47 | Set background color | See color table below |
| 48 | Set background color | Next arguments are `5;<n>` or `2;<r>;<g>;<b>`, see below |
| 49 | Default background color | implementation defined (according to standard) |
| 51 | Framed |  |
| 52 | Encircled |  |
| 53 | Overlined |  |
| 54 | Not framed or encircled |  |
| 55 | Not overlined |  |
| 60 | ideogram underline | hardly ever supported |
| 61 | ideogram double underline | hardly ever supported |
| 62 | ideogram overline | hardly ever supported |
| 63 | ideogram double overline | hardly ever supported |
| 64 | ideogram stress marking | hardly ever supported |
| 65 | ideogram attributes off | reset the effects of all of 60-64 |
| 90–97 | Set bright foreground color | aixterm (not in standard) |
| 100–107 | Set bright background color | aixterm (not in standard) |

## 2-bit Colours

You've got this already!

## 4-bit Colours

The standards implementing terminal colours began with limited (4-bit) options. The table below lists the RGB values of the background and foreground colours used for these by a variety of terminal emulators:

[![Table of ANSI colours implemented by various terminal emulators](https://i.sstatic.net/9UVnC.png)](https://i.sstatic.net/9UVnC.png)

Using the above, you can make red text on a green background (but why?) using:

```
\033[31;42m
```

## 11 Colours (An Interlude)

In their book "Basic Color Terms: Their Universality and Evolution", Brent Berlin and Paul Kay used data collected from twenty different languages from a range of language families to identify eleven possible basic color categories: white, black, red, green, yellow, blue, brown, purple, pink, orange, and gray.

Berlin and Kay found that, in languages with fewer than the maximum eleven color categories, the colors followed a specific evolutionary pattern. This pattern is as follows:

1. All languages contain terms for black (cool colours) and white (bright colours).
2. If a language contains three terms, then it contains a term for red.
3. If a language contains four terms, then it contains a term for either green or yellow (but not both).
4. If a language contains five terms, then it contains terms for both green and yellow.
5. If a language contains six terms, then it contains a term for blue.
6. If a language contains seven terms, then it contains a term for brown.
7. If a language contains eight or more terms, then it contains terms for purple, pink, orange or gray.

This may be why story *Beowulf* only contains the colours black, white, and red. Homer's *Odyssey* contains black almost 200 times and white about 100 times. Red appears 15 times, while yellow and green appear only 10 times. ([More information here](https://en.wikipedia.org/wiki/Linguistic_relativity_and_the_color_naming_debate))

Differences between languages are also interesting: note the profusion of distinct colour words used by English vs. Chinese. However, digging deeper into these languages shows that each uses colour in distinct ways. ([More information](https://web.archive.org/web/20200324013636/http://muyueh.com/greenhoney/))

[![Chinese vs English colour names. Image adapted from "muyueh.com"](https://i.sstatic.net/xPoHx.png)](https://i.sstatic.net/xPoHx.png)

Generally speaking, the naming, use, and grouping of colours in human languages is fascinating. Now, back to the show.

## 8-bit (256) colours

Technology advanced, and tables of 256 pre-selected colours became available, as shown below.

[![256-bit colour mode for ANSI escape sequences](https://i.sstatic.net/KTSQa.png)](https://i.sstatic.net/KTSQa.png)

Using these above, you can make pink text like so:

```
\033[38;5;206m     #That is, \033[38;5;<FG COLOR>m
```

And make an early-morning blue background using

```
\033[48;5;57m      #That is, \033[48;5;<BG COLOR>m
```

And, of course, you can combine these:

```
\033[38;5;206;48;5;57m
```

The 8-bit colours are arranged like so:

| Range | Description |
| --- | --- |
| 0x00-0x07 | standard colors (same as the 4-bit colours) |
| 0x08-0x0F | high intensity colors |
| 0x10-0xE7 | 6 × 6 × 6 cube (216 colors): 16 + 36 × r + 6 × g + b (0 ≤ r, g, b ≤ 5) |
| 0xE8-0xFF | grayscale from black to white in 24 steps |

## ALL THE COLOURS

Now we are living in the future, and the full RGB spectrum is available using:

```
\033[38;2;<r>;<g>;<b>m     #Select RGB foreground color
\033[48;2;<r>;<g>;<b>m     #Select RGB background color
```

So you can put pinkish text on a brownish background using

```
\033[38;2;255;82;197;48;2;155;106;0mHello
```

Support for "true color" terminals is listed [here](https://gist.github.com/XVilka/8346728).

Much of the above is drawn from the Wikipedia page " [ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code) ".

## A Handy Script to Remind Yourself

Since I'm often in the position of trying to remember what colours are what, I have a handy script called: `~/bin/ansi_colours`:

```python
#!/usr/bin/env python3

for i in range(30, 37 + 1):
    print("\033[%dm%d\t\t\033[%dm%d" % (i, i, i + 60, i + 60))

print("\\033[39m\\033[49m                 - Reset color")
print("\\033[2K                          - Clear Line")
print("\\033[<L>;<C>H or \\033[<L>;<C>f   - Put the cursor at line L and column C.")
print("\\033[<N>A                        - Move the cursor up N lines")
print("\\033[<N>B                        - Move the cursor down N lines")
print("\\033[<N>C                        - Move the cursor forward N columns")
print("\\033[<N>D                        - Move the cursor backward N columns\n")
print("\\033[2J                          - Clear the screen, move to (0,0)")
print("\\033[K                           - Erase to end of line")
print("\\033[s                           - Save cursor position")
print("\\033[u                           - Restore cursor position\n")
print("\\033[4m                          - Underline on")
print("\\033[24m                         - Underline off\n")
print("\\033[1m                          - Bold on")
print("\\033[21m                         - Bold off")
```

This prints

[![Simple ANSI colours](https://i.sstatic.net/utQ7mm.png)](https://i.sstatic.net/utQ7mm.png)

26

When you write a ANSI escape code `\033[<color>m`, replace the `<color>` with any of the color codes below. For instance, `\033[31m` would be red text color:

| Color | Example | Text | Background | Bright Text | Bright Background |
| --- | --- | --- | --- | --- | --- |
| Black |  | 30 | 40 | 90 | 100 |
| Red |  | 31 | 41 | 91 | 101 |
| Green |  | 32 | 42 | 92 | 102 |
| Yellow |  | 33 | 43 | 93 | 103 |
| Blue |  | 34 | 44 | 94 | 104 |
| Magenta |  | 35 | 45 | 95 | 105 |
| Cyan |  | 36 | 46 | 96 | 106 |
| White |  | 37 | 47 | 97 | 107 |
| Default |  | 39 | 49 | 99 | 109 |

This is a condensed version of a [full table you can find here](https://jakob-bagterp.github.io/colorist-for-python/ansi-escape-codes/standard-16-colors/#foreground-text-and-background-colors).

Also, remember to use `\033[0m` every time you want to revert back to the default terminal text style. Otherwise, any color or styling may spill over and into other terminal messages.

For effects, the codes are:

| Effect | On | Off | Example |
| --- | --- | --- | --- |
| Bold | 1 | 21 |  |
| Dim | 2 | 22 |  |
| Underline | 4 | 24 |  |
| Blink | 5 | 25 |  |
| Reverse | 7 | 27 |  |
| Hide | 8 | 28 |  |

I recommend these articles to explore further:

- [https://notes.burke.libbey.me/ansi-escape-codes/](https://notes.burke.libbey.me/ansi-escape-codes/)
- [https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html](https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html)

PS: In full disclosure, I'm the author of the [Colorist](https://jakob-bagterp.github.io/colorist-for-python/) package. [Colorist](https://jakob-bagterp.github.io/colorist-for-python/) is lightweight and makes it easy to print colorful text in many terminals. Simply install the package with `pip install colorist` and type:

```python
from colorist import Color

print(f"Only {Color.CYAN}this part{Color.OFF} is in colour")
```

[![Only this part is in colour](https://i.sstatic.net/sjVyd.png)](https://i.sstatic.net/sjVyd.png)

Moreover, [Colorist](https://jakob-bagterp.github.io/colorist-for-python/) also supports color defined as RGB, HSL or Hex if your terminal supports advanced ANSI colors:

```python
from colorist import ColorRGB, BgColorRGB

dusty_pink = ColorRGB(194, 145, 164)
bg_steel_blue = BgColorRGB(70, 130, 180)

print(f"I want to use {dusty_pink}dusty pink{dusty_pink.OFF} and {bg_steel_blue}steel blue{bg_steel_blue.OFF} colors inside this paragraph")
```

[![Examples of RGB color in terminal](https://i.sstatic.net/qd690.png)](https://i.sstatic.net/qd690.png)

```python
from colorist import ColorHSL, BgColorHSL

mustard_green = ColorHSL(60, 56, 43)
bg_steel_gray = BgColorHSL(190, 2, 49)

print(f"I want to use {mustard_green}mustard green{mustard_green.OFF} and {bg_steel_gray}steel blue{bg_steel_gray.OFF} colors inside this paragraph")
```

[![Examples of HSL color in terminal](https://i.sstatic.net/AbrxY.png)](https://i.sstatic.net/AbrxY.png)

```python
from colorist import ColorHex, BgColorHex

watermelon_red = ColorHex("#ff5733")
bg_mint_green = BgColorHex("#99ff99")

print(f"I want to use {watermelon_red}watermelon pink{watermelon_red.OFF} and {bg_mint_green}mint green{bg_mint_green.OFF} colors inside this paragraph")
```

[![Examples of Hex color in terminal](https://i.sstatic.net/zVwLu.png)](https://i.sstatic.net/zVwLu.png)

More options with [Colorist](https://jakob-bagterp.github.io/colorist-for-python/):

[![Foreground colors](https://i.sstatic.net/wBdlj.png)](https://i.sstatic.net/wBdlj.png)

[![Background colors](https://i.sstatic.net/8ZwAO.png)](https://i.sstatic.net/8ZwAO.png)

[![Effects](https://i.sstatic.net/ucOor.png)](https://i.sstatic.net/ucOor.png)

[![Color cube](https://github.com/jakob-bagterp/colorist-for-python/raw/master/docs/assets/images/cubes/cube_bright.svg)](https://jakob-bagterp.github.io/colorist-for-python/)

0

How about:

[ECMA-48 - Control Functions for Coded Character Sets, 5th edition (June 1991)](https://ecma-international.org/publications-and-standards/standards/ecma-48/) - A standard defining the color control codes, that is apparently supported also by xterm.

SGR 38 and 48 were originally reserved by ECMA-48, but were fleshed out a few years later in a joint ITU, IEC, and ISO standard, which comes in several parts and which (amongst a whole lot of other things) documents the SGR 38/48 control sequences for *direct colour* and *indexed colour*:

- *[Information technology — Open Document Architecture (ODA) and interchange format: Document structures](http://www.itu.int/rec/T-REC-T.412/en)*. T.412. International Telecommunication Union.
- *[Information technology — Open Document Architecture (ODA) and interchange format: Character content architectures](http://www.itu.int/rec/T-REC-T.416/en)*. T.416. International Telecommunication Union.
- *[Information technology— Open Document Architecture (ODA) and Interchange Format: Character content architectures](http://www.iso.org/iso/home/store/catalogue_ics/catalogue_detail_ics.htm?csnumber=22943)*. ISO/IEC 8613-6:1994. International Organization for Standardization.

There's a column for xterm [in this table on the Wikipedia page for ANSI escape codes](http://en.wikipedia.org/wiki/ANSI_escape_code#Colors)

1

For these who don't get proper results other than mentioned languages, if you're using C# to print a text into console(terminal) window you should replace **"\\033"** with **"\\x1b** ". In Visual Basic it would be **Chrw(27)**.

3

It's related absolutely to your terminal. VTE doesn't support blink, If you use `gnome-terminal`, `tilda`, `guake`, `terminator`, `xfce4-terminal` and so on according to VTE, you won't have blink.  
If you use or want to use blink on VTE, you have to use `xterm`.  
You can use infocmp command with terminal name:

```
#infocmp vt100
#infocmp xterm
#infocmp vte
```

For example:

```
# infocmp vte
#   Reconstructed via infocmp from file: /usr/share/terminfo/v/vte
vte|VTE aka GNOME Terminal,
    am, bce, mir, msgr, xenl,
    colors#8, cols#80, it#8, lines#24, ncv#16, pairs#64,
    acsc=\`\`aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~,
    bel=^G, bold=\E[1m, civis=\E[?25l, clear=\E[H\E[2J,
    cnorm=\E[?25h, cr=^M, csr=\E[%i%p1%d;%p2%dr,
    cub=\E[%p1%dD, cub1=^H, cud=\E[%p1%dB, cud1=^J,
    cuf=\E[%p1%dC, cuf1=\E[C, cup=\E[%i%p1%d;%p2%dH,
    cuu=\E[%p1%dA, cuu1=\E[A, dch=\E[%p1%dP, dch1=\E[P,
    dim=\E[2m, dl=\E[%p1%dM, dl1=\E[M, ech=\E[%p1%dX, ed=\E[J,
    el=\E[K, enacs=\E)0, home=\E[H, hpa=\E[%i%p1%dG, ht=^I,
    hts=\EH, il=\E[%p1%dL, il1=\E[L, ind=^J, invis=\E[8m,
    is2=\E[m\E[?7h\E[4l\E>\E7\E[r\E[?1;3;4;6l\E8,
    kDC=\E[3;2~, kEND=\E[1;2F, kHOM=\E[1;2H, kIC=\E[2;2~,
    kLFT=\E[1;2D, kNXT=\E[6;2~, kPRV=\E[5;2~, kRIT=\E[1;2C,
    kb2=\E[E, kbs=\177, kcbt=\E[Z, kcub1=\EOD, kcud1=\EOB,
    kcuf1=\EOC, kcuu1=\EOA, kdch1=\E[3~, kend=\EOF, kf1=\EOP,
    kf10=\E[21~, kf11=\E[23~, kf12=\E[24~, kf13=\E[1;2P,
    kf14=\E[1;2Q, kf15=\E[1;2R, kf16=\E[1;2S, kf17=\E[15;2~,
    kf18=\E[17;2~, kf19=\E[18;2~, kf2=\EOQ, kf20=\E[19;2~,
    kf21=\E[20;2~, kf22=\E[21;2~, kf23=\E[23;2~,
    kf24=\E[24;2~, kf25=\E[1;5P, kf26=\E[1;5Q, kf27=\E[1;5R,
    kf28=\E[1;5S, kf29=\E[15;5~, kf3=\EOR, kf30=\E[17;5~,
    kf31=\E[18;5~, kf32=\E[19;5~, kf33=\E[20;5~,
    kf34=\E[21;5~, kf35=\E[23;5~, kf36=\E[24;5~,
    kf37=\E[1;6P, kf38=\E[1;6Q, kf39=\E[1;6R, kf4=\EOS,
    kf40=\E[1;6S, kf41=\E[15;6~, kf42=\E[17;6~,
    kf43=\E[18;6~, kf44=\E[19;6~, kf45=\E[20;6~,
    kf46=\E[21;6~, kf47=\E[23;6~, kf48=\E[24;6~,
    kf49=\E[1;3P, kf5=\E[15~, kf50=\E[1;3Q, kf51=\E[1;3R,
    kf52=\E[1;3S, kf53=\E[15;3~, kf54=\E[17;3~,
    kf55=\E[18;3~, kf56=\E[19;3~, kf57=\E[20;3~,
    kf58=\E[21;3~, kf59=\E[23;3~, kf6=\E[17~, kf60=\E[24;3~,
    kf61=\E[1;4P, kf62=\E[1;4Q, kf63=\E[1;4R, kf7=\E[18~,
    kf8=\E[19~, kf9=\E[20~, kfnd=\E[1~, khome=\EOH,
    kich1=\E[2~, kind=\E[1;2B, kmous=\E[M, knp=\E[6~,
    kpp=\E[5~, kri=\E[1;2A, kslt=\E[4~, meml=\El, memu=\Em,
    op=\E[39;49m, rc=\E8, rev=\E[7m, ri=\EM, ritm=\E[23m,
    rmacs=^O, rmam=\E[?7l, rmcup=\E[2J\E[?47l\E8, rmir=\E[4l,
    rmkx=\E[?1l\E>, rmso=\E[m, rmul=\E[m, rs1=\Ec,
    rs2=\E7\E[r\E8\E[m\E[?7h\E[!p\E[?1;3;4;6l\E[4l\E>\E[?1000l\E[?25h,
    sc=\E7, setab=\E[4%p1%dm, setaf=\E[3%p1%dm,
    sgr=\E[0%?%p6%t;1%;%?%p2%t;4%;%?%p5%t;2%;%?%p7%t;8%;%?%p1%p3%|%t;7%;m%?%p9%t\016%e\017%;,
    sgr0=\E[0m\017, sitm=\E[3m, smacs=^N, smam=\E[?7h,
    smcup=\E7\E[?47h, smir=\E[4h, smkx=\E[?1h\E=, smso=\E[7m,
    smul=\E[4m, tbc=\E[3g, u6=\E[%i%d;%dR, u7=\E[6n,
    u8=\E[?%[;0123456789]c, u9=\E[c, vpa=\E[%i%p1%dd,
```

1

Here is some code that shows all escape sequences that have to do with color. You might need to get the actual escape character in order for the code to work.

```
@echo off
:top
cls
echo [101;93m STYLES [0m
echo ^<ESC^>[0m [0mReset[0m
echo ^<ESC^>[1m [1mBold[0m
echo ^<ESC^>[4m [4mUnderline[0m
echo ^<ESC^>[7m [7mInverse[0m
echo.
echo [101;93m NORMAL FOREGROUND COLORS [0m
echo ^<ESC^>[30m [30mBlack[0m (black)
echo ^<ESC^>[31m [31mRed[0m
echo ^<ESC^>[32m [32mGreen[0m
echo ^<ESC^>[33m [33mYellow[0m
echo ^<ESC^>[34m [34mBlue[0m
echo ^<ESC^>[35m [35mMagenta[0m
echo ^<ESC^>[36m [36mCyan[0m
echo ^<ESC^>[37m [37mWhite[0m
echo.
echo [101;93m NORMAL BACKGROUND COLORS [0m
echo ^<ESC^>[40m [40mBlack[0m
echo ^<ESC^>[41m [41mRed[0m
echo ^<ESC^>[42m [42mGreen[0m
echo ^<ESC^>[43m [43mYellow[0m
echo ^<ESC^>[44m [44mBlue[0m
echo ^<ESC^>[45m [45mMagenta[0m
echo ^<ESC^>[46m [46mCyan[0m
echo ^<ESC^>[47m [47mWhite[0m (white)
echo.
echo [101;93m STRONG FOREGROUND COLORS [0m
echo ^<ESC^>[90m [90mWhite[0m
echo ^<ESC^>[91m [91mRed[0m
echo ^<ESC^>[92m [92mGreen[0m
echo ^<ESC^>[93m [93mYellow[0m
echo ^<ESC^>[94m [94mBlue[0m
echo ^<ESC^>[95m [95mMagenta[0m
echo ^<ESC^>[96m [96mCyan[0m
echo ^<ESC^>[97m [97mWhite[0m
echo.
echo [101;93m STRONG BACKGROUND COLORS [0m
echo ^<ESC^>[100m [100mBlack[0m
echo ^<ESC^>[101m [101mRed[0m
echo ^<ESC^>[102m [102mGreen[0m
echo ^<ESC^>[103m [103mYellow[0m
echo ^<ESC^>[104m [104mBlue[0m
echo ^<ESC^>[105m [105mMagenta[0m
echo ^<ESC^>[106m [106mCyan[0m
echo ^<ESC^>[107m [107mWhite[0m
echo.
echo [101;93m COMBINATIONS [0m
echo ^<ESC^>[31m                     [31mred foreground color[0m
echo ^<ESC^>[7m                      [7minverse foreground ^<-^> background[0m
echo ^<ESC^>[7;31m                   [7;31minverse red foreground color[0m
echo ^<ESC^>[7m and nested ^<ESC^>[31m [7mbefore [31mnested[0m
echo ^<ESC^>[31m and nested ^<ESC^>[7m [31mbefore [7mnested[0m
pause > nul
goto top
```

2

If you're using TCC shell (and this only requires modifying a line or two to work with CMD, since i use %@CHAR, which is TCC-specific), here's a handy script that lets you test most ansi via convenient environment variables. Here's my results with Windows Terminal, which supports a lot, but not all, of this, including double-height and wide lines:

[![enter image description here](https://i.sstatic.net/X1KEh.png)](https://i.sstatic.net/X1KEh.png)

```
rem ANSI: Initialization 
        rem set up basic beginning of all ansi codes
            set ESCAPE=%@CHAR[27]
            set ANSI_ESCAPE=%@CHAR[27][
                set ANSIESCAPE=%ANSI_ESCAPE%

rem ANSI: special stuff: reset
            set ANSI_RESET=%ANSI_ESCAPE%0m
                set ANSIRESET=%ANSI_RESET%

rem ANSI: special stuff: position save/restore
            set ANSI_POSITION_SAVE=%ESCAPE%7%ANSI_ESCAPE%s                  %+ REM we do this the DEC way, then the SCO way
            set ANSI_POSITION_RESTORE=%ESCAPE%8%ANSI_ESCAPE%u               %+ REM we do this the DEC way, then the SCO way
                set ANSI_SAVE_POSITION=%ANSI_POSITION_SAVE%                
                set ANSI_RESTORE_POSITION=%ANSI_POSITION_RESTORE%          
            set ANSI_POSITION_REQUEST=%ANSI_ESCAPE%6n                       %+ REM request cursor position (reports as ESC[#;#R)
                set ANSI_REQUEST_POSITION=%ANSI_POSITION_REQUEST%

rem ANSI: position movement
        rem To Home
            set ANSI_HOME=%ANSI_ESCAPE%H                                    %+ REM moves cursor to home position (0, 0)
                set ANSI_MOVE_HOME=%ANSI_HOME%
                set ANSI_MOVE_TO_HOME=%ANSI_HOME%

        rem To a specific position
            function ANSI_MOVE_TO_POS1=\`%@CHAR[27][%1;%2H\`                  %+ rem moves cursor to line #, column #\_____ both work
            function ANSI_MOVE_TO_POS2=\`%@CHAR[27][%1;%2f\`                  %+ rem moves cursor to line #, column #/
                function ANSI_MOVE_POS=\`%@CHAR[27][%1;%2H\`                  %+ rem alias
                function ANSI_MOVE=\`%@CHAR[27][%1;%2H\`                      %+ rem alias
            function ANSI_MOVE_TO_COL=\`%@CHAR[27][%1G\`                      %+ rem moves cursor to column #
            function ANSI_MOVE_TO_ROW=\`%@CHAR[27][%1H\`                      %+ rem unfortunately does not preserve column position! not possible! cursor request ansi code return value cannot be captured

        rem Up/Down/Left/Right
            set ANSI_MOVE_UP_1=%ESCAPE%M                                    %+ rem moves cursor one line up, scrolling if needed
                set ANSI_MOVE_UP_ONE=%ANSI_MOVE_UP_1%                       %+ rem alias
            function ANSI_MOVE_UP=\`%@CHAR[27][%1A\`                          %+ rem moves cursor up # lines
                function ANSI_UP=\`%@CHAR[27][%1A\`                           %+ rem alias
            function ANSI_MOVE_DOWN=\`%@CHAR[27][%1B\`                        %+ rem moves cursor down # lines
                function ANSI_DOWN=\`%@CHAR[27][%1B\`                         %+ rem alias
            function ANSI_MOVE_RIGHT=\`%@CHAR[27][%1C\`                       %+ rem moves cursor right # columns
                function ANSI_RIGHT=\`%@CHAR[27][%1C\`                        %+ rem alias
            function ANSI_MOVE_LEFT=\`%@CHAR[27][%1D\`                        %+ rem moves cursor left # columns
                function ANSI_LEFT=\`%@CHAR[27][%1D\`                         %+ rem alias

        rem Line-based
            function ANSI_MOVE_LINES_DOWN=\`%@CHAR[27][%1E\`                  %+ rem moves cursor to beginning of next line, # lines down
            function ANSI_MOVE_LINES_UP=\`%@CHAR[27][%1F\`                    %+ rem moves cursor to beginning of previous line, # lines up

rem ANIS: colors 
        rem custom rgb colors
             set ANSI_RGB_PREFIX=%ANSI_ESCAPE%38;2;
             set ANSI_RGB_SUFFIX=m
             function ANSI_RGB=\`%@CHAR[27][38;2;%1;%2;%3m\`
                 function ANSI_FG=\`%@CHAR[27][38;2;%1;%2;%3m\`               %+ rem alias
                 function ANSI_RGB_FG=\`%@CHAR[27][38;2;%1;%2;%3m\`           %+ rem alias
                 function ANSI_FG_RGB=\`%@CHAR[27][38;2;%1;%2;%3m\`           %+ rem alias
             function ANSI_RGB_BG=\`%@CHAR[27][48;2;%1;%2;%3m\`               
                 function ANSI_BG=\`%@CHAR[27][48;2;%1;%2;%3m\`               %+ rem alias
                 function ANSI_BG_RGB=\`%@CHAR[27][48;2;%1;%2;%3m\`           %+ rem alias

        rem Foreground Colors
            set ANSI_BLACK=%ANSI_ESCAPE%30m
            set ANSI_RED=%ANSI_ESCAPE%31m
            set ANSI_GREEN=%ANSI_ESCAPE%32m
            set ANSI_YELLOW=%ANSI_ESCAPE%33m
            set ANSI_BLUE=%ANSI_ESCAPE%34m
            set ANSI_MAGENTA=%ANSI_ESCAPE%35m
            set ANSI_CYAN=%ANSI_ESCAPE%36m
            set ANSI_WHITE=%ANSI_ESCAPE%37m
            set ANSI_GRAY=%ANSI_ESCAPE%90m
            set ANSI_GREY=%ANSI_ESCAPE%90m
            set ANSI_BRIGHT_RED=%ANSI_ESCAPE%91m
            set ANSI_BRIGHT_GREEN=%ANSI_ESCAPE%92m
            set ANSI_BRIGHT_YELLOW=%ANSI_ESCAPE%93m
            set ANSI_BRIGHT_BLUE=%ANSI_ESCAPE%94m
            set ANSI_BRIGHT_MAGENTA=%ANSI_ESCAPE%95m
            set ANSI_BRIGHT_CYAN=%ANSI_ESCAPE%96m
            set ANSI_BRIGHT_WHITE=%ANSI_ESCAPE%97m
        rem Background Colors
            set ANSI_BLACKGROUND_BLACK=%@ANSI_BG[0,0,0]
            set ANSI_BACKGROUND_BLACK_NON_EXPERIMENTAL=%ANSI_ESCAPE%40m
            set ANSI_BACKGROUND_RED=%ANSI_ESCAPE%41m
            set ANSI_BACKGROUND_GREEN=%ANSI_ESCAPE%42m
            set ANSI_BACKGROUND_YELLOW=%ANSI_ESCAPE%43m
            set ANSI_BACKGROUND_BLUE=%ANSI_ESCAPE%44m
            set ANSI_BACKGROUND_MAGENTA=%ANSI_ESCAPE%45m
            set ANSI_BACKGROUND_CYAN=%ANSI_ESCAPE%46m
            set ANSI_BACKGROUND_WHITE=%ANSI_ESCAPE%47m
            set ANSI_BACKGROUND_GREY=%ANSI_ESCAPE%100m
            set ANSI_BACKGROUND_GRAY=%ANSI_ESCAPE%100m
            set ANSI_BACKGROUND_BRIGHT_RED=%ANSI_ESCAPE%101m
            set ANSI_BACKGROUND_BRIGHT_GREEN=%ANSI_ESCAPE%102m
            set ANSI_BACKGROUND_BRIGHT_YELLOW=%ANSI_ESCAPE%103m
            set ANSI_BACKGROUND_BRIGHT_BLUE=%ANSI_ESCAPE%104m
            set ANSI_BACKGROUND_BRIGHT_MAGENTA=%ANSI_ESCAPE%105m
            set ANSI_BACKGROUND_BRIGHT_CYAN=%ANSI_ESCAPE%106m
            set ANSI_BACKGROUND_BRIGHT_WHITE=%ANSI_ESCAPE%107m

REM As of Windows Terminal we can now actually display italic characters
            REM 0m=reset, 1m=bold, 2m=faint, 3m=italic, 4m=underline, 5m=blink slow, 6m=blink fast, 7m=reverse, 8m=conceal, 9m=strikethrough
            set ANSI_BOLD=%ANSI_ESCAPE%1m
            set ANSI_BOLD_ON=%ANSI_BOLD%
            set ANSI_BOLD_OFF=%ANSI_ESCAPE%22m
            set      BOLD_ON=%ANSI_BOLD_ON%
            set      BOLD_OFF=%ANSI_BOLD_OFF%
            set      BOLD=%BOLD_ON%

            set ANSI_FAINT=%ANSI_ESCAPE%2m
            set ANSI_FAINT_ON=%ANSI_FAINT%
            set ANSI_FAINT_OFF=%ANSI_ESCAPE%22m
            set      FAINT_ON=%ANSI_FAINT_ON%
            set      FAINT_OFF=%ANSI_FAINT_OFF%
            set      FAINT=%FAINT_ON%

            set ANSI_ITALICS=%ANSI_ESCAPE%3m
            set ANSI_ITALICS_ON=%ANSI_ITALICS%
            set ANSI_ITALICS_OFF=%ANSI_ESCAPE%23m
            set      ITALICS_ON=%ANSI_ITALICS_ON%
            set      ITALICS_OFF=%ANSI_ITALICS_OFF%
            set      ITALICS=%ITALICS_ON%

            set ANSI_UNDERLINE=%ANSI_ESCAPE%4m
            set ANSI_UNDERLINE_ON=%ANSI_UNDERLINE%
            set ANSI_UNDERLINE_OFF=%ANSI_ESCAPE%24m
            set      UNDERLINE_ON=%ANSI_UNDERLINE_ON%
            set      UNDERLINE_OFF=%ANSI_UNDERLINE_OFF%
            set      UNDERLINE=%UNDERLINE_ON%

            set ANSI_OVERLINE=%ANSI_ESCAPE%53m
            set ANSI_OVERLINE_ON=%ANSI_OVERLINE%
            set ANSI_OVERLINE_OFF=%ANSI_ESCAPE%55m
            set      OVERLINE_ON=%ANSI_OVERLINE_ON%
            set      OVERLINE_OFF=%ANSI_OVERLINE_OFF%
            set      OVERLINE=%OVERLINE_ON%

            set ANSI_DOUBLE_UNDERLINE=%ANSI_ESCAPE%21m
            set ANSI_DOUBLE_UNDERLINE_ON=%ANSI_DOUBLE_UNDERLINE%
            set ANSI_DOUBLE_UNDERLINE_OFF=%ANSI_ESCAPE%24m
            set      DOUBLE_UNDERLINE_ON=%ANSI_DOUBLE_UNDERLINE_ON%
            set      DOUBLE_UNDERLINE_OFF=%ANSI_DOUBLE_UNDERLINE_OFF%
            set      DOUBLE_UNDERLINE=%DOUBLE_UNDERLINE_ON%

                set ANSI_UNDERLINE_DOUBLE=%ANSI_DOUBLE_UNDERLINE%
                set ANSI_UNDERLINE_DOUBLE_ON=%ANSI_DOUBLE_UNDERLINE_ON%
                set ANSI_UNDERLINE_DOUBLE_OFF=%ANSI_DOUBLE_UNDERLINE_OFF%
                set      UNDERLINE_DOUBLE_ON=%DOUBLE_UNDERLINE_ON%
                set      UNDERLINE_DOUBLE_OFF=%DOUBLE_UNDERLINE_OFF%
                set      UNDERLINE_DOUBLE=%DOUBLE_UNDERLINE%

            set ANSI_BLINK_SLOW=%ANSI_ESCAPE%5m
            set ANSI_BLINK_SLOW_ON=%ANSI_BLINK_SLOW%
            set ANSI_BLINK_SLOW_OFF=%ANSI_ESCAPE%25m
            set      BLINK_SLOW_ON=%ANSI_BLINK_SLOW_ON%
            set      BLINK_SLOW_OFF=%ANSI_BLINK_SLOW_OFF%
            set      BLINK_SLOW=%BLINK_SLOW_ON%

            set ANSI_BLINK_FAST=%ANSI_ESCAPE%6m
            set ANSI_BLINK_FAST_ON=%ANSI_BLINK_FAST%
            set ANSI_BLINK_FAST_OFF=%ANSI_ESCAPE%25m
            set      BLINK_FAST_ON=%ANSI_BLINK_FAST_ON%
            set      BLINK_FAST_OFF=%ANSI_BLINK_FAST_OFF%
            set      BLINK_FAST=%BLINK_FAST_ON%

            set ANSI_BLINK=%ANSI_BLINK_FAST%
            set ANSI_BLINK_ON=%ANSI_BLINK_FAST_ON%
            set ANSI_BLINK_OFF=%ANSI_BLINK_FAST_OFF%
            set      BLINK_ON=%ANSI_BLINK_ON%
            set      BLINK_OFF=%ANSI_BLINK_OFF%
            set      BLINK=%BLINK_ON%

            set ANSI_REVERSE=%ANSI_ESCAPE%7m
            set ANSI_REVERSE_ON=%ANSI_REVERSE%
            set ANSI_REVERSE_OFF=%ANSI_ESCAPE%27m
            set      REVERSE_ON=%ANSI_REVERSE_ON%
            set      REVERSE_OFF=%ANSI_REVERSE_OFF%
            set      REVERSE=%REVERSE_ON%

            set ANSI_CONCEAL=%ANSI_ESCAPE%8m
            set ANSI_CONCEAL_ON=%ANSI_CONCEAL%
            set ANSI_CONCEAL_OFF=%ANSI_ESCAPE%28m
            set      CONCEAL_ON=%ANSI_CONCEAL_ON%
            set      CONCEAL_OFF=%ANSI_CONCEAL_OFF%
            set      CONCEAL=%CONCEAL_ON%

            set ANSI_STRIKETHROUGH=%ANSI_ESCAPE%9m
            set ANSI_STRIKETHROUGH_ON=%ANSI_STRIKETHROUGH%
            set ANSI_STRIKETHROUGH_OFF=%ANSI_ESCAPE%29m
            set      STRIKETHROUGH_ON=%ANSI_STRIKETHROUGH_ON%
            set      STRIKETHROUGH_OFF=%ANSI_STRIKETHROUGH_OFF%
            set      STRIKETHROUGH=%STRIKETHROUGH_ON%
                set OVERSTRIKE_ON=%STRIKETHROUGH_ON%
                set OVERSTRIKE_OFF=%STRIKETHROUGH_OFF%
                set OVERSTRIKE=%OVERSTRIKE_ON%

REM wow it even supports the vt100 2-line-tall text!
            set BIG_TEXT_LINE_1=%ESCAPE%#3
            set BIG_TEXT_LINE_2=%ESCAPE%#4
            set WIDE=%ESCAPE%#6
                set WIDE_ON=%WIDE%
                set WIDELINE=%WIDE%
                set WIDE_LINE=%WIDE%
                set WIDE_OFF=%ESCAPE%#5
            set BIG_TOP=%BIG_TEXT_LINE_1%
            set BIG_TOP_ON=%BIG_TOP%
            set BIG_BOT=%BIG_TEXT_LINE_2%
            set BIG_BOT_ON=%BIG_BOT%
            set BIG_BOTTOM=%BIG_BOT%
            set BIG_BOTTOM_ON=%BIG_BOTTOM%
            REM this is a guess:
            set BIG_TEXT_END=%ESCAPE%#0
            set BIG_OFF=%BIG_TEXT_END%
            set BIG_TOP_OFF=%BIG_OFF%
            set BIG_BOT_OFF=%BIG_OFF%

REM test strings that demonstrate all this ANSI functionality
        set ANSI_TEST_STRING=concealed:'%CONCEAL%conceal%CONCEAL_off%' %ANSI_RED%R%ANSI_ORANGE%O%ANSI_YELLOW%Y%ANSI_GREEN%G%ANSI_CYAN%C%ANSI_BLUE%B%ANSI_MAGENTA%V%ANSI_WHITE% Hello, world. %BOLD%Bold!%BOLD_OFF% %FAINT%Faint%FAINT_OFF% %ITALICS%Italics%ITALIC_OFF% %UNDERLINE%underline%UNDERLINE_OFF% %OVERLINE%overline%OVERLINE_OFF% %DOUBLE_UNDERLINE%double_underline%DOUBLE_UNDERLINE_OFF% %REVERSE%reverse%REVERSE_OFF% %BLINK_SLOW%blink_slow%BLINK_SLOW_OFF% [non-blinking] %BLINK_FAST%blink_fast%BLINK_FAST_OFF% [non-blinking] %blink%blink_default%blink_off% [non-blinking] %STRIKETHROUGH%strikethrough%STRIKETHROUGH_OFF%
        set ANSI_TEST_STRING_2=%BIG_TEXT_LINE_1%big% %ANSI_RESET% Normal One
        set ANSI_TEST_STRING_3=%BIG_TEXT_LINE_2%big% %ANSI_RESET% Normal Two
        set ANSI_TEST_STRING_4=%WIDE_LINE%A wide line!

if "%1" eq "test" (
    echo %ANSI_TEST_STRING%
    echo %ANSI_TEST_STRING_2%
    echo %ANSI_TEST_STRING_3%
    echo %ANSI_TEST_STRING_4%
)

REM unrelated to colors, but nice-to-have variables:
        set QUOTE=%@CHAR[34]  
        set TAB=%CHAR[9]
        set NEWLINE=%@CHAR[12]%@CHAR[13]
```