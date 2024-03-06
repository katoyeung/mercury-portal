local cjson = require "cjson"

function log()
    local log_buffer = ngx.shared.my_logs
    local log_msg = {
        remote_addr = ngx.var.remote_addr,
        time_local = ngx.var.time_local,
        request = ngx.var.request,
        status = ngx.var.status,
        body_bytes_sent = ngx.var.body_bytes_sent,
        http_referer = ngx.var.http_referer,
        http_user_agent = ngx.var.http_user_agent,
        request_time = ngx.var.request_time,
    }

    local log_json = cjson.encode(log_msg)
    local ok, err = log_buffer:rpush("logs", log_json)
    if not ok then
        ngx.log(ngx.ERR, "Failed to write log to buffer: ", err)
    end
end

-- log()
