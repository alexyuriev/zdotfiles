# x-desktop-rotator - wmctrl wrapper

## Problem

OpenBox does not support per monitor sticky windows. When switching from one virtual desktop to another it is not possible to keep some windows, typically mapped to specific monitors to follow the desktop switch.

## Why sticky windows?

That's simple: web browser. You want to have web browser follow you around. There are a few other windows that I like following me around, but the web browser is the key.

## Solution: Replace internal OpenBox desktop switcher with x-desktop-rotator

It is 2020. Computers are fast enough. `wmctrl` works well enought to control windows from command line.

To flip to the next desktop use:

`x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --next`

To flip to previous desktop use:

`x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --previous`

Add the following to openbox `rc.xml` to start using the `x-desktop-rotator`, replacing `/home/alex/.config-x-desktop-rotator.json` with the location of your configuration file.

```
    <!--
      Ctrl+Alt+LeftArrow switches to next
      Ctrl+Alt+RightArrow switches to previous

      Use x-desktop-rotator to switch desktops with sticky monitors defined rather than
      built-in openbox switching
    -->

    <keybind key="C-A-Left">
      <action name="Execute">
        <command>x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --next</command>
      </action>

    </keybind>
    <keybind key="C-A-Right">
      <action name="Execute">
        <command>x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --previous</command>
      </action>
    </keybind>
```

`config-x-desktop-rotator.json` defines coordinates of the monitors containing pinned/sticky windows. Here's my setup:

```
[4K-1][4K-2][4K-3]
         [4K-4]

```
4K-1 is a monitor that gets floating windows. On my main desktop it carries `alacritty` running `tmux`. On other desktops it gets floating windows. 4K-2 monitor has an editor on a main desktop or whatever I'm currently working with on ( `alacritty` or `xterm` ). 4K-3 is a monitor containing browser-1 and some additional status real-time information displays that I want to always follow me around regardless of the desktop i have active. Finally 4K-4 is a small 4K monitor sitting below the middle of 4K-2 and 4K-3. It runs a different web browser and some other applications that I want to always follow me around.

The following is my `config-x-desktop-rotator.json`. It tells x-desktop-rotator that any window that is located within 'most-right-4k' or 'right-low-4k' monitor is to follow desktop switching.

```
{
  "pinned-monitors" : [
    {
      "name"    : "most-right-4k",
      "start-x" : "7680",
      "start-y" : "0",
      "end-x"   : "11520",
      "end-y"   : "2160"
    },
    {
      "name"    : "right-low-4k",
      "start-x" : "5760",
      "start-y" : "2160",
      "end-x"   : "9600",
      "end-y"   : "4320"
    }
  ]
}

```

`"pinned-monitors"` is a list of boxes that define confines of pinned/sticky areas. Those boxes typically match the monitors. 0,0 is the top left corner of the desktop. If a window is within the confines of a pinned/sticky area the window will follow a switch of a desktop.
