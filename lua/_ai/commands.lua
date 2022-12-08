local M = {}

local openai = require("_ai/openai")

function M.ai (args)
    local prompt = args.args
    local start_line = args.line1
    local end_line = args.line2
    local range_count = args.range

    local buf = 0

    local function on_result (result)
        local text = result.choices[1].text
        local lines = {}
        for line in text:gmatch("[^\n]+") do
            table.insert(lines, line)
        end

        if range_count == 0 then
            vim.api.nvim_buf_set_lines(buf, start_line, end_line, true, lines)
        else
            vim.api.nvim_buf_set_lines(buf, start_line-1, end_line, true, lines)
        end
    end

    if range_count == 0 then
        if prompt == nil or prompt == "" then
            -- Insert some text generated using surrounding context
            local line_count = 20
            local prefix = table.concat(vim.api.nvim_buf_get_lines(buf, math.max(0, start_line-line_count), start_line, true), "\n")
            local suffix = table.concat(vim.api.nvim_buf_get_lines(buf, start_line, start_line+line_count, false), "\n")

            openai.call("completions", {
                model = "text-davinci-003",
                prompt = prefix,
                suffix = suffix,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        else
            -- Insert some text generated using the given prompt
            openai.call("completions", {
                model = "text-davinci-003",
                prompt = prompt,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        end
    else
        local text = table.concat(vim.api.nvim_buf_get_lines(buf, start_line-1, end_line, true), "\n")
        if prompt == nil or prompt == "" then
            -- Replace the selected text, also using it as a prompt
            openai.call("completions", {
                model = "text-davinci-003",
                prompt = text,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        else
            -- Edit the selected text using the given prompt as instruction
            openai.call("edits", {
                model = "code-davinci-edit-001",
                input = text,
                instruction = prompt,
                temperature = 0,
            }, on_result)
        end
    end
end

return M
