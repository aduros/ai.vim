local M = {}

local config = require('_ai/config')

---@param cmd string
---@param args string[]
---@param on_result fun(err: string?, output: string?)
local function exec (cmd, args, on_result)
    local stdout = vim.loop.new_pipe()
    local stdout_chunks = {}
    local function on_stdout_read (_, data)
        if data then
            table.insert(stdout_chunks, data)
        end
    end

    local stderr = vim.loop.new_pipe()
    local stderr_chunks = {}
    local function on_stderr_read (_, data)
        if data then
            table.insert(stderr_chunks, data)
        end
    end

    -- print(cmd, vim.inspect(args))

    local handle

    handle, error = vim.loop.spawn(cmd, {
        args = args,
        stdio = {nil, stdout, stderr},
    }, function (code)
        stdout:close()
        stderr:close()
        handle:close()

        vim.schedule(function ()
            if code ~= 0 then
                on_result(vim.trim(table.concat(stderr_chunks, "")))
            else
                on_result(nil, vim.trim(table.concat(stdout_chunks, "")))
            end
        end)
    end)

    if not handle then
        on_result(cmd .. " could not be started: " .. error)
    else
        stdout:read_start(on_stdout_read)
        stderr:read_start(on_stderr_read)
    end
end

---@param endpoint string
---@param body table
---@param on_result fun(err: string?, output: unknown?): nil
function M.call (endpoint, body, on_result)
    local api_key = os.getenv("OPENAI_API_KEY")
    if not api_key then
        on_result("$OPENAI_API_KEY environment variable must be set")
        return
    end

    local curl_args = {
        "-X", "POST", "--silent", "--show-error",
        "-L", "https://api.openai.com/v1/" .. endpoint,
        "-m", config.timeout,
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", vim.json.encode(body),
    }

    exec("curl", curl_args, function (err, output)
        if err then
            on_result(err)
        else
            local json = vim.json.decode(output)
            if json.error then
                on_result(json.error.message)
            else
                on_result(nil, json)
            end
        end
    end)
end

return M
