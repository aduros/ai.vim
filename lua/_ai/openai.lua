local M = {}

local config = require("_ai/config")

local function request (endpoint, body, on_data, on_complete)
    local api_key = os.getenv("OPENAI_API_KEY")
    if not api_key then
        on_complete("$OPENAI_API_KEY environment variable must be set")
        return
    end
    local curl = {
        "curl",
        "--silent",
        "--show-error",
        "--no-buffer",
        "--max-time", config.timeout,
        "-L",
        "-H", "Authorization: Bearer " .. api_key,
        "-H", "Content-Type: application/json",
        "-X", "POST",
        "-d", vim.json.encode(body),
        "https://api.openai.com/v1/" .. endpoint,
    }
    local json_str = vim.fn.system(curl)
    local json = vim.json.decode(json_str)
    if json.error then
        on_complete(json.error.message)
    else
        on_data(json)
    end
end

---@param body table
---@param on_data fun(data: unknown): nil
---@param on_complete fun(err: string?): nil
function M.completions (body, on_data, on_complete)
    body = vim.tbl_extend("keep", body, {
        model = config.completions_model,
        max_tokens = 2048,
        temperature = config.temperature,
        stream = true,
    })
    request("completions", body, on_data, on_complete)
end

---@param body table
---@param on_data fun(data: unknown): nil
---@param on_complete fun(err: string?): nil
function M.edits (body, on_data, on_complete)
    body = vim.tbl_extend("keep", body, {
        model = config.edits_model,
        temperature = config.temperature,
    })
    request("edits", body, on_data, on_complete)
end

return M
