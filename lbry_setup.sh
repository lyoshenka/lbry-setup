#!/bin/bash

DEBIAN_FRONTEND=noninteractive

if [ -z "$BASH" ]; then
    printf "Non-bash shell detected. Trying to run with bash...\n"
    bash $0
    exit 0
fi

exec >  >(tee -a script_setup.log)
exec 2> >(tee -a script_setup.log >&2)

ROOT=.
GIT_URL_ROOT="https://github.com/lbryio/"
PACKAGES="git"

#install/update requirements
if hash apt-get 2>/dev/null; then
	printf "Installing $PACKAGES\n\n"
    if ! sudo apt-get install -y $PACKAGES; then 
        echo $'\n\nFailed to install necessary packages. Make sure your system is up to date, then try again.'
        exit
    fi
else
	echo "Running on a system without apt-get.
Install requires the following packages or equivalents: $PACKAGES
Pull requests encouraged if you have an install for your system!
"
    exit
fi

#Clone/pull repo and return true/false whether or not anything changed
#$1 : repo name
UpdateSource() 
{
	if [ ! -d "$ROOT/.git" ]; then
       	echo "setup script does not exist, checking out\n";
        mv lbry_setup.sh lbry_setup.sh.backup
        git init
        git remote add origin "${GIT_URL_ROOT}lbry-setup.git"
        git fetch --all
        git checkout master
		return 0 
	else
		#http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
		git remote update;
		LOCAL=$(git rev-parse @{0})
		REMOTE=$(git rev-parse @{u})
		if [ $LOCAL = $REMOTE ]; then
			echo "No changes to setup script\n"
			return 1 
		else
			echo "Fetching source changes to setup script\n"
			git pull --rebase
			return 0
		fi
	fi
}
UpdateSource

bash update_lbry.sh
