## awesome.battery-widget

### Description

Battery indicator widget for awesome window manager.

Uses `/sys/class/power_supply` for status information, and `acpi_listen` when
`listen` is enabled.


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/battery-widget.git
```


### Usage

In your `rc.lua`:

```lua
local battery_widget = require("battery-widget")


-- define your battery widget (you may need to use another adapter name as in
-- your /sys/class/power_supply)
local battery = battery_widget({adapter = "BAT0"})


-- add the widget to your wibox
...
right_layout:add(battery.widget)
...
```

If you have multiple batteries or use the same `rc.lua` on multiple devices with differing numbers of batteries:

```lua
...
-- creates an empty container wibox, which can be added to your panel even if its empty
local batteries = { layout = wibox.layout.fixed.horizontal }
for i, adapter in ipairs(battery_widget:discover()) do
    table.insert(batteries, battery_widget({adapter = adapter}).widget)
end
...

-- add 'batteries' to the widget container
s.mywibox:setup {
    layout = wibox.layout.align.horizontal,
    { -- Left widgets
        ...,
    },
    ...,
    { -- Right widgets
        ...,
        batteries,
    },
}
```

### Usage Options

Full example:

```lua
battery_widget({
    adapter = "BAT0",
    ac_prefix = "AC: ",
    battery_prefix = "Bat: ",
    limits = {
        { 25, "red"   },
        { 50, "orange"},
        {100, "green" }
    },
    listen = true,
    timeout = 10,
    widget_text = "${AC_BAT}${color_on}${percent}%${color_off}",
    widget_font = "Deja Vu Sans Mono 16",
    tooltip_text = "Battery ${state}${time_est}\nCapacity: ${capacity_percent}%",
    alert_threshold = 5,
    alert_timeout = 0,
    alert_title = "Low battery !",
    alert_text = "${AC_BAT}${time_est}"
})
```

`adapter`
The pointer located inside of `/sys/class/power_supply` which corresponds to your battery's status.

`ac_prefix`
The prefix to populate `${AC_BAT}` when your computer is using ac power. If your font supports unicode characters, you could use "🔌".

`battery_prefix`
The prefix to populate `${AC_BAT}` when your computer is using battery power. If your font supports unicode characters, you could use "🔋".

`limits`
The colors that the percentage changes to, as well as the upper-bound limit of when it will change. Ex. `{100, "green"}` means any percentage lower than 100 is colored green.

`listen`
Tells the widget to listen to updates via `acpi_listen`. When an event is fired, the widget updates.

`timeout`
The time interval that the widget waits before it updates itself, in seconds.

`widget_text`, `tooltip_text`
The text which shows up on the toolbar and when you highlight the widget, respectively. Please refer to function `battery_widget:update()` for other interpolatable variables.

`widget_font`
The font description used for the widget text, for instance "Deja Vu Sans Mono 16". If this is empty or unspecified, the default font will be used.

`alert_threshold`
The percentage used as the maximum value at which an alert will be generated, `-1` to disable alerts. Once the alert is dismissed (or expired) it will not show up again until the battery has been charging.

`alert_timeout`
The time after which the alert expire, `0` for no timeout.

`alert_title`, `alert_text`
The text which shows up on the alert notification, respectively the title and body text.

### Requirements

* [awesome 4.0](http://awesome.naquadah.org/) and possibly also 3.5

