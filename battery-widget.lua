-- Battery widget

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

------------------------------------------
-- Private utility functions
------------------------------------------

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
    return setmetatable({}, {__index = self}):init(args)
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

    self.text_template = args.text_template or (
        "${AC_BAT}${color_on}${percent}%${color_off}")
    self.tooltip_template = args.tooltip_template or (
        "Battery ${state}${time_est}\nCapacity: ${capacity_percent}%")

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

    if r.charge and r.capacity then
        r.percent = r.percent or round(r.charge * 100 / r.capacity)
    end

    return r
end

function battery_widget:update()
    local ctx = self:get_state()

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
        ctx.hours   = math.floor((ctx.time))
        ctx.minutes = math.floor((ctx.time - ctx.hours) * 60)
        if ctx.hours == 0
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
    self.widget:set_markup(substitute(self.text_template, ctx))
    self.tooltip:set_text(substitute(self.tooltip_template, ctx))
end

return setmetatable(battery_widget, {
  __call = battery_widget.new,
})
