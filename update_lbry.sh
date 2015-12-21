#!/bin/bash

exec >  >(tee -a setup.log)
exec 2> >(tee -a setup.log >&2)

DEBIAN_FRONTEND=noninteractive

ROOT=.
GIT_URL_ROOT="https://github.com/lbryio/"
CONF_DIR=~/.lbrycrd
CONF_FILE=$CONF_DIR/lbrycrd.conf
PACKAGES="git libgmp3-dev build-essential python2.7 python2.7-dev python-pip"

#install/update requirements
if hash apt-get 2>/dev/null; then
	printf "Installing $PACKAGES\n\n"
	if ! sudo apt-get install -y $PACKAGES; then
        echo $'\n\nFailed to install necessary packages. Make sure your system is up to date and then try again.'
        exit
    fi
else
	printf "Running on a system without apt-get. Install requires the following packages or equivalents: $PACKAGES\n\nPull requests encouraged if you have an install for your system!\n\n"
    exit
fi

#Clone/pull repo and return true/false whether or not anything changed
#$1 : repo name
UpdateSource() 
{
	if [ ! -d "$ROOT/$1/.git" ]; then
       	echo "$1 does not exist, checking out"
	    git clone "$GIT_URL_ROOT$1.git"
		return 0 
	else
		cd $1
		#http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
		git remote update;
		LOCAL=$(git rev-parse @{0})
		REMOTE=$(git rev-parse @{u})
		if [ $LOCAL = $REMOTE ]; then
			echo "No changes to $1 source\n"
            cd ..
			return 1 
		else
			echo "Fetching source changes to $1\n"
			git pull --rebase
            cd ..
			return 0
		fi
	fi
}

if [ ! -d bin ]; then
    printf "Creating bin\n"
    mkdir -p bin
else
    printf "bin directory already exists\n"
fi

UPDATELBRYCRD=0

if [ -e bin/lbrycrd.tar.gz ]; then
    LBRYCRDHASHSUM=`md5sum bin/lbrycrd.tar.gz | awk '{print $1}'`
    if [ ! "$LBRYCRDHASHSUM" = "046463be793a567671df691a2d4cac2f" ] && [ ! "$LBRYCRDHASHSUM" = "0cf55341bbd8594468af5792811c0977" ]; then
        UPDATELBRYCRD=1
    fi
else
    UPDATELBRYCRD=1
fi

if [ $UPDATELBRYCRD = 1 ]; then
    cd bin
    if [ `getconf LONG_BIT` = "64" ]; then
        wget --progress=bar https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_64.tar.gz -O lbrycrd.tar.gz
    else
        wget --progress=bar https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_32.tar.gz -O lbrycrd.tar.gz
    fi
    tar xf lbrycrd.tar.gz
    #create config file
    if [ ! -d $CONF_DIR ]; then
	    echo "Setting up lbrycrd data in in $CONF_DIR"
	    mkdir -p $CONF_DIR
	    echo "rpcuser=lbryrpc" > $CONF_FILE
	    echo -n "rpcpassword=" >> $CONF_FILE
	    tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-12} | xargs >> $CONF_FILE
        mv lbrycrd/lbrycrddata/* $CONF_DIR/
        rm -rf lbrycrd/lbrycrddata
    else
	    echo "$CONF_DIR already exists"
    fi

    mv lbrycrd/* .
    rm -rf lbrycrd
    cd ..
    if [ -e ~/.lbrycrddpath.conf ]; then
        if [ `cat ~/.lbrycrddpath.conf` = "`pwd`/lbrycrd/src/lbrycrdd" ]; then
            rm ~/.lbrycrddpath.conf
        fi
    fi
else
	printf "lbrycrd installed and nothing to update\n"
fi

if [ ! -e ~/.lbrycrddpath.conf ]; then
    echo `pwd`/bin/lbrycrdd > ~/.lbrycrddpath.conf
fi
#setup lbry-console
printf "\n\nInstalling/updating lbry-console\n";
if UpdateSource lbry || [ ! -d $ROOT/lbry/dist ]; then
	echo $'Updating lbry-console\n'
else
    echo $'lbry already up to date, rebuilding anyway\n'
fi
cd lbry
if [ -d dist ]; then
    if [ `stat -c "%U" dist` = "root" ]; then
        sudo rm -rf dist build ez_setup.pyc lbrynet.egg-info setuptools-4.0.1-py2.7.egg setuptools-4.0.1.zip
    fi
fi
SETUPFAILEDMESSAGE="Failed to install lbry. Make sure your system is up to date and try again.\n"
if ! python2.7 setup.py build bdist_egg; then
    echo "$SETUPFAILEDMESSAGE"
    cd ..
    exit
fi
if ! sudo python2.7 setup.py install; then
    echo "$SETUPFAILEDMESSAGE"
    cd ..
    exit
fi
cd ..
