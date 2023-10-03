local M = {}

local openai = require("_ai/openai")
local config = require("_ai/config")
local indicator = require("_ai/indicator")

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
        local line = vim.fn.getline(end_pos[1])
        if line == "" then
            end_col = 0
        else
            end_col = vim.fn.byteidx(line, vim.fn.charcol("'>"))
        end

    else
        -- Use the cursor position
        local start_pos = vim.api.nvim_win_get_cursor(0)
        start_row = start_pos[1] - 1
        local line = vim.fn.getline(start_pos[1])
        if line == "" then
            start_col = 0
        else
            start_col = vim.fn.byteidx(line, vim.fn.charcol("."))
        end
        end_row = start_row
        end_col = start_col
    end

    local start_line_length = vim.api.nvim_buf_get_lines(buffer, start_row, start_row+1, true)[1]:len()
    start_col = math.min(start_col, start_line_length)

    local end_line_length = vim.api.nvim_buf_get_lines(buffer, end_row, end_row+1, true)[1]:len()
    end_col = math.min(end_col, end_line_length)

    local indicator_obj = indicator.create(buffer, start_row, start_col, end_row, end_col)
    local accumulated_text = ""

    local function on_data (data)
        accumulated_text = accumulated_text .. data.choices[1].text
        indicator.set_preview_text(indicator_obj, accumulated_text)
    end

    local function on_complete (err)
        if err then
            vim.api.nvim_err_writeln("ai.vim: " .. err)
        elseif #accumulated_text > 0 then
            indicator.set_buffer_text(indicator_obj, accumulated_text)
        end
        indicator.finish(indicator_obj)
    end

    if visual_mode then
        local selected_text = table.concat(vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col, {}), "\n")
        if prompt == "" then
            -- Replace the selected text, also using it as a prompt
            openai.completions({
                prompt = selected_text,
            }, on_data, on_complete)
        else
            -- Edit selected text
            openai.edits({
                input = selected_text,
                instruction = prompt,
            }, on_data, on_complete)
        end
    else
        if prompt == "" then
            -- Insert some text generated using surrounding context
            local prefix = table.concat(vim.api.nvim_buf_get_text(buffer,
                math.max(0, start_row-config.context_before), 0, start_row, start_col, {}), "\n")

            local line_count = vim.api.nvim_buf_line_count(buffer)
            local suffix = table.concat(vim.api.nvim_buf_get_text(buffer,
                end_row, end_col, math.min(end_row+config.context_after, line_count-1), 99999999, {}), "\n")

            openai.completions({
                prompt = prefix,
                suffix = suffix,
            }, on_data, on_complete)
        else
            -- Insert some text generated using the given prompt
            openai.completions({
                prompt = prompt,
            }, on_data, on_complete)
        end
    end
end

return M
