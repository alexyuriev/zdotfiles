#!/bin/bash 

DSTDIR=$HOME/zdotfiles



DSTDIRBIN=${DSTDIR}/bin
DSTDOTROOT=${DSTDIR}/dot-in-home-root

DIRDOTCONFIG=.config
SRCDOTCONFIG=${DIRDOTCONFIG}
DSTDOTCONFIG=${DSTDIR}/${DIRDOTCONFIG}

DIRPROFILED=etc/profile.d
SRCETCPROFILED=${DIRPROFILED}
DSTETCPROFILED=${DSTDIR}/${DIRPROFILED}

DIRDOTCONFIGOPENBOX=.config/openbox
SRCDOTCONFIGOPENBOX=${DIRDOTCONFIGOPENBOX}
DSTDOTCONFIGOPENBOX=${DSTDOTCONFIG}/${DIRDOTCONFIGOPENBOX}

DIRXORGCONFD=etc/X11/xorg.conf.d
SRCXORGCONFD=${DIRXORGCONFD}
DSTXORGCONFD=${DSTDIR}/${DIRXORGCONFD}

SRCHELPERLIBDIR=bin/lib/Helpers
DSTHELPERLIBDIR=${DSTDIR}/${SRCHELPERLIBDIR}

SRCBINDIR=bin

HELPERLIBS="AWS.pm Misc.pm Logger.pm"
AWSTOOLS="aws-iam-create-user aws-build-ec2-instance aws-list-ec2-sec-groups aws-create-ec2-sec-group aws-edit-ec2-sec-group aws-wait-ec2-instance-state aws-list-ec2-instances aws-list-iam-policies aws-set-ec2-tags aws-save-ec2-tags aws-srv-ip*"
MISCBINS="batcheck randompass take-screenshot show-my-external-ipv4 gitup url-2-file"
ROOTDOTFILES=".curlrc .bash_profile .nvidia-settings-rc .compton.conf .Xresources .xbindkeysrc"
PROFILEDFILES="opt.sh"
CONFIGOPENBOX="rc.xml"
XORGCONFDFILES="99-no-touchscreen.conf"

echo "Installing helper perl libraries into ${DSTHELPLIBDIR}"
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

echo "Install misc bin helpers into ${DSTDIRBIN}"
for i in ${MISCBINS} ; do
	j=${SRCBINDIR}/$i
	install -m 755 $j ${DSTDIRBIN}
done

echo "Installing dot files into root of the homedir - ${DSTDOTROOT}"
mkdir -p ${DSTDOTROOT}
for i in ${ROOTDOTFILES} ; do 
	j=$i
	install -m 644 $j ${DSTDOTROOT}
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
