---
title: クソでかinit.lua
emoji: 💤
type: tech
topics:
  - lua
  - neovim
published: true
published_at: 2023-01-06 11:58
created: 250426 08:55:26
updated: 250623 09:41:03
---

[init.lua](https://github.com/sugiura-hiromichi/.config/blob/master/nvim/init.lua)がそれなりに充実してきたので整理も兼ねて紹介記事を書こう！と思いついたので実行していきたいと思います。<br/>
この記事の対象としては１年ほど前の自分、つまりコーディング未経験者を想定しています。

# 全体像

最新版は上記のリンクから。この記事の内容は基本的に更新しないと思います。

```lua: init.lua
if vim.fn.expand '%:p' == '' then
	vim.cmd [[e $MYVIMRC]]
end
vim.cmd 'colo catppuccin'

local p = vim.opt -- d: variables
p.list = true
p.listchars = {
	tab = '│ ',
}
p.pumblend = 22
p.relativenumber = true
p.number = true
p.autowriteall = true
p.termguicolors = true
p.clipboard:append { 'unnamedplus' }
p.autochdir = true
p.laststatus = 0
p.cmdheight = 0 --until `folke/noice` recovered

local aucmd = vim.api.nvim_create_autocmd -- d: autocmd
-- d: Just using `set fo-=cro` won't work since many filetypes set/expand `formatoption`
aucmd('filetype', {
	callback = function()
		p.fo = { j = true }
		p.softtabstop = 3
		p.tabstop = 3
		p.shiftwidth = 3
	end,
})

local usrcmd = vim.api.nvim_create_user_command
usrcmd('Make', function(opts)
	local cmd = '<cr> '
	local ft = vim.bo.filetype
	if ft == 'rust' then
		cmd = '!cargo '
	elseif ft == 'lua' or ft == 'cpp' or ft == 'c' then
		cmd = '!make '
	end
	vim.cmd(cmd .. opts.args)
end, {
	nargs = '*',
})

local map = vim.keymap.set -- d: keymap
map('n', '<esc>', '<cmd>noh<cr>') -- <esc> to noh
map('i', '<c-[>', '<c-[><cmd>update | lua vim.lsp.buf.format{async=true}<cr>')
map({ 'n', 'v' }, '$', '^') -- swap $ & ^
map({ 'n', 'v' }, '^', '$')
map({ 'n', 'v' }, ',', '@:') --repeat previous command
map('i', '<c-n>', '<down>') --emacs keybind
map('i', '<c-p>', '<up>')
map('i', '<c-b>', '<left>')
map('i', '<c-f>', '<right>')
map('i', '<c-a>', '<home>')
map('i', '<c-e>', '<end>')
map('i', '<c-d>', '<del>')
map('i', '<c-k>', '<right><c-c>v$hs')
map('i', '<c-u>', '<c-c>v^s')
map('i', '<a-d>', '<right><c-c>ves')
map('i', '<a-f>', '<c-right>')
map('i', '<a-b>', '<c-left>')
map({ 'n', 'v' }, '<tab>', require('todo-comments').jump_next)
map({ 'n', 'v' }, '<s-tab>', require('todo-comments').jump_prev)
map('n', '<cr>', ':Make ') -- execute shell command
map('n', '<s-cr>', ':!')
map({ 'i', 'n', 'v' }, '<a-left>', '<c-w><') -- change window size
map({ 'i', 'n', 'v' }, '<a-down>', '<c-w>+')
map({ 'i', 'n', 'v' }, '<a-up>', '<c-w>-')
map({ 'i', 'n', 'v' }, '<a-right>', '<c-w>>')
map('n', 't', require('telescope.builtin').builtin) -- Telescope
map('n', '<space>o', require('telescope.builtin').lsp_document_symbols)
map('n', '<space>d', require('telescope.builtin').diagnostics)
map('n', '<space>b', require('telescope.builtin').buffers)
map('n', '<space>e', require('telescope').extensions.file_browser.file_browser)
map('n', '<space>f', require('telescope').extensions.frecency.frecency)
map('n', '<space>c', '<cmd>TodoTelescope<cr>')
map('n', '<space>n', require('telescope').extensions.notify.notify)
map({ 'n', 'v' }, '<space>a', '<cmd>Lspsaga code_action<cr>')
map('n', '<space>j', '<cmd>Lspsaga lsp_finder<cr>') --`j` stands for jump
map('n', '<space>r', '<cmd>Lspsaga rename<cr>')
map('n', '<space>h', '<cmd>Lspsaga hover_doc<cr>')
map('n', '<c-j>', '<cmd>Lspsaga diagnostic_jump_next<cr>')
map('n', '<c-k>', '<cmd>Lspsaga diagnostic_jump_prev<cr>')

require('packer').startup(function(use) -- d: package
	use 'wbthomason/packer.nvim' -- NOTE: required
	use 'nvim-lua/plenary.nvim'
	use 'kkharji/sqlite.lua'
	use 'MunifTanjim/nui.nvim'
	use 'nvim-tree/nvim-web-devicons' -- NOTE: appearance
	use {
		'amdt/sunset',
		config = function()
			vim.g.sunset_latitude = 35.02
			vim.g.sunset_longitude = 135.78
		end,
	}
	use {
		'catppuccin/nvim',
		as = 'catppuccin',
		config = function()
			require('catppuccin').setup {
				background = {
					dark = 'frappe',
				},
				dim_inactive = {
					enabled = true,
				},
			}
		end,
	}
	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		config = function()
			require('nvim-treesitter.configs').setup {
				ensure_installed = { 'bash', 'markdown_inline' },
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
			}
		end,
	}
	use {
		'rcarriga/nvim-notify',
		config = function()
			vim.notify = require 'notify'
			vim.notify_once = require 'notify'
		end,
	} -- NOTE: UI
	use {
		'folke/todo-comments.nvim',
		config = function()
			require('todo-comments').setup {
				keywords = {
					FIX = { alt = { 'e' } }, -- e: `e` stands for error
					TODO = {
						color = 'hint',
						alt = { 'q' }, -- q: `q` stands for question
					},
					HACK = {
						color = 'doc',
						alt = { 'a' }, -- a: `a` stands for attention
					},
					WARN = { alt = { 'x' } }, -- x: `x` is abbreviation of `XXX`
					PERF = {
						color = 'cmt',
						alt = { 'p' }, -- p: `p` stands for performance
					},
					NOTE = {
						color = 'info',
						alt = { 'd' }, -- d: `d` stands for description
					},
					TEST = { alt = { 't', 'PASS', 'FAIL' } }, -- t: `t` stands for test
				},
				colors = {
					cmt = { 'Comment' },
					doc = { 'SpecialComment' },
					todo = { 'Todo' },
				},
			}
		end,
	}
	--[[	
	use {
		'folke/noice.nvim',
		config = function()
			require('noice').setup {
				presets = {
					bottom_search = true,
				},
			}
		end,
	}
]]
	use {
		'windwp/nvim-autopairs',
		config = function() -- NOTE: Input Helper
			require('nvim-autopairs').setup {
				map_c_h = true,
			}
		end,
	}
	use {
		'nvim-telescope/telescope.nvim',
		tag = '0.1.0',
		config = function() -- NOTE: Fuzzy Search
			require('telescope').setup {
				extensions = {
					file_browser = {
						hidden = true,
						hide_parent_dir = true,
					},
				},
			}
			require('telescope').load_extension 'frecency'
			require('telescope').load_extension 'file_browser'
		end,
	}
	use 'nvim-telescope/telescope-frecency.nvim'
	use 'nvim-telescope/telescope-file-browser.nvim'
	use {
		'williamboman/mason.nvim',
		config = function() -- NOTE: lsp
			require('mason').setup()
		end,
	}
	use {
		'williamboman/mason-lspconfig.nvim',
		config = function()
			require('mason-lspconfig').setup {
				ensure_installed = {
					'bashls',
					'sumneko_lua',
					'rust_analyzer@nightly',
				},
			}
		end,
	}
	use {
		'neovim/nvim-lspconfig',
		config = function()
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

			-- d: rust_analyzer
			require('lspconfig').rust_analyzer.setup {
				capabilities = capabilities,
				settings = {
					['rust-analyzer'] = {
						hover = {
							actions = {
								reference = {
									enable = true,
								},
							},
						},
						inlayHints = {
							closingBraceHints = {
								minLines = 0,
							},
							lifetimeElisionHints = {
								enable = 'always',
								useParameterNames = true,
							},
							maxLength = 0,
							typeHints = {
								hideNamedConstructor = false,
							},
						},
						lens = {
							implementations = {
								enable = false,
							},
						},
						rustfmt = {
							rangeFormatting = {
								enable = true,
							},
						},
						semanticHighlighting = {
							operator = {
								specialization = {
									enable = true,
								},
							},
						},
						typing = {
							autoClosingAngleBrackets = {
								enable = true,
							},
						},
						workspace = {
							symbol = {
								search = {
									kind = 'all_symbols',
								},
							},
						},
					},
				},
			}

			-- d: lua
			require('lspconfig').sumneko_lua.setup {
				capabilities = capabilities,
				settings = {
					Lua = {
						runtime = {
							version = 'LuaJIT',
						},
						diagnostics = {
							globals = { 'vim' },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file('', true),
							checkThirdParty = false,
						},
						telemetry = {
							enable = false,
						},
					},
				},
			}

			-- d: clangd
			require('lspconfig').clangd.setup {
				capabilities = capabilities,
			}
		end,
	}
	use {
		'glepnir/lspsaga.nvim',
		branch = 'main',
		config = function()
			require('lspsaga').init_lsp_saga {
				saga_winblend = 20,
				max_preview_lines = 10,
				code_action_lightbulb = {
					enable = false,
				},
				finder_action_keys = {
					open = '<cr>',
					vsplit = '<c-v>',
					split = '<c-x>',
				},
				definition_action_keys = {
					edit = '<cr>',
					vsplit = '<c-v>',
					split = '<c-x>',
					tabe = 't',
				},
			}
		end,
	}
	use {
		'jose-elias-alvarez/null-ls.nvim',
		config = function()
			local nls = require 'null-ls'
			nls.setup {
				sources = {
					nls.builtins.formatting.dprint.with { filetypes = { 'markdown', 'json', 'toml' } },
					nls.builtins.formatting.stylua,
				},
			}
		end,
	}
	use {
		'hrsh7th/nvim-cmp',
		config = function() -- NOTE: cmp
			local luasnip = require 'luasnip'
			local cmp = require 'cmp'
			cmp.setup {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert {
					['<a-k>'] = cmp.mapping.scroll_docs(-10),
					['<a-j>'] = cmp.mapping.scroll_docs(10),
					['<c-c>'] = cmp.mapping.abort(),
					['<tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.confirm {
								behavior = cmp.ConfirmBehavior.Insert,
								select = true,
							}
						else
							fallback()
						end
					end, { 'i', 's', 'c' }),
					['<s-tab>'] = cmp.mapping(function(fallback)
						if luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's', 'c' }),
					['<c-n>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { 'i', 's', 'c' }),
					['<c-p>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { 'i', 's', 'c' }),
				},
				sources = {
					{ name = 'luasnip' },
					{ name = 'nvim_lsp' },
					{ name = 'nvim_lua' },
					{ name = 'nvim_lsp_signature_help' },
					{ name = 'buffer' },
				},
			}

			cmp.setup.cmdline('/', {
				sources = {
					{ name = 'buffer' },
				},
			})

			cmp.setup.cmdline(':', {
				sources = {
					{ name = 'path' },
					{ name = 'cmdline' },
					{ name = 'buffer' },
				},
			})
		end,
	}
	use 'hrsh7th/cmp-nvim-lsp'
	use 'hrsh7th/cmp-nvim-lua'
	use 'hrsh7th/cmp-nvim-lsp-signature-help'
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/cmp-path'
	use 'hrsh7th/cmp-cmdline'
	use 'saadparwaiz1/cmp_luasnip'
	use 'L3MON4D3/LuaSnip'
end)
```

init.luaは分割しておくと管理しやすいよ！って各所でいわれています。おっしゃる通りだと思います。

が、自分はあちこちファイルを行き来するのが面倒なのでやっていません←

# デフォルトファイル
 
 ```lua
 if vim.fn.expand '%:p' == '' then
	vim.cmd [[e $MYVIMRC]]
end
```
 
 開くファイルを指定せずに`nvim`した場合`inil.lua`を開く様にしています。
 こうすることでどこからでも楽に`init.lua`できます。
 尚、この方法で開いた場合一度`:e`するまでハイライトが死んでます😢　有識者助けて
 
 # オプション
 
 ```lua
 local p = vim.opt -- d: variables
p.list = true
p.listchars = {
	tab = '│ ',
}
p.pumblend = 22
p.relativenumber = true
p.number = true
p.autowriteall = true
p.termguicolors = true
p.clipboard:append { 'unnamedplus' }
p.autochdir = true
p.laststatus = 0
p.cmdheight = 0 --until `folke/noice` recovered
```

### `p.list=true`

としておくと`listchar`と呼ばれる文字たち(tab, eol など)を目立たせることができます。

### `p.listchars={..}`

でどの様に目立たせるかを指定できます。
自分はインデントをspaceではなくtabにしているのでこの設定をしておくことで[indentline](https://github.com/Yggdroot/indentLine)系のプラグインを入れなくとも同じことを再現できます。
- なんなら大体のindentline系のプラグインは代替インデント幅が４文字以外だと表示がおかしくなります。(自分はインデント３文字にしているので致命的)
- この設定ではそのデメリットもないのでこの形に落ち着いています。

### `p.pumblend=22`

では**p**op **u**p **m**enu、要はfloating windowの背景透過率を指定します。0で不透明、100で透明

### `p.relativenumber=true`

と指定することで左端の行番号をカーソルのある行からのオフセットとして表示できます。
- コードが長くなって行数が３桁とかになってくると数行移動するのにいちいち`121G`などとするのが面倒に感じていました。
- オフセットが分かっていれば`6k`、`10j`と脳死でできるので思いのほか重宝しています。（地味にGよりk、jの方が押しやすいってのもあるかも）

### `p.number=true`

も同時に指定してやるとカーソルのある行だけ、絶対行数が表示されます。
これをfalseにすると、カーソルのある行は0と表示されます。

### `p.autowriteall=true`

としておくと別のバッファにいく時やneovimから出た時に自動で変更を保存してくれます。
自分の場合、基本neovim開きっぱなし、fuzzy_finderで頻繁にあちこち行ったり来たりしてるのでこれがないとストレスフル⚰️
- `p.awa=true`としても同じ。\\(awa)/

### `p.termguicolors=true`

みなさんご存知。これmacのデフォルトのterminalでは効かないんですよねぇ 流石に時代錯誤な気がします

### `p.clipboard:append { 'unnamedplus' }`

としておくとシステムのclipboardと連携してくれます。これもみなさんご存知ですね。~~luaでどう書けばいいのか地味に困る。~~[ドキュメント読もう](https://github.com/nanotee/nvim-lua-guide)

### `p.autochdir=true`

によりneovim上でのカレントディレクトリをファイルの変更に合わせて追尾してくれます。
自分は`:!`を`<s-cr>`に割り当てて多用しているのですがその中で簡単なgit操作などを行うのでこの設定をしておかないと⚰️

### `p.laststatus=0`

でステータスラインを非表示にできます。尚、完全に非表示にできるわけではなくwindowを縦に分割すると顔を出します。

### `p.cmdheight=0`

とすることで必要のない時にcmdlineを隠すことができます。
- 蛇足
>neovimではvimの基本的なUIもユーザーがカスタマイズできる様にしよう!という動きの元、
vimのcコードをひっくり返してapiの開発が進んでいます。
[folke/noice](https://github.com/folke/noice.nvim)も同じ目的を持ったプラグインです。
ですがこのapiは目下開発中なので当然予期しないバグなどが有り得ます(@nightly)
`neovim --HEAD`を使用している場合、neovim側のバグにより`noice.nvim`を使ってcmdlineを開こうとすると[クラッシュ](https://github.com/folke/noice.nvim/issues/298)します。
なのでこのバグが修正されるまでは`noice.nvim`を使わずこのオプションを設定しています。

# AutoCmd

```lua
local aucmd = vim.api.nvim_create_autocmd -- d: autocmd
-- d: Just using `set fo-=cro` won't work since many filetypes set/expand `formatoption`
aucmd('filetype', {
	callback = function()
		p.fo = { j = true }
		p.softtabstop = 3
		p.tabstop = 3
		p.shiftwidth = 3
	end,
})
```

vimのautocmdって、なんか適切にaugroupでまとめないとうまく働かない、みたいなのよく聞くけど
ぶっちゃけゼェんぜん理解出来てないです。でも今のままで問題ないので放置してます。

このautocmdは任意のfiletypeを対象にしています。

```lua
p.softtabstop = 3
p.tabstop = 3
p.shiftwidth = 3
```

これらをわざわざautocmdで設定しているのは、普通に書くと外部ツール（具体的にはrust-analyzer）の影響で正しく反映されなかったからです。
同じ記述を２箇所に書くのも野暮ったいのでまとめて任意の`ft`に対して設定することでまとめています。

# UserCmd

```lua
local usrcmd = vim.api.nvim_create_user_command
usrcmd('Make', function(opts)
	local cmd = '<cr> '
	local ft = vim.bo.filetype
	if ft == 'rust' then
		cmd = '!cargo '
	elseif ft == 'lua' or ft == 'cpp' or ft == 'c' then
		cmd = '!make '
	end
	vim.cmd(cmd .. opts.args)
end, {
	nargs = '*',
})
```

(Neo)vimにある程度詳しい方なら、*これ`:make`じゃあかんの？* となると思います。
自分も初めは *`:make`うまいこと使えば便利やん。使お* と思っていましたが、幾つかの点に引っかかっていました。
- コマンドの実行が失敗した場合、デフォルトだとエラーメッセージが書かれたtmpファイルが自動で開かれる。これが鬱陶しい。
- `p.shellpipe`をエラーファイルが作られないように(例 `p.shellpipe='echo Executing...'`)設定してやればtmpファイルは作られないが、今度は *エラーしたのにエラーファイルが作られない* というエラーメッセが表示される。🥹

他にも細かい不満点はありましたが、それらは適切に設定してやると回避できました。

これら二つの問題を回避するため`Make`コマンドを作りました。`nargs='*'`としてやることで任意個の引数を受け取れます。これを`<cr>`にマッピングして即座に呼び出せる様にしています。

# Key Mapping

```lua
local map = vim.keymap.set -- d: keymap
map('n', '<esc>', '<cmd>noh<cr>') -- <esc> to noh
map('i', '<c-[>', '<c-[><cmd>update | lua vim.lsp.buf.format{async=true}<cr>')
map({ 'n', 'v' }, '$', '^') -- swap $ & ^
map({ 'n', 'v' }, '^', '$')
map({ 'n', 'v' }, ',', '@:') --repeat previous command
map('i', '<c-n>', '<down>') --emacs keybind
map('i', '<c-p>', '<up>')
map('i', '<c-b>', '<left>')
map('i', '<c-f>', '<right>')
map('i', '<c-a>', '<home>')
map('i', '<c-e>', '<end>')
map('i', '<c-d>', '<del>')
map('i', '<c-k>', '<right><c-c>v$hs')
map('i', '<c-u>', '<c-c>v^s')
map('i', '<a-d>', '<right><c-c>ves')
map('i', '<a-f>', '<c-right>')
map('i', '<a-b>', '<c-left>')
map({ 'n', 'v' }, '<tab>', require('todo-comments').jump_next)
map({ 'n', 'v' }, '<s-tab>', require('todo-comments').jump_prev)
map('n', '<cr>', ':Make ') -- execute shell command
map('n', '<s-cr>', ':!')
map({ 'i', 'n', 'v' }, '<a-left>', '<c-w><') -- change window size
map({ 'i', 'n', 'v' }, '<a-down>', '<c-w>+')
map({ 'i', 'n', 'v' }, '<a-up>', '<c-w>-')
map({ 'i', 'n', 'v' }, '<a-right>', '<c-w>>')
map('n', 't', require('telescope.builtin').builtin) -- Telescope
map('n', '<space>o', require('telescope.builtin').lsp_document_symbols)
map('n', '<space>d', require('telescope.builtin').diagnostics)
map('n', '<space>b', require('telescope.builtin').buffers)
map('n', '<space>e', require('telescope').extensions.file_browser.file_browser)
map('n', '<space>f', require('telescope').extensions.frecency.frecency)
map('n', '<space>c', '<cmd>TodoTelescope<cr>')
map('n', '<space>n', require('telescope').extensions.notify.notify)
map({ 'n', 'v' }, '<space>a', '<cmd>Lspsaga code_action<cr>')
map('n', '<space>j', '<cmd>Lspsaga lsp_finder<cr>') --`j` stands for jump
map('n', '<space>r', '<cmd>Lspsaga rename<cr>')
map('n', '<space>h', '<cmd>Lspsaga hover_doc<cr>')
map('n', '<c-j>', '<cmd>Lspsaga diagnostic_jump_next<cr>')
map('n', '<c-k>', '<cmd>Lspsaga diagnostic_jump_prev<cr>')
```

全部話してるとキリがないのでかいつまんで行きます。

### `map('n', '<esc>', '<cmd>noh<cr>')`

で`<esc>`に検索時のハイライト消しを割り当てています。~~中身のないコピー記事~~いろいろな記事でなぜか`<esc><esc>`に割り当てられているやつですね！

### `map('i', '<c-[>', '<c-[><cmd>update | lua vim.lsp.buf.format{async=true}<cr>')`

おそらく世のコーダーに呆れられることをしています。`<c-[>==<esc>`と思ってください。
- 他にも`<c-m>==<cr>`,`<c-i>==<tab>`だったりします

insert modeで`<c-[>`と入力するとまず`<c-[>`が送られnormal modeに入ります。次に`:update`が実行されバッファに変更があった場合保存されます。最後に`lua vim.lsp.buf.format{async=true}`が実行され、コードがフォーマットされます。formatterが見つからない場合エラーメッセが表示されます。いつかきちんと書き直したいです。

### `map({ 'n', 'v' }, '$', '^') & map({ 'n', 'v' }, '^', '$')`

デフォルトでは行末移動は`$(shift+4)`　行頭移動は`^(shift+6)`なのですが、
行頭移動は左側へ、行末移動は右側へ行くのにキーボード上では逆になっていて毎回混乱していました。なのでより直感的にするためにこれらのkeyを交換しています。

### `map({ 'n', 'v' }, ',', '@:')`

とすることで直前のコマンドを繰り返すことができます。vimでは`.`に直前の文字列操作を繰り返す機能が割り当てられています。dot repeatってやつですね。コマンドに対してもそれと同じ感覚の機能が欲しかったのでこのマップにしています。

### `map('i', '<a-d>', '<right><c-c>ves')`

ターミナル上では`option+d(mac)`で単語削除できます。
vimでは`<a or m-ﾅﾝﾄｶ>`とすることで修飾キーとして`option(mac)`を使えます。
他OSの`alt`に当たるやつ。<br/>
`<a-f>` `<a-b>`についても同様。

### `map({ 'i', 'n', 'v' }, '<a-left>', '<c-w><')`

`<c-w>`系のキーマップはwindowの操作、移動に主に使われています。
コメントにも書いてある通り`<c-w><` `<c-w>+` `<c-w>-` `<c-w>>`はウィンドウのサイズを調整するのに使われます。正直デフォルトのままでも使いやすいんですが、
サイズ調整だけは連打できないのが致命的に辛いのでマッピングを作っています。
ちなみに`<a-left>`のleftとは左矢印キーのことです。

### telescope & lsp系キーマップ

プラグインのとこでまとめて紹介します。

# プラグイン

長いので端折って紹介していきます。大分厳選しているはずなんですけどね..

## ライブラリ系

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim): 何に必要なんだっけ..
- [sqlite.lua](https://github.com/kkharji/sqlite.lua): [telescope-frecency](https://github.com/nvim-telescope/telescope-frecency.nvim)を使うのに必要
- [nui.nivm](https://github.com/MunifTanjim/nui.nvim): [noice.nivm](https://github.com/folke/noice.nvim)に必要

## 見た目系（？）

エディタの見た目（主に色）をいい感じにしてくれる奴らです。個人的に色ってUIとはまたなんか違うよなと思うので分けていますがそんなに深い意味はありません。

### [amdt/sunset](https://github.com/amdt/sunset)

```lua
use {
	'amdt/sunset',
	config = function()
		vim.g.sunset_latitude = 35.02
		vim.g.sunset_longitude = 135.78
	end,
}
```

緯度と経度を指定してやるとその場所の日の出、日の入りに合わせて自動でbackgroundをスイッチしてくれます。つまり、これの設定を安易に晒すということは自分の住所を晒すということです。まぁダミーかもしれんけど

実は使ってるcolorscheme（とターミナルエミュレータ）によってはこのプラグインは必要ありません。
いつからかneovimはターミナルの背景色を判定し、それに合わせてbackgroundの`light` `dark`を設定してくれる様になりました。
更に、[warp](https://github.com/warpdotdev/warp)など、システムの外観に合わせて自動でターミナルのlight,darkを切り替えてくれるターミナルエミュレータ~~itermにこの設定ないの未だに信じられない~~ を使っている場合は何もせずともこのプラグインと同じ恩恵を得ることができます。（なんならより柔軟に設定できる）

余談ですが、これが原因で一時期itermからwarpに移行していた時期がありました。ですが、色表示がおかしい（今は改善されています）、補完はwarp-builtinよりiterm+figの方が優秀、itermの方がカスタマイズ性が高い、などの理由（figの存在が一番大きい）により結局itermに落ち着いています。itermでは`cmd+shift+o`でspotlightの様なものが開くのでそこからcolorschemeを切り替えると便利です。

### [catppuccin/nvim](https://github.com/catppuccin/nvim)

```lua
use {
	'catppuccin/nvim',
	as = 'catppuccin',
	config = function()
		require('catppuccin').setup {
			background = {
				dark = 'frappe',
			},
			dim_inactive = {
				enabled = true,
			},
		}
	end,
}
```

colorschemeは語り出すと止まらないのですが、個人的にdark themeよりlight themeの方が好きなためdark themeが蔓延っている浮世に憂いが止まりません。
しかし、夜中は背景が暗い方が見やすいため基本的にはlight, dark両方に対応しているcolorschemeしか使っていません。
このcolorschemeはカッコよさと見やすさが両立されていてかつlight themeもちゃんと腰を入れて作っている稀有なプラグインです。他に良さげなcolorschemeがある場合はぜひ教えてください🙏🏻

### その他

- [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons): nerdfont!
- [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter): なんだかんだあると便利。依存してるプラグインも多い

## UI系

### [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify)

```lua
use {
	'rcarriga/nvim-notify',
	-- noice.nvimが正常に使える場合、config部分は要りません
	config = function()
		vim.notify = require 'notify'
		vim.notify_once = require 'notify'
	end,
}
```

neovimの通知をmacのシステム通知みたくできます

### [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim)

```lua
use {
	'folke/todo-comments.nvim',
	config = function()
		require('todo-comments').setup {
			keywords = {
				FIX = { alt = { 'e' } }, -- e: `e` stands for error
				TODO = {
					color = 'hint',
					alt = { 'q' }, -- q: `q` stands for question
				},
				HACK = {
					color = 'doc',
					alt = { 'a' }, -- a: `a` stands for attention
				},
				WARN = { alt = { 'x' } }, -- x: `x` is abbreviation of `XXX`
				PERF = {
					color = 'cmt',
					alt = { 'p' }, -- p: `p` stands for performance
				},
				NOTE = {
					color = 'info',
					alt = { 'd' }, -- d: `d` stands for description
				},
				TEST = { alt = { 't', 'PASS', 'FAIL' } }, -- t: `t` stands for test
			},
			colors = {
				cmt = { 'Comment' },
				doc = { 'SpecialComment' },
				todo = { 'Todo' },
			},
		}
	end,
}
```

[vimはデフォルトでコメント内で特定のキーワードを特別なハイライトをしてくれます](https://zenn.dev/link/comments/8f0e04297be123)。このプラグインの提供する機能も基本的に同じですが、builtinは若干物足りないのと、こっちの方がカスタマイズしやすいのでこっちを使っています。`require('todo-comments').jump_prev`と`next()`でtodo-comment間を行き来できます。自分はこれを`<tab>` `<s-tab>`に割り当てています。便利。

```lua
map('n', '<space>c', '<cmd>TodoTelescope<cr>')
```
また、`<space>c`で現在のバッファのtodo-commentたちを一覧できる様にしています。（要telescope)

個人的にかなりおすすめのプラグインです。

### [folke/noice.nvim](https://github.com/folke/noice.nvim)

```lua
use {
	'folke/noice.nvim',
	config = function()
		require('noice').setup {
			presets = {
				bottom_search = true,
			},
		}
	end,
}
```

>[`オプション`](#オプション)のところでも述べたようにこのプラグインは現在(2023/1/6)neovim側のバグが原因でうまく動作しません。

このプラグインを使うとneovimのUIをいい感じに乗っ取ってくれます。また、個人的に重宝しているのは、[notify](https://github.com/rcarriga/nvim-notify)と連携することでvimから送られる通知の履歴を簡単に見返せる機能です。

更に[telescope](https://github.com/nvim-telescope/telescope.nvim)と連携することで、通知の履歴をfuzzy_searchできます。ネ申
自分は`map('n', '<space>n', require('telescope').extensions.notify.notify)
`とマッピングすることで`<space>n`でいつでも呼び出せる様にしています。

## 入力補助系

### [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs)

```lua
use {
	'windwp/nvim-autopairs',
	config = function()
		require('nvim-autopairs').setup {
			map_c_h = true,
		}
	end,
}
```

みんな何かしら入れてる勝手にカッコ閉じてくれるタイプのやつですね。builtinのlsp使っている人は大体これ（偏見）

## FuzzyFinder系

FuzzyFinder系というよりtelescope系

[telescope](https://github.com/nvim-telescope/telescope.nvim)の存在でvimからneovimに移行する決心がつきました。このプラグインを使ったことない方にはぜひ試して欲しいですし、他のff系プラグインを使っている方にも一度は触れて欲しいです。エコシステムが豊かでneovimとの相性も良いのでできることが一気に広がります。

### [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

```lua
use {
	'nvim-telescope/telescope.nvim',
	tag = '0.1.0',
	config = function()
		require('telescope').setup {
			extensions = {
				file_browser = {
					hidden = true,
					hide_parent_dir = true,
				},
			},
		}
		require('telescope').load_extension 'frecency'
		require('telescope').load_extension 'file_browser'
	end,
}
```

これがないと始まらない。neovimのプラグインで一番おすすめです。
↓はbuiltinのpickerでよく使うもの

```lua
map('n', 't', require('telescope.builtin').builtin)
map('n', '<space>o', require('telescope.builtin').lsp_document_symbols)
map('n', '<space>d', require('telescope.builtin').diagnostics)
map('n', '<space>b', require('telescope.builtin').buffers)
```

### [nvim-telescope/telescope-frecency.nvim](https://github.com/nvim-telescope/telescope-frecency.nvim)

```lua
use 'nvim-telescope/telescope-frecency.nvim'
-- まっぴんぐ
map('n', '<space>f', require('telescope').extensions.frecency.frecency)
```

builtinのpickerになってないのが不思議。

### [nvim-telescope/telescope-file-browser.nvim](https://github.com/nvim-telescope/telescope-file-browser.nvim)

```lua
use 'nvim-telescope/telescope-file-browser.nvim'
--まっぴんぐ
map('n', <space>e',require('telescope').extensions.file_browser.file_browser)
```

ファイラー系プラグインって地味にたくさんありますが、telescopeのいつものUIでブラウズするのがなんだかんだ一番楽なのでこれを使っています。似た様な理由でvim時代は[coc-explorer](https://github.com/weirongxu/coc-explorer)を使っていました。マッピングが`<space>e`になってるのはその名残です。（***e***xplorer)

## LSP系

今やすっかり人権装備となったlsp

### [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

```lua
use {
	'neovim/nvim-lspconfig',
	config = function()
		local capabilities = require('cmp_nvim_lsp').default_capabilities()
                                                                          
		-- d: rust_analyzer
		require('lspconfig').rust_analyzer.setup {
			capabilities = capabilities,
			settings = {
				['rust-analyzer'] = {
					hover = {
						actions = {
							reference = {
								enable = true,
							},
						},
					},
					inlayHints = {
						closingBraceHints = {
							minLines = 0,
						},
						lifetimeElisionHints = {
							enable = 'always',
							useParameterNames = true,
						},
						maxLength = 0,
						typeHints = {
							hideNamedConstructor = false,
						},
					},
					lens = {
						implementations = {
							enable = false,
						},
					},
					rustfmt = {
						rangeFormatting = {
							enable = true,
						},
					},
					semanticHighlighting = {
						operator = {
							specialization = {
								enable = true,
							},
						},
					},
					typing = {
						autoClosingAngleBrackets = {
							enable = true,
						},
					},
					workspace = {
						symbol = {
							search = {
								kind = 'all_symbols',
							},
						},
					},
				},
			},
		}
                                                                          
		-- d: lua
		require('lspconfig').sumneko_lua.setup {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						version = 'LuaJIT',
					},
					diagnostics = {
						globals = { 'vim' },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file('', true),
						checkThirdParty = false,
					},
					telemetry = {
						enable = false,
					},
				},
			},
		}
                                                                          
		-- d: clangd
		require('lspconfig').clangd.setup {
			capabilities = capabilities,
		}
	end,
}
```

InlayHintやSemanticTokenなどの機能は未実装なもののtelescopeとの兼ね合いでbuiltinを使っています。`rust-analyzer`の設定は`coc`時代のものです。それからいじってないので古臭いことやってるかもしれません。

luaの設定のこの部分
```lua
diagnostics = {
	globals = { 'vim' },
},
```

を取り除くとlspが`vim.opt`などの`vim`をグローバルな変数だと理解してくれずにエラーを出す様になります。

### [glepnir/lspsaga.nvim](https://github.com/glepnir/lspsaga.nvim)

```lua
use {
	'glepnir/lspsaga.nvim',
	branch = 'main',
	config = function()
		require('lspsaga').init_lsp_saga {
			saga_winblend = 20,
			max_preview_lines = 10,
			code_action_lightbulb = {
				enable = false,
			},
			finder_action_keys = {
				open = '<cr>',
				vsplit = '<c-v>',
				split = '<c-x>',
			},
			definition_action_keys = {
				edit = '<cr>',
				vsplit = '<c-v>',
				split = '<c-x>',
				tabe = 't',
			},
		}
	end,
}
--まっぴんぐ
map({ 'n', 'v' }, '<space>a', '<cmd>Lspsaga code_action<cr>')
map('n', '<space>j', '<cmd>Lspsaga lsp_finder<cr>') --`j` stands for jump
map('n', '<space>r', '<cmd>Lspsaga rename<cr>')
map('n', '<space>h', '<cmd>Lspsaga hover_doc<cr>')
map('n', '<c-j>', '<cmd>Lspsaga diagnostic_jump_next<cr>')
map('n', '<c-k>', '<cmd>Lspsaga diagnostic_jump_prev<cr>')
```

`<space>j`で`Lspsaga lsp_finder`を呼び出すために入れています。その他のマッピングはbuiltinのapiを用いて
```lua
map({ 'n', 'v' }, '<space>a', vim.lsp.code_action)
map('n', '<space>r', vim.lsp.buf.rename)
map('n', '<space>h', vim.lsp.buf.hover)
map('n', '<c-j>', vim.diagnostic.goto_next)
map('n', '<c-k>', vim.diagnostic.goto_prev)
```
再現できます。Lspsagaを使った方がUIが見やすいです。

### その他

- [mason.nvim](https://github.com/williamboman/mason.nvim): プラグインマネージャヤーみたいなやつ
- [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim): プラグインマネージャヤーみたいなやつ2
- [null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim): lspと同じ機能を提供する外部ツールをlspとして扱うことができるものです

## 補完系

### [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

```lua
use {
	'hrsh7th/nvim-cmp',
	config = function()
		local luasnip = require 'luasnip'
		local cmp = require 'cmp'
		cmp.setup {
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			mapping = cmp.mapping.preset.insert {
				['<a-k>'] = cmp.mapping.scroll_docs(-10),
				['<a-j>'] = cmp.mapping.scroll_docs(10),
				['<c-c>'] = cmp.mapping.abort(),
				['<tab>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.confirm {
							behavior = cmp.ConfirmBehavior.Insert,
							select = true,
						}
					else
						fallback()
					end
				end, { 'i', 's', 'c' }),
				['<s-tab>'] = cmp.mapping(function(fallback)
					if luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { 'i', 's', 'c' }),
				['<c-n>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					else
						fallback()
					end
				end, { 'i', 's', 'c' }),
				['<c-p>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end, { 'i', 's', 'c' }),
			},
			sources = {
				{ name = 'luasnip' },
				{ name = 'nvim_lsp' },
				{ name = 'nvim_lua' },
				{ name = 'nvim_lsp_signature_help' },
				{ name = 'buffer' },
			},
		}
                                                            
		cmp.setup.cmdline('/', {
			sources = {
				{ name = 'buffer' },
			},
		})
                                                            
		cmp.setup.cmdline(':', {
			sources = {
				{ name = 'path' },
				{ name = 'cmdline' },
				{ name = 'buffer' },
			},
		})
	end,
}
```

~~lspconfigでおすすめされてたので脳死で使ってます~~拡張性が高そうなので使っています。

`cmp.setup`に渡されるtableの`sources`の部分では複数の補完ソースを指定できますが、この時、ソースの並びがそのまま補完の優先度になります。自分の場合

```lua
sources = {
	{ name = 'luasnip' },--priority 1
	{ name = 'nvim_lsp' },--priority 2
	{ name = 'nvim_lua' },--priority 3
	{ name = 'nvim_lsp_signature_help' },--priority 4
	{ name = 'buffer' },--priority 5
},
```

となっています

### その他

- [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp): lspが送ってくる補完ソース
- [cmp-nvim-lua](https://github.com/hrsh7th/cmp-nvim-lua): init.luaを書く時とかに重宝します
- [cmp-nvim-lsp-signature-help](https://github.com/hrsh7th/cmp-nvim-lsp-signature-help): 関数の引数の補完がいい感じになります
- [cmp-buffer](https://github.com/hrsh7th/cmp-buffer): 現在のバッファの単語を補完に追加してくれます
- [cmp-path](https://github.com/hrsh7th/cmp-path): cmdline等でpathを入力したい場面で補完を提供してくれます
- [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline): vimのコマンドなどを補完してくれます。builtinの補完との違いで一番大きいと感じるのはfuzzy_searchできる点です。地味に革命
- [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip): ~~なんか必要らしい~~lspが送ってくるコードのスニペットに対応するためにスニペットプラグインが必要らしく、これはスニペットプラグインと補完プラグインを繋ぐ役割を持っている。らしいです
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip): 高機能なスニペットプラグインだそうです。全然使いこなせていない..
