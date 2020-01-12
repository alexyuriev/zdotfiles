# zdotfiles

Just some useful dotfiles and non-dot files that make life easier

Installation instructions

Edit install.sh and set DSTDIR to wherever you want to install everything into.
By default it will be installed into zdotfiles of your home directory.

### Misc configuraiton files

File name                                  | Description
-------------------------------------------|-------------
.config/openbox/rc.xml                     | OpenBox window manager configuration file
.config/peco/config.json                   | Configuration file for https://github.com/peco/peco interactive filtering tool. You really should bind it to Cltr-R. See .bash_profile
etc/X11/xorg.conf.d/99-no-touchscreen.conf | disables touch screen in X11 etc/profile.d/opt.sh |  /opt/bin tree should really be a part of the path in a modern system
.Xresources                                | Basic X11 customization for Xterm & Xft

### Misc useful tools

Tool name                      | Description
-------------------------------|-----------
bake-git-repo                  | Pulls merges some files from multiple repositories over a master repo based on a plan
batcheck                       | Displays the current laptop battery status in X
gitup                          | syncs up all branches of a repo against remote
gitprompt                      | Displays git repo name and a current branch. Useful for putting into prompt (PS1) of a shell
per-type-editor                | Dynamically switches the editor depending on the argument of the file to edit
randompass                     | generates a random password
show-my-external-ipv4          | Returns an IPv4 address of the system running it as seen by Google DNS
sre-sign-debian-package        | Signs a Debian package because debsig is just awful
take-screenshot                | Takes a screen shot of an area
tmux-dev-workspace             | Sets up a tmux workspace ( 3 windows )
url-2-file                     | Stores content of the URL in a file using easily assembleable configuration
xterm.wrapper                  | Wrapper for xterm to play nicely with https://github.com/alacritty/alacritty - GPU accelerated terminal
x-workspace-setup-code         | Called by the X manager to create a single work environment
extra-non-matching-lines       | Displays the lines in a file that do not have equivalent lines in another file
sre-push-to-redis-queue        | Pushes lines of a file into a Redis queue.
sre-fail-if-bad-redis-hash-key | Attempts to fetch a specific field of a redis hash and checks returned value. Exits 0 on a match, 1 on error. Very useful to ensure that redis is in the right state for async tools manipulating it.


### AWS manipulation utilities

The following tools allow to quickly do commonly needed tasks on AWS EC2 instances.

Tool name|Description
---------|-----------
aws-build-ec2-instance|Builds AWS EC2 instance from JSON configuration file with command live overrides
aws-srv-ip|Gets an IP address of a specific AWS EC2 instance
aws-list-ec2-instances|Lists AWS EC2 instances in a format easily consumable by other tools
aws-wait-ec2-instance-state|Waits for a specific instance to reach a specific state
aws-destroy-ec2-instance|Destroys a running AWS EC2 instance after renaming it to a specific string
aws-create-iam-user|Creates AWS IAM user
aws-list-iam-policies|Lists AWS IAM policies in a format easily consumable by other tools
aws-create-ec2-sec-group|Creates an AWS EC2 Security group
aws-list-ec2-sec-groups|Lists AWS EC2 Security groups in a format easily consumable by other tools
aws-edit-ec2-sec-group|Manipulates individual rules in the AWS EC2 security group
aws-save-ec2-tags|Stores value of AWS EC2 instance tags in a file
aws-set-ec2-tags|Sets a specific tag on an AWS EC instance


### Note:
---------

Some of the tools in this repo rely on a private ``perl-helper-libs`` repo. The to build a release ``config-bake-git-repo.zdotfiles.json`` is provided.
