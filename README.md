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
-- load the widget code
local battery_widget = require("battery-widget")


-- define your battery widget (you may need to use another adapter name as in
-- your /sys/class/power_supply)
battery = battery_widget({adapter = "BAT0"})


-- add the widget to your wibox
...
right_layout:add(battery.widget)
...
```

### Usage Options

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
    listen=true,
    timeout = 10,
    widget_text = "${AC_BAT}${color_on}${percent}%${color_off}",
    tooltip_text = "Battery ${state}${time_est}\nCapacity: ${capacity_percent}%"
})
```

`adapter`  
The pointer located inside of `/sys/class/power_supply` which corresponds to your battery's status.

`ac_prefix`  
The prefix to populate `${AC_BAT}` when your computer is using ac power.

`battery_prefix`  
The prefix to populate `${AC_BAT}` when your computer is using battery power.

`limits`  
The colors that the percentage changes to, as well as the upper-bound limit of when it will change. Ex. `{100, "green"}` means any percentage lower than 100 is colored green.

`listen`  
Tells the widget to listen to updates via `acpi_listen`. When an event is fired, the widget updates.

`timeout`  
The time interval that the widget waits before it updates itself, in seconds.

`widget_text`, `tooltip_text`  
The text which shows up on the toolbar and when you highlight the widget, respectively. Please refer to function `battery_widget:update()` for other interpolatable variables.


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/) and possibly also 3.5

