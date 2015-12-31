Mac OS X Installer Scripts
====================================
An alternative to building lbry yourself, binaries only work on OS X El Capitan

Clone this respository by opening a terminal and running

        git clone https://github.com/lbryio/lbry-setup.git

If you don't have xcode command line tools installed, a prompt to do so will appear the first time you run 'git'. 

Make the scripts executable

        cd lbry-setup
        chmod +x lbry_osx_setup_1.sh
        chmod +x lbry_osx_setup_2.sh

Run the first script

        ./lbry_osx_setup_1.sh

If brew wasn't installed previously you'll be prompted to hit 'enter' and to enter your password when requested.

Once the first script is done, complete the installation with

        sudo ./lbry_osx_setup_2.sh
        
Once this completes you can start the gui by double clicking /Applications/LBRY.app, or start the lbrynet console with

        sudo lbrynet-console


Mac OS X Build Instructions and Notes
====================================
This guide will show you how to build lbry for OSX.

Notes
-----

* Tested on OS X 10.10 through 10.11 on 64-bit Intel processors only.

* All of the commands should be executed in a Terminal application. The
built-in one is located in `/Applications/Utilities`.

* These instructions aren't perfect. If you run into a problem, please email me at jack@lbry.io so I can adjust this readme accordingly.

Preparation
-----------

If you're running El Capitan, you may need to disable rootless mode. To do so follow the instructions [here](https://www.quora.com/How-do-I-turn-off-the-rootless-in-OS-X-El-Capitan-10-11).

You need to install XCode with all the options checked so that the compiler
and everything is available in /usr not just /Developer. XCode should be
available on your OS X installation media, but if not, you can get the
current version from https://developer.apple.com/xcode/. If you install
Xcode 4.3 or later, you'll need to install its command line tools. This can
be done in `Xcode > Preferences > Downloads > Components` and generally must
be re-done or updated every time Xcode is updated.

You will also need to install [Homebrew](http://brew.sh) in order to install library
dependencies. If you don't have it, run the following:

        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

You will also need pip. If you don't have it, run the following:

        sudo easy_install pip

The installation of the actual dependencies is covered in the instructions below.

### Install dependencies using Homebrew

        brew install autoconf 
        brew install automake 
        brew install libtool 
        brew install boost
        brew install openssl 
        brew link --force openssl
        brew install pkg-config 
        brew install protobuf 
        brew install qt5 
        brew install git 
        brew install gmp

### Installing berkeley-db4 using Homebrew

The homebrew package for berkeley-db4 has been broken for some time.  It will install without Java though.

Running this command takes you into brew's interactive mode, which allows you to configure, make, and install by hand:

    brew install https://raw.github.com/homebrew/homebrew/master/Library/Formula/berkeley-db4.rb -–without-java 

The rest of these commands are run inside brew interactive mode:

    cd ..
    db-4.8.30/dist/configure --prefix=/usr/local/Cellar/berkeley-db4/4.8.30 --mandir=/usr/local/Cellar/berkeley-db4/4.8.30/share/man --enable-cxx
    make
    make install
    exit


After exiting, run the following:

    brew link --force berkeley-db4


### Installing miniupnpc-1.9

Unfortunatly, the miniupnpc available with brew isn't compatible with lbry. Download the compatable version [here](http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.tar.gz) and double click the downloaded file to decompress it. Then enter the following:

    cd ~/Downloads/miniupnpc-1.9
    sudo make
    sudo make install

### Installing gmpy

Run the following:

    sudo pip install gmpy

### Building lbrycrd

1. Clone the github tree to get the source code and go into the directory.

        git clone https://github.com/lbryio/lbrycrd.git
        cd lbrycrd

2.  Build lbrycrd:

        sudo ./autogen.sh
        sudo ./configure
        sudo make

3.  It is also a good idea to build and run the unit tests:

        make check

4.  (Optional) You can also install lbrycrd to your path:

        make install

### Installing lbrynet

1. Clone the github tree to get the source code and go into the directory (assuming you want to download to your home directory).

        cd ~/
        git clone https://github.com/lbryio/lbry.git
        cd lbry
        sudo python setup.py install

### Port forwarding

If you're behind a firewall you'll need to forward the following ports:

        3333 For data transfer
        4444 For DHT

How to do that depends on your router, although [this](http://portforward.com/english/routers/port_forwarding/routerindex.htm) is a good general resource.


Running
-------

It's now available at `./lbrycrdd`, provided that you are in the `lbrycrd/src`
directory. We have to first create the RPC configuration file, though.

To setup your configuration file, enter the following:

    sudo echo -e "rpcuser=lbryrpc\nrpcpassword=$(xxd -l 16 -p /dev/urandom)" > "/Users/${USER}/Library/Application Support/lbrycrd/lbrycrd.conf"
    sudo chmod 600 "/Users/${USER}/Library/Application Support/lbrycrd/lbrycrd.conf"

The next time you run it, it will start downloading the blockchain, give it a few minutes to do its thing.

To start up the gui, navigate to the folder containing lbrycrd and enter the following:

        cd lbrycrd/src
        ./lbrycrdd -server -gen -daemon
        lbrynet-gui

To start the console, enter lbrynet-console instead of lbrynet-gui.

To stop the daemon enter the following (while in lbrycrd/src):

        ./lbrycrd-cli stop
