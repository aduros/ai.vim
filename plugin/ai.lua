vim.api.nvim_create_user_command("AI", function (args)
    require("_ai/commands").ai(args)
end, {
    range = true,
    nargs = "*",
})

if not vim.g.ai_no_mappings then
    vim.api.nvim_set_keymap("n", "<C-a>", ":AI ", { noremap = true })
    vim.api.nvim_set_keymap("v", "<C-a>", ":AI ", { noremap = true })
    vim.api.nvim_set_keymap("i", "<C-a>", "<Esc>:AI<CR>a", { noremap = true })
end
