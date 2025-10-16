local class = require 'llae.class'


local function serialize_tags(tags)
    if not tags then
        return ''
    end
    local tagsv = {}
    for k, v in pairs(tags) do
        table.insert(tagsv, string.format("%s=%s", k, tostring(v)))
    end
    table.sort(tagsv)
    return table.concat(tagsv, ',')
end

---@class prometheus.metric
---@field _key string
---@field _value number?
---@field new fun(key: string, value: number): prometheus.metric
local metric = class(nil, 'prometheus.metric')
function metric:_init(key, value)
    self._key = key
    self._value = value or 0
end

function metric:get_value()
    return self._value
end

function metric:set_value(value)
    self._value = value
end

function metric:serialize(lines,name)
    local enc_tags = ''
    if self._key ~= '' then
        enc_tags = '{' .. self._key .. '}'
    end
    table.insert(lines, string.format("%s%s %s", name, enc_tags, tostring(self._value)))
end

---@class prometheus.collector
---@field _name string
---@field _help string
---@field _kind string
local collector = class(nil, 'prometheus.collector')

function collector:_init(name, help, kind)
    self._name = name
    self._help = help
    self._kind = kind
    self._values = {}
    self._metrics = {}
end

function collector:get_metric(tags)
    local key = serialize_tags(tags)
    local m = self._metrics[key]
    if not m then
        m = metric.new(key)
        self._metrics[key] = m
        table.insert(self._values, m)
    end
    return m
end

---@param lines string[]
function collector:serialize(lines)
    table.insert(lines, string.format("# HELP %s %s", self._name, self._help))
    table.insert(lines, string.format("# TYPE %s %s", self._name, self._kind))
    for _, value in ipairs(self._values) do
        value:serialize(lines, self._name)
    end
end


---@class prometheus.metrics
---@field _collectors prometheus.collector[]
local metrics = class(nil, 'prometheus.metrics')

function metrics:_init()
    self._collectors = {}
end

---@param c prometheus.collector
function metrics:add_collector(c)
    table.insert(self._collectors, c)
end

function metrics:serialize()
    local response = {}
    for _, metric in ipairs(self._collectors) do
        metric:serialize(response)
    end
    return table.concat(response, '\n')
end

---@class prometheus.counter : prometheus.collector
---@field baseclass prometheus.collector
local counter = class(collector, 'prometheus.counter')

function counter:_init(name, help)
    counter.baseclass._init(self, name, help, 'counter')
end

function counter:inc(value, tags)
    if not value then
        value = 1
    end
    local m = self:get_metric(tags)
    m:set_value(m:get_value() + value)
end


function metrics:add_counter(name, help)
    local c = counter.new(name, help)
    self:add_collector(c)
    return c
end


---@class prometheus.gauge : prometheus.collector
---@field baseclass prometheus.collector
local gauge = class(collector, 'prometheus.gauge')
function gauge:_init(name, help)
    gauge.baseclass._init(self, name, help, 'gauge')
end

function gauge:set(value, tags)
    local m = self:get_metric(tags)
    m:set_value(value)
end


function metrics:add_gauge(name, help)
    local g = gauge.new(name, help)
    self:add_collector(g)
    return g
end

return metrics