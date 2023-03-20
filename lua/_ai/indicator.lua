local M = {}

local config = require("_ai/config")

---@class Indicator
---@field buffer number
---@field extmark_id number

local ns_id = vim.api.nvim_create_namespace("")

local function get_default_extmark_opts ()
    local extmark_opts = {
        hl_group = "AIHighlight",
        -- right_gravity = false,
        -- end_right_gravity = true,
    }

    if config.indicator_style ~= "none" then
        extmark_opts.sign_text = config.indicator_text
        extmark_opts.sign_hl_group = "AIIndicator"
    end

    return extmark_opts
end

-- Creates a new indicator.
---@param buffer number
---@param start_row number
---@param start_col number
---@param end_row number
---@param end_col number
---@return Indicator
function M.create (buffer, start_row, start_col, end_row, end_col)
    local extmark_opts = get_default_extmark_opts()

    if end_row ~= start_row or end_col ~= start_col then
        extmark_opts.end_row = end_row
        extmark_opts.end_col = end_col
    end

    local extmark_id = vim.api.nvim_buf_set_extmark(buffer, ns_id, start_row, start_col, extmark_opts)

    return {
        buffer = buffer,
        extmark_id = extmark_id,
    }
end

-- Set the preview virtual text to show at this indicator.
---@param indicator Indicator
---@param text string
function M.set_preview_text (indicator, text)
    local extmark = vim.api.nvim_buf_get_extmark_by_id(indicator.buffer, ns_id, indicator.extmark_id, { details = true })
    local start_row = extmark[1]
    local start_col = extmark[2]

    if extmark[3].end_row or extmark[3].end_col then
        return -- We don't support preview text on indicators over a range
    end

    local extmark_opts = get_default_extmark_opts()
    extmark_opts.id = indicator.extmark_id
    extmark_opts.virt_text_pos = "overlay"

    local lines = vim.split(text, "\n")
    extmark_opts.virt_text = {{lines[1], "Comment"}}

    if #lines > 1 then
        extmark_opts.virt_lines = vim.tbl_map(function (line) return {{line, "Comment"}} end, vim.list_slice(lines, 2))
    end

    vim.api.nvim_buf_set_extmark(indicator.buffer, ns_id, start_row, start_col, extmark_opts)
end

-- Sets the in-buffer text at this indicator.
---@param indicator Indicator
---@param text string
function M.set_buffer_text (indicator, text)
    local extmark = vim.api.nvim_buf_get_extmark_by_id(indicator.buffer, ns_id, indicator.extmark_id, { details = true })
    local start_row = extmark[1]
    local start_col = extmark[2]

    local end_row = extmark[3].end_row
    if not end_row then
        end_row = start_row
    end

    local end_col = extmark[3].end_col
    if not end_col then
        end_col = start_col
    end

    local lines = vim.split(text, "\n")
    vim.api.nvim_buf_set_text(indicator.buffer, start_row, start_col, end_row, end_col, lines)
end

---@param indicator Indicator
function M.finish (indicator)
    vim.api.nvim_buf_del_extmark(indicator.buffer, ns_id, indicator.extmark_id)
end

return M
