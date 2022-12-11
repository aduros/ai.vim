vim.api.nvim_create_user_command("AI", function (args)
    require("_ai/commands").ai(args)
end, {
    range = true,
    nargs = "*",
})

vim.api.nvim_set_var("ai_sign_text", "🤖")
vim.api.nvim_set_var("ai_context_before", 20)
vim.api.nvim_set_var("ai_context_after", 20)

if not vim.g.ai_no_mappings then
    vim.api.nvim_set_keymap("n", "<C-a>", ":AI ", { noremap = true })
    vim.api.nvim_set_keymap("v", "<C-a>", ":AI ", { noremap = true })
    vim.api.nvim_set_keymap("i", "<C-a>", "<Esc>:AI<CR>a", { noremap = true })
end
