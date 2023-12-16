# 🤖 ai.vim

A minimalist Neovim plugin for generating and editing text using OpenAI and GPT.

## Features

- Complete text in insert mode.
- Generate new text using a prompt.
- Select and edit existing text in-place.
- Streaming support for completions.
- Easy to use interface. Just hit `<Ctrl-A>` or run `:AI <prompt>`.
- Works with both source code and regular text.

## Installing

For vim-plug, add this to your init.vim:

```vim
Plug 'aduros/ai.vim'
```

Make sure you have an environment variable called `$OPENAI_API_KEY` which you can [generate
here](https://beta.openai.com/account/api-keys). You'll also need `curl` installed.

To see the full help and customization options, run `:help ai.vim`.

## Configuring

These plugin only register the `AI` command, it let full control to you over your keymaps.
Here are some recomendations

```lua
vim.api.nvim_set_keymap("n", "<C-a>", ":AI ", { noremap = true })
vim.api.nvim_set_keymap("v", "<C-a>", ":AI ", { noremap = true })
vim.api.nvim_set_keymap("i", "<C-a>", "<Esc>:AI<CR>a", { noremap = true })
```


## Tutorial

The most basic use-case is completion, by pressing `<Ctrl-A>` in insert mode.

For example:

```typescript
function capitalize (str: string): string {
    (Press <Ctrl-A> here)
}
```

Will result in:

```typescript
function capitalize (str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1);
}
```

ai.vim isn't just for programming! You can also complete regular human text:

```
Hey Joe, here are some ideas for slogans for the new petshop. Which do you like best?
1. <Ctrl-A>
```

Results in:

```
Hey Joe, here are some ideas for slogans for the new petshop. Which do you like best?
1. "Where Pets Come First!"
2. "Your Pet's Home Away From Home!"
3. "The Best Place for Your Pet!"
4. "The Pet Store That Cares!"
5. "The Pet Store That Loves Your Pet!"
```

You can also generate some text by pressing `<Ctrl-A>` in normal mode and providing a prompt. For
example:

```
:AI write a thank you email to Bigco engineering interviewer
```

Results in something like:

```
Dear [Name],

I wanted to take a moment to thank you for taking the time to interview me for the engineering
position at Bigco. I was very impressed with the company and the team, and I am excited about the
possibility of joining the team.

I appreciate the time you took to explain the role and the company's mission. I am confident that I
have the skills and experience to be a valuable asset to the team.

Once again, thank you for your time and consideration. I look forward to hearing from you soon.

Sincerely,
[Your Name]
```

Besides generating new text, you can also edit existing text using a given instruction.

```css
body {
    color: orange;
    background: green;
}
```

Visually selecting the above CSS and running `:AI convert colors to hex` results in:

```css
body {
    color: #ffa500;
    background: #008000;
}
```

Another example of text editing:

```
List of capitals:
1. Toronto
2. London
3. Honolulu
4. Miami
5. Boston
```

Visually selecting this text and running `:AI sort by population` results in:

```
List of capitals:
1. London
2. Toronto
3. Boston
4. Miami
5. Honolulu
```

You can build your own shortcuts for long and complex prompts. For example:

```vim
vnoremap <silent> <leader>f :AI fix grammar and spelling and replace slang and contractions with a formal academic writing style<CR>
```

With this custom mapping you can select text that looks like this:

```
Me fail English? That's unpossible!
```

And by pressing `<leader>f` transform it into this:

```
I failed English? That is impossible!
```

If you come up with any exciting ways to use ai.vim, please share what you find!

## Important Disclaimers

**Accuracy**: GPT is good at producing text and code that looks correct at first glance, but may be
completely wrong. Make sure you carefully proof read and test everything output by this plugin!

**Privacy**: This plugin sends text to OpenAI when generating completions and edits. Don't use it in
files containing sensitive information.
