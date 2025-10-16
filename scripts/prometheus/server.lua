local class = require 'llae.class'
local http = require 'net.http'

---@class prometheus.server
---@field _host string
---@field _port number
---@field _path string
---@field _server net.http.server
---@field _metrics prometheus.metrics[]
local server = class(nil, 'prometheus.server')

function server:_init(opts)
    self._host = opts and opts.host or '127.0.0.1'
    self._port = opts and opts.port or 9090
    self._path = opts and opts.path or '/metrics'
    self._server = http.server.new(function(req, res)
        self:handle(req, res)
    end)
    self._metrics = {}
end

function server:get_host()
    return self._host
end

function server:get_port()
    return self._port
end

function server:get_path()
    return self._path
end

---@param metrics prometheus.metrics[]
function server:add_metrics(metrics)
    table.insert(self._metrics, metrics)
end

function server:handle(req, res)
    if req:get_path() == self._path then
        res:set_header('Content-Type', 'text/plain; charset=utf8')
        res:write(self:collect_metrics_response())
        res:finish()
    else
        res:status(404)
        res:write('Not found')
        res:finish()
    end
end

function server:start()
    local res, err = self._server:listen(self._port, self._host)
    return res, err
end

function server:stop()
    self._server:close()
end

function server:collect_metrics_response()
    local response = {}
    for _, metric in ipairs(self._metrics) do
        table.insert(response, metric:serialize())
    end
    return table.concat(response, '\n') .. '\n'
end

return server