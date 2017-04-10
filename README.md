## awesome.battery-widget

### Description

Battery indicator widget for awesome window manager.

Uses `/sys/class/power_supply` for status information, and `acpi_listen` when
`listen` is enabled.


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/coldfix/awesome.battery-widget.git battery-widget
```


### Usage

In your `rc.lua`:

```lua
-- load the widget code
local battery_widget = require("battery-widget")


-- define your battery widget
battery = battery_widget({adapter = "BAT0"})


-- add the widget to your wibox
...
right_layout:add(battery.widget)
...
```


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/) and possibly also 3.5
