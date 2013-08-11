## awesome.battery-widget

### Description

Battery indicator widget for awesome window manager.

Uses `/sys/class/power_supply` for status information.


### Installation

Drop the script into your awesome config folder. Suggestion:

    cd ~/.config/awesome
    git clone https://github.com/coldfix/awesome.battery-widget.git
    ln -s awesome.battery-widget/battery-widget.lua


### Usage

In your `rc.lua`:

    -- load the widget code
    local battery_widget = require("battery-widget")


    -- define your volume control
    battery = battery_widget({adapter = "BAT0"})

    -- add the widget to your wibox
    ...
    right_layout:add(battery.widget)
    ...


### Requirements

* [awesome 3.5](http://awesome.naquadah.org/)
