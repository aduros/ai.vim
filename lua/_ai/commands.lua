local M = {}

local openai = require("_ai/openai")

local ns_id = vim.api.nvim_create_namespace("")

---@param name string
---@param default_value unknown
---@return unknown
local function get_var (name, default_value)
    local value = vim.g[name]
    if value == nil then
        return default_value
    end
    return value
end

---@param args { args: string, range: integer }
function M.ai (args)
    local prompt = args.args
    local visual_mode = args.range > 0

    local buffer = vim.api.nvim_get_current_buf()

    local start_row, start_col
    local end_row, end_col

    if visual_mode then
        -- Use the visual selection
        local start_pos = vim.api.nvim_buf_get_mark(buffer, "<")
        start_row = start_pos[1] - 1
        start_col = start_pos[2]

        local end_pos = vim.api.nvim_buf_get_mark(buffer, ">")
        end_row = end_pos[1] - 1
        end_col = end_pos[2] + 1

    else
        -- Use the cursor position
        local start_pos = vim.api.nvim_win_get_cursor(0)
        start_row = start_pos[1] - 1
        start_col = start_pos[2] + 1
        end_row = start_row
        end_col = start_col
    end

    local start_line_length = vim.api.nvim_buf_get_lines(buffer, start_row, start_row+1, true)[1]:len()
    start_col = math.min(start_col, start_line_length)

    local end_line_length = vim.api.nvim_buf_get_lines(buffer, end_row, end_row+1, true)[1]:len()
    end_col = math.min(end_col, end_line_length)

    local mark_id = vim.api.nvim_buf_set_extmark(buffer, ns_id, start_row, start_col, {
        end_row = end_row,
        end_col = end_col,
        hl_group = "AIHighlight",
        sign_text = get_var("ai_sign_text", "🤖"),
        sign_hl_group = "AISign",
        -- virt_text = {{"🤖", nil}},
    })

    local function on_result (err, result)
        local mark = vim.api.nvim_buf_get_extmark_by_id(buffer, ns_id, mark_id, { details = true })
        local start_row = mark[1]
        local start_col = mark[2]
        local end_row = mark[3].end_row
        local end_col = mark[3].end_col

        vim.api.nvim_buf_del_extmark(buffer, ns_id, mark_id)

        if err then
            vim.api.nvim_err_writeln("ai.vim: " .. err)
        else
            local text = result.choices[1].text
            local lines = {}
            for line in text:gmatch("[^\n]+") do
                table.insert(lines, line)
            end

            -- -- Special case: prepend \n if we're dealing with a multi-line response
            -- if #lines > 1 then
            --     table.insert(lines, 1, "")
            -- end

            vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, lines)
        end
    end

    if visual_mode then
        local selected_text = table.concat(vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col, {}), "\n")
        local model = get_var("ai_model", "text-davinci-003")
        local edit_model = get_var("ai_edit_model", "text-davinci-edit-001")

        if prompt == "" then
            -- Replace the selected text, also using it as a prompt
            openai.call("completions", {
                model = model,
                prompt = selected_text,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        else
            -- Edit selected text
            openai.call("edits", {
                model = edit_model,
                input = selected_text,
                instruction = prompt,
                temperature = 0,
            }, on_result)
        end
    else
        if prompt == "" then
            -- Insert some text generated using surrounding context
            local context_before = get_var("ai_context_before", 20)
            local prefix = table.concat(vim.api.nvim_buf_get_text(buffer,
                math.max(0, start_row-context_before), 0, start_row, start_col, {}), "\n")

            local context_after = get_var("ai_context_after", 20)
            local line_count = vim.api.nvim_buf_line_count(buffer)
            local suffix = table.concat(vim.api.nvim_buf_get_text(buffer,
                end_row, end_col, math.min(end_row+context_after, line_count-1), 99999999, {}), "\n")

            openai.call("completions", {
                model = model,
                prompt = prefix,
                suffix = suffix,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        else
            -- Insert some text generated using the given prompt
            openai.call("completions", {
                model = model,
                prompt = prompt,
                max_tokens = 2048,
                temperature = 0,
            }, on_result)
        end
    end
end

return M
