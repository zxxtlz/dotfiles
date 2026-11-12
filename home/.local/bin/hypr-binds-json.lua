-- Load the Lua Hyprland binds file with a recorder instead of a compositor and
-- print every hl.bind it declares as JSON. Used by rofi-shortcuts so the menu
-- always reflects the real config, including binds generated inside loops.
local home = os.getenv("HOME") or ""
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local variables = os.getenv("HYPR_VARIABLES") or (config .. "/hypr/config/variables.lua")
local binds = os.getenv("HYPR_BINDS") or (config .. "/hypr/config/binds.lua")

local records = {}

-- Every hl.dsp.<path>(...) call becomes a small record. Nested paths are built
-- lazily, so window.move({...}) and workspace.toggle_special() both work.
local function make_proxy(path)
    return setmetatable({}, {
        __index = function(_, key)
            return make_proxy(path == "" and key or (path .. "." .. key))
        end,
        __call = function(_, ...)
            local args = table.pack(...)
            local n = args.n
            while n > 0 and args[n] == nil do n = n - 1 end
            local out = {}
            for i = 1, n do out[i] = args[i] end
            return { __kind = "dsp", path = path, args = out }
        end,
    })
end

local function record(key, action, opts)
    records[#records + 1] = { key = tostring(key), action = action, opts = opts }
end

hl = setmetatable({}, {
    __index = function(_, key)
        if key == "bind" then return record end
        if key == "dsp" then return make_proxy("") end
        if key == "get_config" then return function() return 1.0 end end
        if key == "config" then return function() end end
        if key == "exec_cmd" then
            return function(cmd) return { __kind = "exec", cmd = cmd } end
        end
        error("hypr-binds-json: unexpected hl." .. tostring(key))
    end,
})

local ok, err = pcall(function()
    dofile(variables)
    dofile(binds)
end)
if not ok then
    io.stderr:write("hypr-binds-json: " .. tostring(err) .. "\n")
end

local function esc(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
        :gsub("\r", "\\r"):gsub("\t", "\\t")
    return '"' .. s .. '"'
end

local function enc(v, depth)
    depth = depth or 0
    local t = type(v)
    if v == nil then return "null" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    end
    if t == "string" then return esc(v) end
    if t == "function" then return '"[function]"' end
    if t == "table" then
        if depth > 6 then return "{}" end
        local is_array = true
        local max = 0
        for k in pairs(v) do
            if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
                is_array = false
                break
            end
            if k > max then max = k end
        end
        if is_array then
            local parts = {}
            for i = 1, max do parts[#parts + 1] = enc(v[i], depth + 1) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do
            parts[#parts + 1] = esc(k) .. ":" .. enc(v[k], depth + 1)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return esc(tostring(v))
end

local out = {}
for _, r in ipairs(records) do
    local entry = { key = r.key }
    local a = r.action
    if type(a) == "function" then
        local info = debug.getinfo(a, "S")
        entry.kind = "function"
        entry.line = info and info.linedefined or 0
        entry.path = ""
        entry.args = {}
    elseif type(a) == "table" and a.__kind == "dsp" then
        entry.kind = "dsp"
        entry.path = a.path
        entry.args = a.args
    elseif type(a) == "table" and a.__kind == "exec" then
        entry.kind = "exec"
        entry.path = ""
        entry.args = { a.cmd }
    else
        entry.kind = type(a)
        entry.path = ""
        entry.args = {}
    end
    if r.opts then entry.opts = r.opts end
    out[#out + 1] = entry
end

io.write("[")
for i, e in ipairs(out) do
    if i > 1 then io.write(",") end
    io.write(enc(e))
end
io.write("]\n")
