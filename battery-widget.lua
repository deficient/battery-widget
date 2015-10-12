local awful = require("awful")
local wibox = require("wibox")

-- Battery widget

-- battery_widget.mt: module (class) metatable
-- battery_widget.wmt: widget (instance) metatable
local battery_widget = { mt = {}, wmt = {} }
battery_widget.wmt.__index = battery_widget


------------------------------------------
-- Private utility functions
------------------------------------------

local function readfile(command)
    local file = io.open(command)
    local text = file:read('*all')
    file:close()
    return text
end

function fg(color, text)
    if color == nil then
        return text
    else
        return '<span color="' .. color .. '">' .. text .. '</span>'
    end
end

function round(value)
  return math.floor(value + 0.5)
end

------------------------------------------
-- Battery widget interface
------------------------------------------

function battery_widget.new(args)
    local sw = setmetatable({}, battery_widget.wmt)

    sw.adapter = args.adapter or "BAT0"
    sw.limits = args.limits or {
        {25, "red"},
        {50, "orange"},
        {100, "green"}
    }

    sw.widget = wibox.widget.textbox()
    sw.widget.set_align("right")
    sw.tooltip = awful.tooltip({objects={sw.widget}})

    sw.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() sw:update() end),
        awful.button({ }, 3, function() sw:update() end)
    ))

    sw.timer = timer({ timeout = args.timeout or 10 })
    sw.timer:connect_signal("timeout", function() sw:update() end)
    sw.timer:start()
    sw:update()

    return sw
end

function battery_widget:get_state()
    local present, capacity, state, rate, charge
    local percent, time, is_charging

    local dir = "/sys/class/power_supply/" .. self.adapter
    present   = readfile(dir.."/present")
    state     = trim(readfile(dir.."/status"):lower())
    rate      = readfile(dir.."/power_now")
    charge    = readfile(dir.."/energy_now")
    capacity  = readfile(dir.."/energy_full")
    design    = readfile(dir.."/energy_full_design")

    if state == "unknown" then
        state = "charged"
    end

    -- ac_state = tonumber(ac_state)
    ac_state = state ~= "discharging"
    rate = tonumber(rate)
    charge = tonumber(charge)
    capacity = tonumber(capacity)

    -- loaded percentage
    percent = round(charge * 100 / capacity)

    -- estimate time
    is_charging = 0
    time = -1
    if rate ~= 0 then
        if state == "charging" then
            time = (capacity - charge) / rate
            is_charging = 1
        elseif state == "discharging" then
            time = charge / rate
            is_charging = -1
        end
    end

    return percent, ac_state, time, state, is_charging, capacity, design
end

function battery_widget:update()
    local percent, ac_state, time, state, is_charging, capacity, design = self:get_state()
    local prefix, text
    local time_hour, time_minute, time_str, est_postfix

    -- AC/battery prefix
    if ac_state then
        prefix = "AC: "
    else
        prefix = "Bat: "
    end

    -- Percentage
    -- text =  "⚡ ".. percent .. "%"
    text =  percent .. "%"
    for k,v in ipairs(self.limits) do
        if percent <= v[1] then
            text = fg(v[2], text)
            break
        end
    end

    -- Time
    if time == -1 then
        est_postfix = "..."
    else
        time_hour = math.floor(time)
        time_minute = math.floor((time - time_hour) * 60)
        time_str = ""
        if time_hour ~= 0 then
            time_str = time_hour .. "h "
        end
        time_str = time_str .. time_minute .. "m"
        est_postfix = ": "..time_str.." remaining"
    end


    -- update text
    self.widget:set_markup(prefix..text)

    -- capacity text
    captext = "\nCapacity: " .. round(capacity/design*100) .. "%"

    -- update tooltip
    if is_charging == 1 then
        self.tooltip:set_text("Battery "..state..est_postfix..captext)
    elseif is_charging == -1 then
        self.tooltip:set_text("Battery "..state..est_postfix..captext)
    else
        self.tooltip:set_text("Battery "..state..captext)
    end
end


function battery_widget.mt:__call(...)
    return battery_widget.new(...)
end

return setmetatable(battery_widget, battery_widget.mt)

