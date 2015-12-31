#!/bin/sh

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install mpfr libmpc
mkdir -p "/Users/${USER}/Library/Application Support/lbrycrd"
echo "rpcuser=lbryrpc\nrpcpassword=$(xxd -l 16 -p /dev/urandom)" > "/Users/${USER}/Library/Application Support/lbrycrd/lbrycrd.conf"