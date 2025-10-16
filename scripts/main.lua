local async = require 'llae.async'
local log = require 'llae.log'
local metrics = require 'prometheus.metrics'
local server = require 'prometheus.server'


async.run(function()
    local m = metrics.new()

    local c = m:add_counter('test_counter', 'Test counter')
    c:inc(1, {type = 'test'})
    c:inc(2, {type = 'test'})
    c:inc(3, {type = 'test1'})
    c:inc(4, {type = 'test'})
    c:inc(5, {type = 'test2'})
    c:inc(6, {type = 'test'})
    local g = m:add_gauge('test_gauge', 'Test gauge')
    g:set(1, {type = 'test'})
    g:set(2, {type = 'test'})
    g:set(3, {type = 'test2'})
    g:set(4, {type = 'test'})
    g:set(5, {type = 'test3'})
    g:set(6, {type = 'test'})


    local serv = server.new{
        host = '127.0.0.1',
        port = 9090,
        path = '/metrics',
    }

    async.run(function()
        while true do
            c:inc(1)
            async.pause(1000)
        end
    end)

    serv:add_metrics(m)
    log.info(string.format('Server started on http://%s:%d%s', serv:get_host(), serv:get_port(), serv:get_path()))

    assert(serv:start())
end)