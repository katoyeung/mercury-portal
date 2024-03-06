local function flush_logs(premature)
    if premature then return end

    local log_buffer = ngx.shared.log_buffer
    local log_file_path = "/path/to/your/logs.txt" -- Update this path

    while true do
        local log_msg, err = log_buffer:lpop("logs")
        if log_msg then
            -- Example: Write log message to a file
            local file, err = io.open(log_file_path, "a")
            if not file then
                ngx.log(ngx.ERR, "Failed to open log file: ", err)
                return
            end

            file:write(log_msg .. "\n")
            file:close()
        else
            break -- No more logs to flush
        end
    end
end

-- Initialize the background worker
local ok, err = ngx.timer.every(5, flush_logs) -- Flush every 5 seconds
if not ok then
    ngx.log(ngx.ERR, "Failed to create log flush timer: ", err)
end
