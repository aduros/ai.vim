local M = {}

function exec (cmd, args, on_stdout)
    local chunks = {}
    local function on_read (err, data)
        if data then
            table.insert(chunks, data)
        end
    end

    local stdout = vim.loop.new_pipe()
    local handle

    handle = vim.loop.spawn(cmd, {
        args = args,
        stdio = {nil, stdout, nil},
    }, function (code, signal)
        stdout:close()
        handle:close()

        vim.schedule(function ()
            local output = table.concat(chunks, "")
            on_stdout(output)
        end)
    end)

    stdout:read_start(on_read)
end

function M.call (endpoint, body, on_result)
    local api_key = os.getenv("OPENAI_API_KEY")
    assert(api_key ~= nil, "$OPENAI_API_KEY environment variable must be set")

    local curl_args = {
        "-L", "https://api.openai.com/v1/" .. endpoint,
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", vim.json.encode(body),
    }

    -- print("Calling API:", endpoint, vim.json.encode(body))
    exec("curl", curl_args, function (output)
        local json = vim.json.decode(output)
        if json.error then
            print("API error:", json.error.message)
        else
            on_result(json)
        end
    end)
end

return M
