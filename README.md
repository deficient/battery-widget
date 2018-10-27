## awesome.battery-widget

Battery indicator widget for awesome window manager.

![Screenshot](/screenshot.png?raw=true "Screenshot")

Displays status information from `/sys/class/power_supply`.


### Installation

Drop the script into your awesome config folder, e.g.:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/battery-widget.git
```

For instant status updates, I recommend to install the following optional
dependency:

```bash
pacman -S acpid
systemctl enable acpid
```


### Usage

All it takes is one additional line in your `rc.lua`:

```lua
    -- Add widgets to the wibox
    s.mywibox:setup {
        ...,
        { -- Right widgets
            ...,
            require("battery-widget") {},
        },
    }
```

This will try to detect battery adapters in `/sys/class/power_supply` and add
one widget for each of them. (With the effect, that this should not crash on
machines without batteries)

If you want more control, you can pass the name of a specific adapter as argument
to the constructor, e.g.:

```lua
local battery_widget = require("battery-widget")
local BAT0 = battery_widget { adapter = "BAT0", ac = "AC" }

s.mywibox:setup {
    ...,
    { -- Right widgets
        ...,
        BAT0,
    },
}
```

### Usage Options

Full example:

```lua
battery_widget {
    ac = "AC",
    adapter = "BAT0",
    ac_prefix = "AC: ",
    battery_prefix = "Bat: ",
    percent_colors = {
        { 25, "red"   },
        { 50, "orange"},
        {999, "green" },
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
}
```

`adapter`
The pointer located inside of `/sys/class/power_supply` which corresponds to your battery's status.

`ac`
The pointer located inside of `/sys/class/power_supply` which corresponds to your AC status.

`ac_prefix`
The prefix to populate `${AC_BAT}` when your computer is using ac power. If your font supports unicode characters, you could use "🔌".

`battery_prefix`
The prefix to populate `${AC_BAT}` when your computer is using battery power. If your font supports unicode characters, you could use "🔋". Can also be configured as a table like `percent_colors` to show different prefixes at different battery percentages.

`percent_colors` (`limits` for backwards compatibility)
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

`warn_full_battery`, boolean
Whether a notification should be displayed when the battery gets fully charged

### Usage Examples

Percentage tables can be used for `ac_prefix`, `battery_prefix`, and `percent_colors` to show different things depending on the battery charge level, e.g.:

```lua
battery_widget {
    -- Show different prefixes when charging on AC
    ac_prefix = {
        { 25, "not charged" },
        { 50, "1/4 charged" },
        { 75, "2/4 charged" },
        { 95, "3/4 charged" },
        {100, "fully charged" }
    },

    -- Show a visual indicator of charge level when on battery power
    battery_prefix = {
        { 25, "#--- "},
        { 50, "##-- "},
        { 75, "###- "},
        {100, "#### "}
    }
}
```

`ac_prefix`, `battery_prefix`, and `widget_text` can be further customized with spans to specify colors or fonts, e.g.:

```lua
battery_widget {
    -- Use different colors for ac_prefix and battery_prefix
    ac_prefix = '<span color="red">AC: </span>',
    battery_prefix = '<span color="green">Bat: </span>',

    -- Use a bold font for both prefixes (overrides widget_font)
    widget_text = '<span font="Deja Vu Sans Bold 16">${AC_BAT}</span>${color_on}${percent}%${color_off}'
}
```

### Requirements

* [awesome 4.0](http://awesome.naquadah.org/). May work on 3.5 with minor changes.
* `acpid` (optional)

