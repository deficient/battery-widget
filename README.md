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

Optionally, in order to receive status updates, you will also need `acpid`:

```bash
pacman -S acpid
systemctl enable --now acpid
```


### Usage

In order to add a battery widget to your wibox, you have to import the module
and then instanciate a widget with the desired options like this:

```lua
-- Import module:
local battery_widget = require("battery-widget")

-- Instanciate and add widget to the wibox:
s.mywibox:setup {
    ...,
    { -- Right widgets
        ...,
        battery_widget {
            -- pass options here
        },
    },
}
```

If you pass an adapter name using the `adapter = "..."` option, a widget for
that specific battery adapter will be instanciated. If the `adapter` option is
not specified, the call will return a table containing widgets for each of the
battery adapters in `/sys/class/power_supply`. In that case if there are no
batteries an empty table will be returned and no error will occur on machines
without batteries.


### Options

The behaviour and appearance of the widget can be tweaked using a few options.
This is an example using all available options:

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
    alert_text = "${AC_BAT}${time_est}",
    alert_icon = "~/Downloads/low_battery_icon.png",
    warn_full_battery = true,
    full_battery_icon = "~/Downloads/full_battery_icon.png",
}
```

`adapter`
The name of the directory entry in `/sys/class/power_supply` corresponding to the requested battery adapter.

`ac`
The name of the directory entry in `/sys/class/power_supply` corresponding to your AC status.

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

`alert_title`, `alert_text`, `alert_icon`
The text which shows up on the alert notification, respectively the title, body text and image path.

`warn_full_battery`, boolean
Whether a notification should be displayed when the battery gets fully charged.

`full_battery_icon`
Path to the image, which should be shown as part of the notification when battery gets fully charged (depends on `warn_full_battery`).

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
        {100, "fully charged" },
    },

    -- Show a visual indicator of charge level when on battery power
    battery_prefix = {
        { 25, "#--- "},
        { 50, "##-- "},
        { 75, "###- "},
        {100, "#### "},
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

* [awesome 4.0](http://awesome.naquadah.org/).
* `acpid` (optional)
