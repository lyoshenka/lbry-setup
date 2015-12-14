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
	sudo apt-get install -y $PACKAGES || ( echo "\n\nFailed to install necessary packages. Make sure your system is up to date and then try again." && exit )
else
	printf "Running on a system without apt-get. Install requires the following packages or equivalents: $PACKAGES\n\nPull requests encouraged if you have an install for your system!\n\n"
    exit
fi

#create config file
if [ ! -f $CONF_FILE ]; then
	echo "Adding lbry config in $CONF_DIR"
	mkdir -p $CONF_DIR
	echo "rpcuser=lbryrpc" > $CONF_FILE
	echo -n "rpcpassword=" >> $CONF_FILE
	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-12} | xargs >> $CONF_FILE 
else
	echo "Config $CONF_FILE already exists"
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
    if [ ! "$LBRYCRDHASHSUM" = "5d876e2e2713c1f063ddc2ee46ad59f6" ] && [ ! "$LBRYCRDHASHSUM" = "79508c039a28aff329ccb49dd3d41691" ]; then
        UPDATELBRYCRD=1
    fi
else
    UPDATELBRYCRD=1
fi

if [ $UPDATELBRYCRD = 1 ]; then
    cd bin
    if [ `getconf LONG_BIT` = "64" ]; then
        wget https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_64.tar.gz -O lbrycrd.tar.gz
    else
        wget https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_32.tar.gz -O lbrycrd.tar.gz
    fi
    tar xf lbrycrd.tar.gz
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
	echo "Updating lbry-console\n"
else
    echo "lbry already up to date, rebuilding anyway\n"
fi
cd lbry
if [ -d dist ]; then
    if [ `stat -c "%U" dist` = "root" ]; then
        sudo rm -rf dist build ez_setup.pyc lbrynet.egg-info setuptools-4.0.1-py2.7.egg setuptools-4.0.1.zip
    fi
fi
SETUPFAILEDMESSAGE="Failed to install lbry. Make sure your system is up to date and try again.\n"
python2.7 setup.py build bdist_egg || ( echo "$SETUPFAILEDMESSAGE" && cd .. && exit )
sudo python2.7 setup.py install || ( echo "$SETUPFAILEDMESSAGE" && cd .. && exit )
cd ..
