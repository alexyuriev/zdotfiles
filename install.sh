#!/bin/bash

help_and_exit() {
	echo ""
	echo "This is zdotfiles (http://github.com/alexyuriev/zdotfiles"
	echo ""
	echo "The installer requires a single argument - destination directory"
	echo ""
	echo "Example: "
	echo ""
	echo "./install.sh /home/alex/alex/zdotfiles-home"
	echo ""
	echo "This will install files into /home/alex/alex/zdotfiles-home"
	echo ""
	echo ""
	echo "Destination directory should not be ${HOME}"

	exit 1

}

if [[ $# -ne 1 ]]; then
	help_and_exit
fi

if [[ "$1" == "${HOME}" ]]; then
	help_and_exit
fi

DSTDIR=$1

DSTDIRBIN=${DSTDIR}/bin

DIRDOTCONFIG=.config
SRCDOTCONFIG=${DIRDOTCONFIG}
DSTDOTCONFIG=${DSTDIR}/${DIRDOTCONFIG}

DIRPROFILED=etc/profile.d
SRCETCPROFILED=${DIRPROFILED}
DSTETCPROFILED=${DSTDIR}/${DIRPROFILED}


DIRDOTCONFIGOPENBOX=.config/openbox
SRCDOTCONFIGOPENBOX=${DIRDOTCONFIGOPENBOX}
DSTDOTCONFIGOPENBOX=${DSTDIR}/${DIRDOTCONFIGOPENBOX}

DIRXORGCONFD=etc/X11/xorg.conf.d
SRCXORGCONFD=${DIRXORGCONFD}
DSTXORGCONFD=${DSTDIR}/${DIRXORGCONFD}

SRCHELPERLIBDIR=bin/lib/Helpers
DSTHELPERLIBDIR=${DSTDIR}/${SRCHELPERLIBDIR}

SRCBINDIR=bin

HELPERLIBS="AWS.pm Misc.pm Logger.pm RedisClient.pm"
AWSTOOLS="aws-build-ec2-instance
	  aws-srv-ip
	  aws-list-ec2-instances
	  aws-list-ec2-amis
	  aws-wait-ec2-instance-state
	  aws-destroy-ec2-instance
	  aws-create-iam-user
	  aws-list-iam-policies
	  aws-create-ec2-sec-group
	  aws-list-ec2-sec-groups
	  aws-edit-ec2-sec-group
	  aws-save-ec2-tags
	  aws-set-ec2-tags
	  aws-rename-ec2-instance
	  "

CMD="echo ${AWSTOOLS} | tr -d '\n'"
AWSTOOLS=$(eval $CMD)

MISCBINS="	batcheck
			randompass
			gitprompt
			take-screenshot
			show-my-external-ipv4
			peco-redis-backend
			gitup
			url-2-file
			extra-non-matching-lines
			sre-push-to-redis-queue
			sre-sign-debian-package
			sre-fail-if-bad-redis-hash-key
			sre-validate-dns-record
			per-type-editor
			evince-mc
			qiv-mc
			tmux-dev-workspace
			x-workspace-setup-code.alacritty
			x-workspace-setup-code.xterm
			x-launch-in-location
			xterm.wrapper
			take_notes"

CMD="echo ${MISCBINS} | tr -d '\n'"
MISCBINS=$(eval $CMD)

ROOTDOTFILES="	.ackrc
                .curlrc
				.bash_profile
				.bash_colors
				.bash_aliases
				.nvidia-settings-rc
				.compton.conf
				.tmux.conf
				.Xresources
				.xbindkeysrc"

CMD="echo ${ROOTDOTFILES} | tr -d '\n'"
ROOTDOTFILES=$(eval $CMD)

PROFILEDFILES="opt.sh"
CONFIGOPENBOX="rc.xml"
XORGCONFDFILES="99-no-touchscreen.conf"

echo "Installing dot files into ${DSTDIR}"
mkdir -p ${DSTDIR}
for i in ${ROOTDOTFILES} ; do
	j=$i
	install -m 644 $j ${DSTDIR}
done

echo "Installing helper perl libraries into ${DSTHELPERLIBDIR}"
mkdir -p ${DSTDIRBIN}/lib/Helpers
for i in ${HELPERLIBS}; do
	j=${SRCHELPERLIBDIR}/$i
	install -m 644 $j ${DSTHELPERLIBDIR}
done

echo "Installing wrapped aws-* tools into ${DSTDIRBIN}"
for i in ${AWSTOOLS}; do
	j=${SRCBINDIR}/$i
	install -m 755 $j ${DSTDIRBIN}
done

echo "Installing misc bin helpers into ${DSTDIRBIN}"
for i in ${MISCBINS} ; do
	j=${SRCBINDIR}/$i
	install -m 755 $j ${DSTDIRBIN}
done

echo "Installing /etc/profile.d files into ${DSTETCPROFILED}"
mkdir -p ${DSTETCPROFILED}
for i in ${PROFILEDFILES} ; do
	j=${SRCETCPROFILED}/$i
	install -m 644 $j ${DSTETCPROFILED}
done

echo "Installing openbox config files into ${DSTDOTCONFIGOPENBOX}"
mkdir -p ${DSTDOTCONFIGOPENBOX}
for i in ${CONFIGOPENBOX} ; do
	j=${SRCDOTCONFIGOPENBOX}/$i
	install -m 644 $j ${DSTDOTCONFIGOPENBOX}
done

echo "Installing xorg.conf.d files into ${DSTXORGCONFD}"
mkdir -p ${DSTXORGCONFD}
for i in ${XORGCONFDFILES} ; do
	j=${SRCXORGCONFD}/$i
	install -m 644 $j ${DSTXORGCONFD}
done
