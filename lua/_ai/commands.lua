local M = {}

local openai = require("_ai/openai")
local config = require('_ai/config')

local ns_id = vim.api.nvim_create_namespace("")

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

    local extmark_opts = {
        end_row = end_row,
        end_col = end_col,
        hl_group = "AIHighlight",
    }
    if config.indicator_style == "sign" then
        extmark_opts.sign_text = config.indicator_text
        extmark_opts.sign_hl_group = "AIIndicator"
    elseif config.indicator_style == "virtual_text" then
        extmark_opts.virt_text = {{ config.indicator_text, "AIIndicator" }}
    elseif config.indicator_style ~= "none" then
        vim.api.nvim_err_writeln("ai.vim: Unsupported value for g:ai_indicator_style")
        return
    end

    local mark_id = vim.api.nvim_buf_set_extmark(buffer, ns_id, start_row, start_col, extmark_opts)

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
            for line in text:gmatch("([^\n]*)\n?") do
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
        if prompt == "" then
            -- Replace the selected text, also using it as a prompt
            openai.call("completions", {
                model = config.completions_model,
                prompt = selected_text,
                max_tokens = 2048,
                temperature = config.temperature,
            }, on_result)
        else
            -- Edit selected text
            openai.call("edits", {
                model = config.edits_model,
                input = selected_text,
                instruction = prompt,
                temperature = config.temperature,
            }, on_result)
        end
    else
        if prompt == "" then
            -- Insert some text generated using surrounding context
            local prefix = table.concat(vim.api.nvim_buf_get_text(buffer,
                math.max(0, start_row-config.context_before), 0, start_row, start_col, {}), "\n")

            local line_count = vim.api.nvim_buf_line_count(buffer)
            local suffix = table.concat(vim.api.nvim_buf_get_text(buffer,
                end_row, end_col, math.min(end_row+config.context_after, line_count-1), 99999999, {}), "\n")

            openai.call("completions", {
                model = config.completions_model,
                prompt = prefix,
                suffix = suffix,
                max_tokens = 2048,
                temperature = config.temperature,
            }, on_result)
        else
            -- Insert some text generated using the given prompt
            openai.call("completions", {
                model = config.completions_model,
                prompt = prompt,
                max_tokens = 2048,
                temperature = config.temperature,
            }, on_result)
        end
    end
end

return M
