# x-desktop-rotator

## Rotate X desktop while maintaining sticky windows

Do modern desktop environments annoy you? Do you find them bulky, overly opinionated and optimized for pedestrian setups? I do. To me the best environment is a few monitors ( in my case 4x 4K) managed by a small, fast and never stand in a way window manager called OpenBox that I can easily configure to do what I want, including having multiple virtual desktops. It does, however, have a very annoying flaw - it lacks support for sticky windows i.e. windows that follow you around when swithing desktops.

## Why sticky windows?

That's simple: web browser. You want to have web browser follow you around. There are a few other windows that I like following me around, but the web browser is the key.

## Solution: Replace internal OpenBox desktop switcher with x-desktop-rotator

It is 2020. Computers are fast enough. To flip to the next desktop use:

`x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --next`

To flip to previous desktop use:

`x-desktop-rotator --config=/home/alex/.config/config-x-desktop-rotator.json --next`


Add this to openbox rc.xml to start using the x-desktop-rotator

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

`config-x-desktop-rotator.json` defines coordinates of the monitors containing pinned windows. Here's my setup

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
