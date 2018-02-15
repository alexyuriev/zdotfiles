# zdotfiles
Just some useful dotfiles and non-dot files that make life easier

Installation instructions

Edit install.sh and set DSTDIR to wherever you want to install everything into.
By default it will be installed into zdotfiles of your home directory.

* dconfig       - configuration files for users .config directory
  * openbox/rc.xml - OpenBox window manager configuration file
* etc/X11/xorg.conf.d/99-no-touchscreen.conf - disables touch screen in X11
* etc/profile.d/opt.sh - /opt/bin tree should really be a part of the path
                       in a modern system
* batcheck                - Show status of battery
* take-screenshot	      - Takes a screenshot of a section of the screen
* .Xresources - Basic X11 customization for Xterm & Xft
* show-my-external-ipv4 - ask Google's DNS for our public IPv4 address


### AWS manipulation utilities

The following tools allow to quickly do commonly needed tasks on AWS EC2 instances.

Tool name|Description
---------|-----------
aws-build-ec2-instance|Builds AWS EC2 instance from JSON configuration file with command live overrides
aws-list-ec2-instances|Lists AWS EC2 instances in a format easily consumable by other tools
aws-destroy-ec2-instance|Destroys a running AWS EC2 instance after renaming it to a specific string
aws-create-ec2-sec-group|Creates an AWS EC2 Security group
aws-list-ec2-sec-groups|Lists AWS EC2 Security groups in a format easily consumable by other tools
aws-create-iam-user|Creates AWS IAM user
aws-list-iam-policies|Lists AWS IAM policies in a format easily consumable by other tools
aws-edit-ec2-sec-group|Manipulates individual rules in the AWS EC2 security group
aws-save-ec2-tags|Stores value of AWS EC2 instance tags in a file
aws-set-ec2-tags|Sets a specific tag on an AWS EC instance
aws-srv-ip|Gets an IP address of a specific AWS EC2 instance
aws-wait-ec2-instance-state|Waits for a specific instance to reach a specific state
