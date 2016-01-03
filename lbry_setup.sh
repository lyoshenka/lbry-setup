#!/bin/bash

DEBIAN_FRONTEND=noninteractive

if [ -z "$BASH_VERSION" ]; then
    if command -v bash >/dev/null 2>&1; then
        echo "Non-bash shell detected. Trying to run with bash..."
        bash "$0"
        exit $?
    else
        echo "This installer only works with bash"
        exit 1
    fi
fi


# BASH strict mode
set -euo pipefail


exec >  >(tee -a setup.log)
exec 2> >(tee -a setup.log >&2)

function isInstalled {
    dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}

function absDir {
    if command -v readlink >/dev/null 2>&1; then
        readlink -m "$1"
    elif [ -d "$1" ] && command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    elif [ -d "$1" ]; then
        echo "$(cd "$1"; pwd)"
    elif [ -d "$(dirname "$1")" ]; then
        echo "$(dirname "$1")/$(basename "$1")"
    else
        echo "$1"
    fi
}

function absPath {
    echo "$(absDir "$(dirname "$1")")/$(basename "$1")"
}


DIR="$(dirname "$(absPath "${BASH_SOURCE[0]}")")"
ROOT=$(absDir "${INSTALL_DIR:-$DIR}")
CONF_DIR=$(absDir "${CONFIG_DIR:-"$HOME/.lbrycrd"}")
CONF_FILE="$CONF_DIR/lbrycrd.conf"

GIT_URL_ROOT="https://github.com/lbryio"
PACKAGES="git libgmp3-dev build-essential python2.7 python2.7-dev python-pip"


echo -e "Installing LBRY\nInstall dir: $ROOT\nConfig dir: $CONF_DIR\n"

mkdir -p "$ROOT"
cd "$ROOT"

function onExit {
  cd "$DIR"
}
trap onExit EXIT



# install/update requirements
if hash apt-get 2>/dev/null; then
    MISSING=""
    for i in $PACKAGES; do
        isInstalled "$i" || MISSING="$MISSING $i"
    done

    if [ -n "$MISSING" ]; then
        echo -e "Installing missing dependencies: $MISSING\n"
        APT_CMD="sudo apt-get install -y $MISSING"
        echo "$APT_CMD"
        if ! $APT_CMD ; then
            echo $'\n\nFailed to install necessary packages. Make sure your system is up to date and then try again.'
            exit 1
        fi
    fi
else
    echo -e "Running on a system without apt-get.\nInstall requires the following packages or equivalents: $PACKAGES\n\nPull requests encouraged if you have an install for your system!\n\n"
    exit 1
fi



mkdir -p "$ROOT/bin"

UPDATELBRYCRD=0

if [ -e "$ROOT/bin/lbrycrd.tar.gz" ]; then
    LBRYCRDHASHSUM=$(md5sum "$ROOT/bin/lbrycrd.tar.gz" | awk '{print $1}')
    if [ ! "$LBRYCRDHASHSUM" = "046463be793a567671df691a2d4cac2f" ] && [ ! "$LBRYCRDHASHSUM" = "0cf55341bbd8594468af5792811c0977" ]; then
        UPDATELBRYCRD=1
    fi
else
    UPDATELBRYCRD=1
fi

if [ $UPDATELBRYCRD = 1 ]; then
    (cd "$ROOT/bin"
        if [ "$(getconf LONG_BIT)" = "64" ]; then
            LBRYCRDBINURL="https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_64.tar.gz"
        else
            LBRYCRDBINURL="https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd_32.tar.gz"
        fi
        echo -e "Downloading lbrycrd\n\n"
        wget --progress=bar:force "$LBRYCRDBINURL" -O lbrycrd.tar.gz
        echo -e "Extracting..."
        tar -xzf lbrycrd.tar.gz
        #create config file
        if [ ! -d "$CONF_DIR" ]; then
            echo "Setting up lbrycrd data in $CONF_DIR"
            mkdir -p "$CONF_DIR"
            echo "rpcuser=lbryrpc" > "$CONF_FILE"
            echo "rpcpassword=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 24)" >> "$CONF_FILE"
            mv lbrycrd/lbrycrddata/* "$CONF_DIR/"
            rm -rf lbrycrd/lbrycrddata
        else
            echo "$CONF_DIR already exists"
        fi

        mv lbrycrd/* .
        rm -rf lbrycrd
    )
    if [ -e "$HOME/.lbrycrddpath.conf" ] && [ "$(cat ~/.lbrycrddpath.conf)" = "$ROOT/lbrycrd/src/lbrycrdd" ]; then
        rm ~/.lbrycrddpath.conf
    fi
else
    echo "lbrycrd installed and nothing to update"
fi


if [ ! -e "$HOME/.lbrycrddpath.conf" ]; then
    echo "$ROOT/bin/lbrycrdd" > ~/.lbrycrddpath.conf
fi



#Clone/pull repo and return true/false whether or not anything changed
#$1 : repo name
function UpdateSource {
    if [ ! -d "$ROOT/$1/.git" ]; then
        echo "$1 does not exist, checking out"
        git clone "$GIT_URL_ROOT/$1.git" "$ROOT/$1"
        return 0
    else
        GITCMD="git --work-tree=$ROOT/$1 --git-dir=$ROOT/$1/.git"
        #http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
        $GITCMD remote update
        LOCAL=$($GITCMD rev-parse "@{0}")
        REMOTE=$($GITCMD rev-parse "@{u}")
        if [ "$LOCAL" = "$REMOTE" ]; then
            echo "No changes to $1 source"
            return 1
        else
            echo "Fetching source changes to $1"
            $GITCMD pull --rebase
            return 0
        fi
    fi
}

#setup lbry-console
echo -e "\n\nInstalling/updating lbry-console";
if UpdateSource lbry || [ ! -d "$ROOT/lbry/dist" ]; then
    echo $'Updating lbry-console\n'
else
    echo $'lbry already up to date, rebuilding anyway\n'
fi



(cd "$ROOT/lbry"
    if [ -d dist ] && [ "$(stat -c "%U" dist)" = "root" ]; then
        sudo rm -rf dist build ez_setup.pyc lbrynet.egg-info setuptools-4.0.1-py2.7.egg setuptools-4.0.1.zip
    fi

    (python2.7 setup.py build bdist_egg -o && sudo python2.7 setup.py install) || (echo "Failed to install lbry. Make sure your system is up to date and try again."; exit 1)
)

echo "LBRY installed into $ROOT"