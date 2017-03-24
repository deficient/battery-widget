-- Battery widget

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

------------------------------------------
-- Private utility functions
------------------------------------------

local function file_exists(command)
    local f = io.open(command)
    if not f then return false end
    f:close()
    return true
end

local function readfile(command)
    local file = io.open(command)
    if file == nil then
        return nil
    end
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
    if s == nil then return nil end
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function substitute(template, context)
  return (template:gsub("%${([%w_]+)}", function(key)
    return tostring(context[key])
  end))
end

------------------------------------------
-- Battery widget interface
------------------------------------------

local battery_widget = {}

function battery_widget:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function battery_widget:init(args)
    self.adapter = args.adapter or "BAT0"
    self.ac_prefix = args.ac_prefix or "AC: "
    self.battery_prefix = args.battery_prefix or "Bat: "
    self.limits = args.limits or {
        {25, "red"},
        {50, "orange"},
        {100, "green"}
    }
    self.text_template = args.text_template or "${prefix}${color_on}${text}${color_off}"
    self.tooltip_template = args.tooltip_template or "Battery ${state}${est_postfix}${captext}"

    self.widget = wibox.widget.textbox()
    self.widget.set_align("right")
    self.tooltip = awful.tooltip({objects={self.widget}})

    self.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() self:update() end),
        awful.button({ }, 3, function() self:update() end)
    ))

    self.timer = gears.timer({ timeout = args.timeout or 10 })
    self.timer:connect_signal("timeout", function() self:update() end)
    self.timer:start()
    self:update()

    return self
end

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
    }
}

function battery_widget:get_state()
    local pre   = "/sys/class/power_supply/"
    local dir   = pre .. self.adapter
    local sysfs = (file_exists(dir.."/"..sysfs_names.charging.rate)
                   and sysfs_names.charging
                   or sysfs_names.discharging)

    local function read_trim(filename)
      return trim(readfile(filename))
    end

    local raw = {
      state     = read_trim(dir.."/"..sysfs.state),
      present   = read_trim(dir.."/"..sysfs.present),
      rate      = read_trim(dir.."/"..sysfs.rate),
      charge    = read_trim(dir.."/"..sysfs.charge),
      capacity  = read_trim(dir.."/"..sysfs.capacity),
      design    = read_trim(dir.."/"..sysfs.design),
      ac_state  = read_trim(pre.."/"..sysfs.ac_state),
      percent   = read_trim(dir.."/"..sysfs.percent),
    }

    -- return value
    local r = {
      state    = raw.state:lower(),
      present  = tonumber(raw.present),
      rate     = tonumber(raw.rate),
      charge   = tonumber(raw.charge),
      capacity = tonumber(raw.capacity),
      design   = tonumber(raw.design),
      ac_state = tonumber(raw.ac_state),
      percent  = tonumber(raw.percent),
    }

    if r.state == "unknown" then
        r.state = "charged"
    end

    -- loaded percentage
    if r.charge and r.capacity and not r.percent then
        r.percent = round(r.charge * 100 / r.capacity)
    end

    -- estimate time
    r.is_charging = 0
    r.time = -1
    if r.rate ~= 0 and r.rate ~= nil then
        if r.state == "charging" then
            r.time = (r.capacity - r.charge) / r.rate
            r.is_charging = 1
        elseif state == "discharging" or state == nil then
            r.time = r.charge / r.rate
            r.is_charging = -1
        end
    end

    return r
end

function battery_widget:update()
    local ctx = self:get_state()

    -- AC/battery prefix
    ctx.prefix = ctx.ac_state == 1 and self.ac_prefix or self.battery_prefix
    ctx.text   = (ctx.percent or "Err!") .. '%'
    ctx.state  = ctx.state or "Err!"

    -- Percentage
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

    -- Time
    if ctx.time == -1 then
        ctx.est_postfix = "..."
    else
        ctx.time_hour = math.floor(ctx.time)
        ctx.time_minute = math.floor((ctx.time - ctx.time_hour) * 60)
        ctx.time_str = ""
        if ctx.time_hour ~= 0 then
            ctx.time_str = ctx.time_hour .. "h "
        end
        ctx.time_str = ctx.time_str .. ctx.time_minute .. "m"
        ctx.est_postfix = ": "..ctx.time_str.." remaining"
    end

    if ctx.is_charging == 0 then
        ctx.est_postfix = ""
    end

    -- capacity text
    if ctx.capacity and ctx.design then
        ctx.captext = "\nCapacity: " .. round(ctx.capacity/ctx.design*100) .. "%"
    else
        ctx.captext = "\nCapacity: Err!"
    end

    -- update text
    self.widget:set_markup(substitute(self.text_template, ctx))
    self.tooltip:set_text(substitute(self.tooltip_template, ctx))
end

return setmetatable(battery_widget, {
  __call = battery_widget.new,
})
