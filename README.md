# zdotfiles

Just some useful dotfiles and non-dot files that make life easier

### Installation instructions

Edit `install.sh` and set `DSTDIR` to wherever you want to install everything into.
By default it will be installed into `zdotfiles` of your home directory.

### Misc configuraiton files

File name                                  | Description
-------------------------------------------|-------------
.config/openbox/rc.xml                     | OpenBox window manager configuration file
.config/peco/config.json                   | Configuration file for https://github.com/peco/peco interactive filtering tool. You really should bind it to Cltr-R. See .bash_profile
etc/X11/xorg.conf.d/99-no-touchscreen.conf | disables touch screen in X11 etc/profile.d/opt.sh |  /opt/bin tree should really be a part of the path in a modern system
.Xresources                                | Basic X11 customization for Xterm & Xft
.ackrc                                     | Configuration for ack search tool -- ignore cases
example-configs/config-wks-redis.json      | Config for accessing a REDIS server for tools that require it

### Misc useful tools

Tool name                      | Description
-------------------------------|-----------
bake-git-repo                  | Pulls merges some files from multiple repositories over a master repo based on a plan
batcheck                       | Displays the current laptop battery status in X
gitup                          | syncs up all branches of a repo against remote
gitprompt                      | Displays git repo name and a current branch. Useful for putting into prompt (PS1) of a shell
per-type-editor                | Dynamically switches the editor depending on the argument of the file to edit
evince-mc                      | Evince wrapper that places Evince window into a specific location
qiv-mc                         | qiv wrapper that places qiv window into a specific location
randompass                     | generates a random password
peco-redis-backend             | Tool to push all bash interactive commands from a workstation into a REDIS to allow peco to select commands regardless of the sessions those commands were typed in.
show-my-external-ipv4          | Returns an IPv4 address of the system running it as seen by Google DNS
sre-sign-debian-package        | Signs a Debian package because debsig is just awful
take-screenshot                | Takes a screen shot of an area
tmux-dev-workspace             | Sets up a tmux workspace ( 3 windows )
url-2-file                     | Stores content of the URL in a file using easily assembleable configuration
xterm.wrapper                  | Wrapper for xterm to play nicely with [alacritty](https://github.com/alacritty/alacritty) - GPU accelerated terminal
x-workspace-setup-code         | Called by the X manager to create a single work environment
x-launch-in-location           | Launches an X application with a specific window position
x-desktop-rotator              | [Rotates desktop while maintaining pinned windows](bin/x-desktop-rotator.md)
extra-non-matching-lines       | Displays the lines in a file that do not have equivalent lines in another file
sre-push-to-redis-queue        | Pushes lines of a file into a Redis queue.
sre-push-json-to-redis-queue   | Pushes a properly formatted JSON into a Redis queue.
sre-fail-if-bad-redis-hash-key | Attempts to fetch a specific field of a redis hash and checks returned value. Exits 0 on a match, 1 on error. Very useful to ensure that redis is in the right state for async tools manipulating it.
sre-validate-dns-record        | Checks a specific name server response for a specific value
take_notes                     | A wrapper for taking notes stored in a single text file, entries timestamped. Uses ``joe`` text editor. Use ``take_notes [<beginning of a note>]``

### AWS manipulation utilities

The following tools allow to quickly do commonly needed tasks on AWS EC2 instances.

Tool name                   | Description
----------------------------|-----------------------------------------------------------------------
aws-build-ec2-instance      | Builds AWS EC2 instance from JSON configuration file with command live overrides
aws-srv-ip                  | Gets an IP address of a specific AWS EC2 instance
aws-list-ec2-instances      | Lists AWS EC2 instances in a format easily consumable by other tools
aws-list-ec2-amis           | Lists AWS EC2 AMIs in a form easily consumable by other tools ( and humans )
aws-wait-ec2-instance-state | Waits for a specific instance to reach a specific state
aws-destroy-ec2-instance    | Destroys a running AWS EC2 instance after renaming it to a specific string
aws-create-iam-user         | Creates AWS IAM user
aws-list-iam-policies       | Lists AWS IAM policies in a format easily consumable by other tools
aws-create-ec2-sec-group    | Creates an AWS EC2 Security group
aws-list-ec2-sec-groups     | Lists AWS EC2 Security groups in a format easily consumable by other tools
aws-edit-ec2-sec-group      | Manipulates individual rules in the AWS EC2 security group
aws-save-ec2-tags           | Stores value of AWS EC2 instance tags in a file
aws-set-ec2-tags            | Sets a specific tag on an AWS EC instance
aws-rename-ec2-instance     | Renames AWS EC2 instance

### Note:
---------

Some of the tools in this repo rely on a private ``perl-helper-libs`` repo. The needed dependencies have already been merged into this tree.
``config-bake-git-repo.zdotfiles.json`` is a configuration tool for ``bake-git-repo`` tool used to merge the dependencies. You should not need to use it.
