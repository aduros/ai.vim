# 🤖 ai.vim

A simple Neovim plugin for generating and editing text using OpenAI and GPT.

> Status: pre-alpha

## Features

- Complete text in insert mode.
- Generate new text using a prompt.
- Select and edit existing text in-place.
- Easy to use interface. Just hit `<Ctrl-A>` or run `:AI <prompt>`.
- Not just for source code!

# Installing

For vim-plug, add this to your init.vim:

`Plug 'aduros/ai.vim'`

Make sure you have an environment variable called `$OPENAI_API_KEY` which you can [generate
here](https://beta.openai.com/account/api-keys). You'll also need `curl` installed.

## Bugs, TODOs

- Needs better feedback while a request is loading.
- Error handling isn't great.
- Support operating on partial lines, and custom motions?
- Documentation.

PRs are welcome!

## Examples

### Completion

```
function capitalize (str: string): string {<Ctrl-A>
```

```
// Calculate hashcode from a string<Ctrl-A>

```
List of planets in Star Wars:<Ctrl-A>
```

```
Here are some ideas for slogans for the new petshop:<Ctrl-A>
```

### Generating

```
:AI write an email to HR asking about vacation policy
```

### Editing

```
1. Toronto
2. London
3. Honolulu
4. Miami
5. Boston

(Visual select the list)
:AI sort cities by their distance to New York
```

```
Today I rote a plugin that do AI things.

(Visual select line)
:AI fix grammar and spelling
```

```
body {
    color: red;
    background: green;
}

(Visual select CSS code)
:AI convert colors to hex
```
