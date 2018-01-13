-- Battery widget

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")

local timer = gears.timer or timer
local watch = awful.spawn and awful.spawn.with_line_callback

------------------------------------------
-- Private utility functions
------------------------------------------

local tolower = string.lower

local function file_exists(command)
    local f = io.open(command)
    if f then f:close() end
    return f and true or false
end

local function readfile(command)
    local file = io.open(command)
    if not file then return nil end
    local text = file:read('*all')
    file:close()
    return text
end

local function color_tags(color)
    if color
        then return '<span color="' .. color .. '">', '</span>'
        else return '', ''
    end
end

local function round(value)
    return math.floor(value + 0.5)
end

local function trim(s)
    if not s then return nil end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function substitute(template, context)
    if type(template) == "string" then
        return (template:gsub("%${([%w_]+)}", function(key)
            return tostring(context[key] or "Err!")
        end))
    else
        -- function / functor:
        return template(context)
    end
end

------------------------------------------
-- Battery widget interface
------------------------------------------

local battery_widget = {}
local sysfs_names = {
    charging = {
        present   = "present",
        state     = "status",
        rate      = "current_now",
        charge    = "charge_now",
        capacity  = "charge_full",
        design    = "charge_full_design",
        ac_state  = "AC/online",
        percent   = "capacity",
    },
    discharging = {
        present   = "present",
        state     = "status",
        rate      = "power_now",
        charge    = "energy_now",
        capacity  = "energy_full",
        design    = "energy_full_design",
        ac_state  = "AC/online",
        percent   = "capacity"
    },
}

function battery_widget:new(args)
    if args.adapter then
        return setmetatable({}, {__index = self}):init(args)
    end
    -- creates an empty container wibox, which can be added to your panel even if its empty
    local batteries = { layout = wibox.layout.fixed.horizontal }
    for i, adapter in ipairs(self:discover()) do
        local _args = setmetatable({adapter = adapter}, {__index = args})
        table.insert(batteries, self(_args).widget)
    end
    return batteries
end

function battery_widget:discover()
    local adapters = {}
    for adapter in io.popen("ls -1 /sys/class/power_supply"):lines() do
        if adapter:match("BAT") then
            table.insert(adapters, adapter)
        end
    end
    return adapters
end

function battery_widget:init(args)
    self.adapter = args.adapter or "BAT0"
    self.ac_prefix = args.ac_prefix or "AC: "
    self.battery_prefix = args.battery_prefix or "Bat: "
    self.limits = args.limits or {
        { 25, "red"   },
        { 50, "orange"},
        {100, "green" }
    }

    self.widget_text = args.widget_text or (
        "${AC_BAT}${color_on}${percent}%${color_off}")
    self.tooltip_text = args.tooltip_text or (
        "Battery ${state}${time_est}\nCapacity: ${capacity_percent}%")

    self.alert_threshold = args.alert_threshold or 5
    self.alert_timeout = args.alert_timeout or 0
    self.alert_title = args.alert_title or "Low battery !"
    self.alert_text = args.alert_text or "${AC_BAT}${time_est}"

    self.widget = wibox.widget.textbox()
    self.widget.set_align("right")
    self.widget.font = args.widget_font
    self.tooltip = awful.tooltip({objects={self.widget}})

    self.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() self:update() end),
        awful.button({ }, 3, function() self:update() end)
    ))

    self.timer = timer({ timeout = args.timeout or 10 })
    self.timer:connect_signal("timeout", function() self:update() end)
    self.timer:start()
    self:update()

    if (args.listen or args.listen == nil) and watch then
        self.listener = watch("acpi_listen", {
            stdout = function(line) self:update() end,
        })
        awesome.connect_signal("exit", function()
            awesome.kill(self.listener, awesome.unix_signal.SIGTERM)
        end)
    end

    return self
end

function battery_widget:get_state()
    local pow   = "/sys/class/power_supply/"
    local bat   = pow .. self.adapter
    local sysfs = (file_exists(bat.."/"..sysfs_names.charging.rate)
                   and sysfs_names.charging
                   or sysfs_names.discharging)

    local function read_trim(filename)
        return trim(readfile(filename))
    end

    -- If there is no battery on this machine.
    if not sysfs.state then return nil end

    -- return value
    local r = {
        state     = tolower (read_trim(bat.."/"..sysfs.state)),
        present   = tonumber(read_trim(bat.."/"..sysfs.present)),
        rate      = tonumber(read_trim(bat.."/"..sysfs.rate)),
        charge    = tonumber(read_trim(bat.."/"..sysfs.charge)),
        capacity  = tonumber(read_trim(bat.."/"..sysfs.capacity)),
        design    = tonumber(read_trim(bat.."/"..sysfs.design)),
        ac_state  = tonumber(read_trim(pow.."/"..sysfs.ac_state)),
        percent   = tonumber(read_trim(bat.."/"..sysfs.percent)),
    }

    if r.state == "unknown" then
        r.state = "charged"
    end

    if r.percent == nil and r.charge and r.capacity then
        r.percent = round(r.charge * 100 / r.capacity)
    end

    return r
end

function battery_widget:update()
    local ctx = self:get_state()

    -- If there is no battery on this machine.
    if not ctx then return nil end

    -- AC/battery prefix
    ctx.AC_BAT  = ctx.ac_state == 1 and self.ac_prefix or self.battery_prefix

    -- Colors
    ctx.color_on = ""
    ctx.color_off = ""
    if ctx.percent then
        for k, v in ipairs(self.limits) do
            if ctx.percent <= v[1] then
                ctx.color_on, ctx.color_off = color_tags(v[2])
                break
            end
        end
    end

    -- estimate time
    ctx.charge_dir = 0    -- +1|0|-1 -> charging|static|discharging
    ctx.time_left  = nil  -- time until charging/discharging complete
    ctx.time_text  = ""
    ctx.time_est   = ""

    if ctx.rate and ctx.rate ~= 0 then
        if not ctx.state or ctx.state == "discharging" then
            ctx.charge_dir = -1
            ctx.time_left = ctx.charge / ctx.rate
        elseif ctx.state == "charging" then
            ctx.charge_dir = 1
            ctx.time_left = (ctx.capacity - ctx.charge) / ctx.rate
        end
    end

    if ctx.time_left then
        ctx.hours   = math.floor((ctx.time_left))
        ctx.minutes = math.floor((ctx.time_left - ctx.hours) * 60)
        if ctx.hours > 0
            then ctx.time_text = ctx.hours .. "h " .. ctx.minutes .. "m"
            else ctx.time_text =                      ctx.minutes .. "m"
        end
        ctx.time_est = ": " .. ctx.time_text .. " remaining"
    end

    -- capacity text
    if ctx.capacity and ctx.design then
        ctx.capacity_percent = round(ctx.capacity/ctx.design*100)
    end

    -- for use in functions
    ctx.obj = self

    -- update text
    self.widget:set_markup(substitute(self.widget_text, ctx))
    self.tooltip:set_text(substitute(self.tooltip_text, ctx))

    -- low battery notification
    if naughty then
        if ctx.state == "discharging" then
            if ctx.percent and ctx.percent <= self.alert_threshold then
                self:notify(substitute(self.alert_title, ctx),
                            substitute(self.alert_text, ctx))
            end
        else
            if self.alert then
                naughty.destroy(
                    self.alert,
                    naughty.notificationClosedReason.dismissedByCommand)
                self.alert = nil
            end
        end
    end
end

function battery_widget:notify(title, text)
    if self.alert then
        naughty.replace_text(self.alert, title, text)
    else
        self.alert = naughty.notify({
            title = title,
            text = text,
            preset = naughty.config.presets.critical,
            timeout = self.alert_timeout
        })
    end
end

return setmetatable(battery_widget, {
    __call = battery_widget.new,
})
