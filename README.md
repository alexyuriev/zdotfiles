# zdotfiles
Just some useful dotfiles and non-dot files

Installation instructions

Edit install.sh and set DSTDIR to wherever you want to install everything into
By default it will be installed into zdotfiles of your home directory

* dconfig       - configuration files for users .config directory
  * openbox/rc.xml - OpenBox window manager configuration file
* etc/X11/xorg.conf.d/99-no-touchscreen.conf - disables touch screen in X11
* etc/profile.d/opt.sh - /opt/bin tree should really be a part of the path 
                       in a modern system
* batcheck              - Show status of battery
* take-screenshot	      - Takes a screenshot of a section of the screen
* .Xresources - Basic X11 customization for Xterm & Xft
* show-my-external-ipv4 - ask Google's DNS for our public IPv4 address